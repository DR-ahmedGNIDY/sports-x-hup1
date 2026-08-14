import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

// Mirrors videos/dto/create-comment.dto.ts — kept as its own copy so this
// module doesn't reach into VideosModule just for a 3-line shape.
export class CreateCommentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text: string;
}
