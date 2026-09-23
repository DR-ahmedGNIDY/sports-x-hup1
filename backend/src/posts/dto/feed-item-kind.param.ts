import { BadRequestException, PipeTransform } from '@nestjs/common';
import { FeedItemKind } from '../posts.service';

// The Home feed mixes photo posts and videos, so its moderation routes are
// addressed by `:kind/:id`. This narrows the raw path segment to the union
// the service expects, and accepts either case so `/feed/photo/...` and
// `/feed/PHOTO/...` both work.
export class ParseFeedItemKindPipe implements PipeTransform<
  string,
  FeedItemKind
> {
  transform(value: string): FeedItemKind {
    const kind = value?.toUpperCase();
    if (kind === 'PHOTO' || kind === 'VIDEO') return kind;
    throw new BadRequestException('Feed item kind must be PHOTO or VIDEO.');
  }
}
