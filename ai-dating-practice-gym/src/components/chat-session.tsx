"use client";

import { useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";

import { SELF_HARM_RESOURCE_MESSAGE } from "@/lib/safety";
import { type ChatMessage } from "@/lib/types";

type ChatSessionProps = {
  sessionId: string;
  initialMessages: ChatMessage[];
  initialStatus: "active" | "ended" | "coached";
};

type SimulateResponse = {
  userMessage: ChatMessage;
  assistantMessage: ChatMessage;
  selfHarm: boolean;
};

export function ChatSession({ sessionId, initialMessages, initialStatus }: ChatSessionProps) {
  const router = useRouter();
  const bottomRef = useRef<HTMLDivElement | null>(null);

  const [messages, setMessages] = useState<ChatMessage[]>(initialMessages);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [ending, setEnding] = useState(false);
  const [status, setStatus] = useState(initialStatus);
  const [safetyStopped, setSafetyStopped] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  const canChat = useMemo(() => status === "active" && !safetyStopped, [status, safetyStopped]);

  async function sendMessage(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!input.trim() || sending || !canChat) {
      return;
    }

    setSending(true);
    setErrorMessage("");

    try {
      const response = await fetch("/api/simulate", {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({
          sessionId,
          content: input.trim(),
        }),
      });

      const payload = (await response.json()) as SimulateResponse | { error: string };
      if (!response.ok || "error" in payload) {
        setErrorMessage("error" in payload ? payload.error : "Failed to send message.");
        return;
      }

      setInput("");
      setMessages((current) => [...current, payload.userMessage, payload.assistantMessage]);
      if (payload.selfHarm) {
        setSafetyStopped(true);
      }
      requestAnimationFrame(() => bottomRef.current?.scrollIntoView({ behavior: "smooth" }));
    } catch {
      setErrorMessage("Unable to reach the server. Please try again.");
    } finally {
      setSending(false);
    }
  }

  async function endDate() {
    if (ending || status === "coached") {
      return;
    }

    setEnding(true);
    setErrorMessage("");
    setStatus("ended");

    try {
      const response = await fetch("/api/coach", {
        method: "POST",
        headers: {
          "content-type": "application/json",
        },
        body: JSON.stringify({ sessionId }),
      });

      const payload = (await response.json()) as { error?: string };
      if (!response.ok) {
        setErrorMessage(payload.error ?? "Failed to generate coaching report.");
        setStatus("active");
        return;
      }

      setStatus("coached");
      router.push(`/app/session/${sessionId}/coach`);
      router.refresh();
    } catch {
      setErrorMessage("Could not generate report. Please try again.");
      setStatus("active");
    } finally {
      setEnding(false);
    }
  }

  return (
    <div className="flex h-[70vh] flex-col overflow-hidden rounded-2xl border border-zinc-200 bg-white shadow-sm">
      {safetyStopped ? (
        <div className="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800">
          <p className="font-medium">Safety support enabled</p>
          <p className="mt-1">{SELF_HARM_RESOURCE_MESSAGE}</p>
        </div>
      ) : null}

      <div className="flex-1 space-y-4 overflow-y-auto p-4">
        {messages.map((message) => (
          <div
            key={message.id}
            className={`max-w-[85%] rounded-2xl px-4 py-2 text-sm ${
              message.role === "user"
                ? "ml-auto bg-zinc-900 text-white"
                : "bg-zinc-100 text-zinc-800"
            }`}
          >
            <p className="mb-1 text-xs uppercase tracking-wide opacity-70">
              {message.role === "assistant" ? "Date" : message.role}
            </p>
            <p className="whitespace-pre-wrap">{message.content}</p>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      <div className="border-t border-zinc-200 p-4">
        {errorMessage ? <p className="mb-3 text-sm text-red-600">{errorMessage}</p> : null}
        <form onSubmit={sendMessage} className="flex flex-col gap-3 sm:flex-row">
          <input
            value={input}
            onChange={(event) => setInput(event.target.value)}
            disabled={!canChat || sending}
            placeholder={canChat ? "Type your message..." : "Session is not active."}
            className="flex-1 rounded-xl border border-zinc-300 px-3 py-2 text-sm outline-none ring-zinc-300 focus:ring-2 disabled:cursor-not-allowed disabled:bg-zinc-100"
          />
          <button
            type="submit"
            disabled={!canChat || sending || !input.trim()}
            className="rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-zinc-700 disabled:cursor-not-allowed disabled:bg-zinc-400"
          >
            {sending ? "Sending..." : "Send"}
          </button>
          <button
            type="button"
            onClick={endDate}
            disabled={ending || status === "coached"}
            className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-100 disabled:cursor-not-allowed disabled:text-zinc-400"
          >
            {ending ? "Finishing..." : "End Date"}
          </button>
        </form>
      </div>
    </div>
  );
}
