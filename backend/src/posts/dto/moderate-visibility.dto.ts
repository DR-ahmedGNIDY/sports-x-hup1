import { IsBoolean } from 'class-validator';

export class ModerateVisibilityDto {
  // true hides the item from the Home feed, false puts it back. Always
  // explicit — there is no "toggle", so two moderators acting on the same
  // post at once can't flip it back and forth by accident.
  @IsBoolean()
  hidden: boolean;
}
