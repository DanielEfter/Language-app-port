import { levenshteinEditDistance } from 'levenshtein-edit-distance';

export function normalizeText(text: string): string {
  // Strip HTML tags and entities first
  let cleanText = text
    .replace(/<[^>]*>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"');

  return cleanText
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export function calculateSimilarity(text1: string, text2: string): number {
  const normalized1 = normalizeText(text1);
  const normalized2 = normalizeText(text2);

  if (normalized1 === normalized2) {
    return 1.0;
  }

  const maxLength = Math.max(normalized1.length, normalized2.length);
  if (maxLength === 0) {
    return 1.0;
  }

  const editDistance = levenshteinEditDistance(normalized1, normalized2);
  const similarity = 1 - editDistance / maxLength;

  return Math.max(0, Math.min(1, similarity));
}

export function isAcceptableSimilarity(similarity: number, threshold: number = 0.8): boolean {
  return similarity >= threshold;
}
