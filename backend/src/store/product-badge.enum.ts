/// The small corner label on a product card ("New", "Pre-Order"). Kept as a
/// controlled list rather than free text because the front end maps each
/// value to its own colour and translated string — an unrecognised value
/// would have nothing to render.
export enum ProductBadge {
  NEW = 'new',
  PRE_ORDER = 'pre_order',
  SALE = 'sale',
}
