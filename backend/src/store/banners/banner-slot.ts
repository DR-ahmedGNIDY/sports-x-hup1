/// Which of a banner's two images an upload is for.
export enum BannerSlot {
  DESKTOP = 'desktop',
  MOBILE = 'mobile',
}

export function isBannerSlot(value: string): value is BannerSlot {
  return value === BannerSlot.DESKTOP || value === BannerSlot.MOBILE;
}
