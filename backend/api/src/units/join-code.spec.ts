import {
  formatJoinCode,
  generateJoinCode,
  JOIN_CODE_ALPHABET,
  JOIN_CODE_LENGTH,
  normalizeJoinCode,
} from './join-code';

describe('join codes', () => {
  it('generates codes from the unambiguous alphabet', () => {
    for (let i = 0; i < 200; i++) {
      const code = generateJoinCode();
      expect(code).toHaveLength(JOIN_CODE_LENGTH);
      for (const ch of code) expect(JOIN_CODE_ALPHABET).toContain(ch);
    }
  });

  it('normalizes user input to the stored form', () => {
    expect(normalizeJoinCode(' k7qm-4xpa ')).toBe('K7QM4XPA');
    expect(normalizeJoinCode('K7QM 4XPA')).toBe('K7QM4XPA');
  });

  it('round-trips display formatting', () => {
    expect(formatJoinCode('K7QM4XPA')).toBe('K7QM-4XPA');
    expect(normalizeJoinCode(formatJoinCode('K7QM4XPA'))).toBe('K7QM4XPA');
  });
});
