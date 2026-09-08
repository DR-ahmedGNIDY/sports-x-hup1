// Slugs are derived from the English title, which is the required half of
// LocalizedText — an Arabic-only slug would percent-encode into an
// unreadable URL, so the store addresses everything in Latin script.
export function slugify(value: string): string {
  return (
    value
      .toLowerCase()
      .trim()
      // Anything that isn't a letter, digit or space becomes a boundary
      // rather than vanishing, so "T-Shirt (V2)" is `t-shirt-v2`, not
      // `tshirt-v2`.
      .replace(/[^a-z0-9\s-]/g, ' ')
      .replace(/[\s-]+/g, '-')
      .replace(/^-+|-+$/g, '')
  );
}
