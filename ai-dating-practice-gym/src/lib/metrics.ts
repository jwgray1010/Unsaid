type MetricInputMessage = {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
};

const heavyTopicKeywords = [
  "divorce",
  "ex",
  "trauma",
  "court",
  "custody",
  "addicted",
  "hate",
  "abuse",
  "cheated",
];

const warmthKeywords = [
  "appreciate",
  "thank you",
  "glad",
  "curious",
  "happy",
  "excited",
  "care",
  "kind",
  "respect",
];

function countWords(content: string): number {
  return content.trim().split(/\s+/).filter(Boolean).length;
}

export function computeSessionMetrics(messages: MetricInputMessage[]) {
  const userMessages = messages.filter((message) => message.role === "user");
  const assistantMessages = messages.filter((message) => message.role === "assistant");

  const questionCount = userMessages.filter((message) => message.content.includes("?")).length;
  const questionRatio = userMessages.length === 0 ? 0 : Number((questionCount / userMessages.length).toFixed(3));

  const avgUserLength =
    userMessages.length === 0
      ? 0
      : Number(
          (
            userMessages.reduce((total, message) => total + countWords(message.content), 0) / userMessages.length
          ).toFixed(2),
        );

  const avgAssistantLength =
    assistantMessages.length === 0
      ? 0
      : Number(
          (
            assistantMessages.reduce((total, message) => total + countWords(message.content), 0) /
            assistantMessages.length
          ).toFixed(2),
        );

  const selfDisclosureCount = userMessages.filter((message) => {
    const normalized = message.content.trim().toLowerCase();
    const words = countWords(message.content);
    return words > 12 && (normalized.startsWith("i ") || normalized.includes("i feel"));
  }).length;
  const selfDisclosureRatio =
    userMessages.length === 0 ? 0 : Number((selfDisclosureCount / userMessages.length).toFixed(3));

  const earlyTurns = userMessages.slice(0, 6).map((message) => message.content.toLowerCase());
  const earlyHeavyTopicFlag = earlyTurns.some((turn) =>
    heavyTopicKeywords.some((keyword) => turn.includes(keyword)),
  );

  const warmthKeywordsCount = userMessages.reduce((total, message) => {
    const normalized = message.content.toLowerCase();
    return total + warmthKeywords.filter((keyword) => normalized.includes(keyword)).length;
  }, 0);

  return {
    question_ratio: questionRatio,
    avg_user_length: avgUserLength,
    avg_assistant_length: avgAssistantLength,
    self_disclosure_ratio: selfDisclosureRatio,
    early_heavy_topic_flag: earlyHeavyTopicFlag,
    warmth_keywords_count: warmthKeywordsCount,
  };
}
