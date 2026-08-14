import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreatePhotoPostDto {
  // Required from a Club (no `sport` on ClubProfile to default from) —
  // optional from a Player, whose own profile sport is used instead when
  // omitted. Validated against the sports catalog either way; see
  // PostsService.createPost.
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  sport?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  caption?: string;
}
