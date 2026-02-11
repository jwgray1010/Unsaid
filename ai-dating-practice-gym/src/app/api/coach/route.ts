import { NextResponse } from "next/server";
import { z } from "zod";

import { computeSessionMetrics } from "@/lib/metrics";
import { getOpenAIClient } from "@/lib/openai";
import {
  buildCoachingSystemPrompt,
  buildCoachingUserPrompt,
  normalizeCoachingPayload,
} from "@/lib/prompts";
import { applyRateLimit } from "@/lib/rate-limit";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { CoachingReportSchema } from "@/lib/types";

const CoachBodySchema = z.object({
  sessionId: z.string().uuid(),
});

export async function POST(request: Request) {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const limit = applyRateLimit({
      key: `coach:${user.id}`,
      max: 12,
      windowMs: 60 * 60 * 1000,
    });
    if (!limit.allowed) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Try generating a report again later." },
        { status: 429 },
      );
    }

    const body = CoachBodySchema.parse(await request.json());

    const [{ data: session }, { data: existingReport }] = await Promise.all([
      supabase
        .from("sessions")
        .select(
          `
          id,
          user_id,
          status,
          persona:personas (id,name,coaching_rubric)
        `,
        )
        .eq("id", body.sessionId)
        .eq("user_id", user.id)
        .single(),
      supabase.from("coaching_reports").select("payload").eq("session_id", body.sessionId).maybeSingle(),
    ]);

    if (!session) {
      return NextResponse.json({ error: "Session not found." }, { status: 404 });
    }

    if (existingReport?.payload) {
      return NextResponse.json({ report: existingReport.payload });
    }

    const { data: messages } = await supabase
      .from("messages")
      .select("id,role,content,created_at")
      .eq("session_id", body.sessionId)
      .order("created_at", { ascending: true });

    const transcript = (messages ?? []).filter((message) => message.role !== "system");
    const userMessageCount = transcript.filter((message) => message.role === "user").length;
    if (userMessageCount < 2) {
      return NextResponse.json(
        { error: "Need at least 2 user messages before generating coaching." },
        { status: 400 },
      );
    }

    const persona = Array.isArray(session.persona) ? session.persona[0] : session.persona;
    const metrics = computeSessionMetrics(
      transcript.map((message) => ({
        id: message.id,
        role: message.role as "user" | "assistant" | "system",
        content: message.content,
      })),
    );

    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL_COACHING ?? "gpt-4.1-mini",
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: buildCoachingSystemPrompt({
            personaName: persona.name,
            rubric: persona.coaching_rubric ?? {},
            metrics,
            transcript: transcript.map((message) => ({
              id: message.id,
              role: message.role,
              content: message.content,
            })),
          }),
        },
        {
          role: "user",
          content: buildCoachingUserPrompt({
            transcript: transcript.map((message) => ({
              id: message.id,
              role: message.role,
              content: message.content,
            })),
          }),
        },
      ],
      max_completion_tokens: 1900,
    });

    const raw = completion.choices[0]?.message?.content;
    if (!raw) {
      return NextResponse.json({ error: "Coach model returned empty output." }, { status: 502 });
    }

    const parsed = CoachingReportSchema.parse(JSON.parse(raw));
    const normalized = normalizeCoachingPayload(parsed);

    const [upsertResult] = await Promise.all([
      supabase.from("coaching_reports").upsert(
        {
          session_id: body.sessionId,
          overall_score: normalized.overall_score,
          payload: normalized,
        },
        { onConflict: "session_id" },
      ),
      supabase
        .from("sessions")
        .update({
          status: "coached",
          ended_at: new Date().toISOString(),
          overall_score: normalized.overall_score,
          summary: normalized.summary,
        })
        .eq("id", body.sessionId)
        .eq("user_id", user.id),
    ]);

    if (upsertResult.error) {
      return NextResponse.json({ error: upsertResult.error.message }, { status: 500 });
    }

    return NextResponse.json({ report: normalized });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: error.issues[0]?.message ?? "Invalid request." }, { status: 400 });
    }
    if (error instanceof SyntaxError) {
      return NextResponse.json({ error: "Coach output was not valid JSON. Try again." }, { status: 502 });
    }
    console.error("coach route error", error);
    return NextResponse.json({ error: "Internal server error." }, { status: 500 });
  }
}
