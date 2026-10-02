import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  SITE_SETTINGS_KEY,
  SiteSettings,
  SiteSettingsDocument,
} from './schemas/site-settings.schema';
import { UpdateSiteSettingsDto } from './dto/update-site-settings.dto';

/// The shape both the website and the admin screen read. Plain values only —
/// no ids or timestamps the site has no use for.
export interface SiteSettingsView {
  facebookUrl: string;
  instagramUrl: string;
  xUrl: string;
  tiktokUrl: string;
  youtubeUrl: string;
  whatsappNumber: string;
  phones: { label: string; number: string }[];
  email: string;
  googlePlayUrl: string;
  webAppUrl: string;
  updatedAt: string | null;
}

@Injectable()
export class SiteSettingsService {
  constructor(
    @InjectModel(SiteSettings.name)
    private readonly model: Model<SiteSettings>,
  ) {}

  // Read-only: before the admin first saves there is no document, and the
  // site gets the all-empty defaults instead of a 404 it would have to handle.
  async get(): Promise<SiteSettingsView> {
    const doc = await this.model.findOne({ key: SITE_SETTINGS_KEY }).exec();
    return toView(doc);
  }

  // Upsert so the first save creates the singleton; `runValidators` keeps the
  // schema's trim/lowercase applying on update as it does on create.
  async update(dto: UpdateSiteSettingsDto): Promise<SiteSettingsView> {
    const set: Record<string, unknown> = {};
    for (const [field, value] of Object.entries(dto)) {
      if (value === undefined) continue;
      set[field] =
        field === 'phones'
          ? (value as { label?: string; number: string }[]).map((p) => ({
              label: p.label ?? '',
              number: p.number,
            }))
          : value;
    }
    const doc = await this.model
      .findOneAndUpdate(
        { key: SITE_SETTINGS_KEY },
        { $set: set },
        {
          upsert: true,
          new: true,
          runValidators: true,
          setDefaultsOnInsert: true,
        },
      )
      .exec();
    return toView(doc);
  }
}

function toView(doc: SiteSettingsDocument | null): SiteSettingsView {
  const timestamps = doc as unknown as { updatedAt?: Date } | null;
  return {
    facebookUrl: doc?.facebookUrl ?? '',
    instagramUrl: doc?.instagramUrl ?? '',
    xUrl: doc?.xUrl ?? '',
    tiktokUrl: doc?.tiktokUrl ?? '',
    youtubeUrl: doc?.youtubeUrl ?? '',
    whatsappNumber: doc?.whatsappNumber ?? '',
    phones: (doc?.phones ?? []).map((p) => ({
      label: p.label ?? '',
      number: p.number,
    })),
    email: doc?.email ?? '',
    googlePlayUrl: doc?.googlePlayUrl ?? '',
    webAppUrl: doc?.webAppUrl ?? '',
    updatedAt: timestamps?.updatedAt?.toISOString() ?? null,
  };
}
