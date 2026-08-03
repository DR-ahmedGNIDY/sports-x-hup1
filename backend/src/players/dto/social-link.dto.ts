import { IsString, IsUrl } from 'class-validator';

export class CreateSocialLinkDto {
  @IsString()
  platform: string;

  @IsUrl()
  url: string;
}

export class UpdateSocialLinkDto {
  @IsString()
  platform: string;

  @IsUrl()
  url: string;
}
