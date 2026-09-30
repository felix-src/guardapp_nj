/** Every PDF starts with "%PDF-". Checked on the bytes, not the file name
 * or the client-supplied content type, both of which can be faked. */
export function looksLikePdf(bytes: Buffer): boolean {
  return bytes.subarray(0, 5).toString('latin1') === '%PDF-';
}
