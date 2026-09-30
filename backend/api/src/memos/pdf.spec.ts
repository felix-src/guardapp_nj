import { looksLikePdf } from './pdf';

describe('looksLikePdf', () => {
  it('accepts PDF bytes', () => {
    expect(looksLikePdf(Buffer.from('%PDF-1.7\n...'))).toBe(true);
  });

  it('rejects other content even if named .pdf', () => {
    expect(looksLikePdf(Buffer.from('<html><script>'))).toBe(false);
    expect(looksLikePdf(Buffer.from('MZ\x90\x00'))).toBe(false);
    expect(looksLikePdf(Buffer.alloc(0))).toBe(false);
  });
});
