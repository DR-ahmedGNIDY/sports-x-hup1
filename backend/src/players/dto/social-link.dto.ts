import { IsNotEmpty, IsString, IsUrl, MaxLength } from 'class-validator';

export class CreateSocialLinkDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
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
