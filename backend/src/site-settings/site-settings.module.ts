import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import {
  SiteSettings,
  SiteSettingsSchema,
} from './schemas/site-settings.schema';
import {
  AdminSiteSettingsController,
  SiteSettingsController,
} from './site-settings.controller';
import { SiteSettingsService } from './site-settings.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SiteSettings.name, schema: SiteSettingsSchema },
    ]),
  ],
  controllers: [SiteSettingsController, AdminSiteSettingsController],
  providers: [SiteSettingsService],
})
export class SiteSettingsModule {}
