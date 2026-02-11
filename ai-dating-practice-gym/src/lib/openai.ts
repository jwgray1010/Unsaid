import OpenAI from "openai";

import { getServerEnv } from "@/lib/env";

let client: OpenAI | null = null;

export function getOpenAIClient() {
  if (!client) {
    client = new OpenAI({
      apiKey: getServerEnv("OPENAI_API_KEY"),
    });
  }
  return client;
}
