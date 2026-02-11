import { NextResponse } from "next/server";
import { z } from "zod";

import { buildProfileSummary } from "@/lib/profile";
import { buildSimulationSystemPrompt } from "@/lib/prompts";
import { getOpenAIClient } from "@/lib/openai";
import { applyRateLimit } from "@/lib/rate-limit";
import {
  detectExplicitContent,
  detectSelfHarm,
  SELF_HARM_RESOURCE_MESSAGE,
} from "@/lib/safety";
import { createSupabaseServerClient } from "@/lib/supabase/server";

const SimulateBodySchema = z.object({
  sessionId: z.string().uuid(),
  content: z.string().trim().min(1).max(1000),
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

    const limitResult = applyRateLimit({
      key: `simulate:${user.id}`,
      max: 40,
      windowMs: 60_000,
    });
    if (!limitResult.allowed) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Please wait a moment before sending more messages." },
        { status: 429 },
      );
    }

    const body = SimulateBodySchema.parse(await request.json());

    const { data: session } = await supabase
      .from("sessions")
      .select(
        `
        id,
        user_id,
        status,
        persona:personas (id,name,system_prompt_template),
        setting:settings (id,name,context_prompt_template)
      `,
      )
      .eq("id", body.sessionId)
      .eq("user_id", user.id)
      .single();

    if (!session) {
      return NextResponse.json({ error: "Session not found." }, { status: 404 });
    }

    if (session.status !== "active") {
      return NextResponse.json({ error: "Session is no longer active." }, { status: 400 });
    }

    const { data: profile } = await supabase
      .from("profiles")
      .select("display_name,dating_goal,tendencies,comfort_level")
      .eq("user_id", user.id)
      .single();

    if (!profile) {
      return NextResponse.json({ error: "Complete your profile first." }, { status: 400 });
    }

    const userMessagePayload = {
      session_id: body.sessionId,
      role: "user",
      content: body.content,
      annotations: {
        explicit_input: detectExplicitContent(body.content),
      },
    };

    const { data: userMessage, error: userInsertError } = await supabase
      .from("messages")
      .insert(userMessagePayload)
      .select("id,role,content,created_at")
      .single();

    if (userInsertError || !userMessage) {
      return NextResponse.json({ error: userInsertError?.message ?? "Could not save message." }, { status: 500 });
    }

    if (detectSelfHarm(body.content)) {
      const { data: assistantMessage, error: assistantInsertError } = await supabase
        .from("messages")
        .insert({
          session_id: body.sessionId,
          role: "assistant",
          content: SELF_HARM_RESOURCE_MESSAGE,
          annotations: {
            safety_override: true,
          },
        })
        .select("id,role,content,created_at")
        .single();

      if (assistantInsertError || !assistantMessage) {
        return NextResponse.json(
          { error: assistantInsertError?.message ?? "Could not save safety response." },
          { status: 500 },
        );
      }

      await supabase
        .from("sessions")
        .update({
          status: "ended",
          ended_at: new Date().toISOString(),
          meta: {
            safety_stop: true,
          },
        })
        .eq("id", body.sessionId)
        .eq("user_id", user.id);

      return NextResponse.json({
        userMessage,
        assistantMessage,
        selfHarm: true,
      });
    }

    const { data: messageHistory } = await supabase
      .from("messages")
      .select("id,role,content")
      .eq("session_id", body.sessionId)
      .order("created_at", { ascending: true });

    const history = (messageHistory ?? [])
      .filter((message) => message.role === "user" || message.role === "assistant")
      .slice(-14);

    const persona = Array.isArray(session.persona) ? session.persona[0] : session.persona;
    const setting = Array.isArray(session.setting) ? session.setting[0] : session.setting;

    const systemPrompt = buildSimulationSystemPrompt({
      personaName: persona.name,
      personaSystemTemplate: persona.system_prompt_template,
      settingName: setting.name,
      settingTemplate: setting.context_prompt_template,
      profileSummary: buildProfileSummary({
        display_name: profile.display_name,
        dating_goal: profile.dating_goal,
        tendencies: Array.isArray(profile.tendencies) ? profile.tendencies : [],
        comfort_level: profile.comfort_level,
      }),
    });

    const openai = getOpenAIClient();
    const completion = await openai.chat.completions.create({
      model: process.env.OPENAI_MODEL_SIMULATION ?? "gpt-4.1-mini",
      temperature: 0.8,
      messages: [
        {
          role: "system",
          content: systemPrompt,
        },
        ...history.map((message) => ({
          role: message.role as "user" | "assistant",
          content: message.content,
        })),
      ],
      max_completion_tokens: 280,
    });

    const assistantText = completion.choices[0]?.message?.content?.trim();
    if (!assistantText) {
      return NextResponse.json({ error: "Simulation model returned an empty response." }, { status: 502 });
    }

    const { data: assistantMessage, error: assistantInsertError } = await supabase
      .from("messages")
      .insert({
        session_id: body.sessionId,
        role: "assistant",
        content: assistantText,
      })
      .select("id,role,content,created_at")
      .single();

    if (assistantInsertError || !assistantMessage) {
      return NextResponse.json(
        { error: assistantInsertError?.message ?? "Could not save assistant reply." },
        { status: 500 },
      );
    }

    return NextResponse.json({
      userMessage,
      assistantMessage,
      selfHarm: false,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: error.issues[0]?.message ?? "Invalid request." }, { status: 400 });
    }
    console.error("simulate route error", error);
    return NextResponse.json({ error: "Internal server error." }, { status: 500 });
  }
}
