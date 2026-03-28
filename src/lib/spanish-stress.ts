export interface StressedSegment {
  text: string;
  isStressed: boolean;
}

// Spanish accented vowels (same as Italian but with different stress rules)
const ACCENTED_VOWELS = ['á', 'é', 'í', 'ó', 'ú', 'ü'];

function hasAccent(char: string): boolean {
  return ACCENTED_VOWELS.includes(char.toLowerCase());
}

function findAccentedSyllable(word: string): number {
  for (let i = 0; i < word.length; i++) {
    if (hasAccent(word[i])) {
      return i;
    }
  }
  return -1;
}

export function highlightStress(text: string, stressRule?: string): StressedSegment[] {
  if (stressRule && stressRule.trim()) {
    return applyManualStressRule(text, stressRule);
  }

  return applyAutomaticStress(text);
}

function applyManualStressRule(text: string, rule: string): StressedSegment[] {
  const ruleMatch = rule.match(/\[(.*?)\]/);
  if (!ruleMatch) {
    return [{ text, isStressed: false }];
  }

  const stressedPart = ruleMatch[1];
  const index = text.toLowerCase().indexOf(stressedPart.toLowerCase());

  if (index === -1) {
    return [{ text, isStressed: false }];
  }

  const segments: StressedSegment[] = [];

  if (index > 0) {
    segments.push({ text: text.substring(0, index), isStressed: false });
  }

  segments.push({
    text: text.substring(index, index + stressedPart.length),
    isStressed: true,
  });

  if (index + stressedPart.length < text.length) {
    segments.push({
      text: text.substring(index + stressedPart.length),
      isStressed: false,
    });
  }

  return segments;
}

function applyAutomaticStress(text: string): StressedSegment[] {
  const words = text.split(/\s+/);
  const segments: StressedSegment[] = [];

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    const accentIndex = findAccentedSyllable(word);

    if (accentIndex !== -1) {
      let syllableStart = Math.max(0, accentIndex - 1);
      let syllableEnd = Math.min(word.length, accentIndex + 2);

      // Spanish vowels pattern
      while (syllableStart > 0 && /[aeiouáéíóúü]/i.test(word[syllableStart - 1])) {
        syllableStart--;
      }
      while (syllableEnd < word.length && /[aeiouáéíóúü]/i.test(word[syllableEnd])) {
        syllableEnd++;
      }

      if (syllableStart > 0) {
        segments.push({ text: word.substring(0, syllableStart), isStressed: false });
      }

      segments.push({
        text: word.substring(syllableStart, syllableEnd),
        isStressed: true,
      });

      if (syllableEnd < word.length) {
        segments.push({ text: word.substring(syllableEnd), isStressed: false });
      }
    } else {
      segments.push({ text: word, isStressed: false });
    }

    if (i < words.length - 1) {
      segments.push({ text: ' ', isStressed: false });
    }
  }

  return segments;
}
