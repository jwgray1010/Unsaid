const selfHarmKeywords = [
  "kill myself",
  "want to die",
  "end my life",
  "suicide",
  "self harm",
  "hurt myself",
  "not worth living",
  "i should disappear",
];

const explicitKeywords = [
  "nudes",
  "hook up",
  "sex chat",
  "explicit",
  "graphic",
  "naked",
  "porn",
];

export function detectSelfHarm(content: string): boolean {
  const normalized = content.toLowerCase();
  return selfHarmKeywords.some((keyword) => normalized.includes(keyword));
}

export function detectExplicitContent(content: string): boolean {
  const normalized = content.toLowerCase();
  return explicitKeywords.some((keyword) => normalized.includes(keyword));
}

export const SELF_HARM_RESOURCE_MESSAGE =
  "I care about your safety. If you might act on thoughts of harming yourself, call or text 988 right now in the U.S. for immediate support. If you are in immediate danger, call emergency services.";
