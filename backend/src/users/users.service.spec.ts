import { NotFoundException } from '@nestjs/common';
import { ClubsService } from '../clubs/clubs.service';
import { PlayersService } from '../players/players.service';
import { VideosService } from '../videos/videos.service';
import { UsersService } from './users.service';
import { UserRole } from './schemas/user.schema';

describe('UsersService', () => {
  function buildService(user: Record<string, unknown> | null) {
    const model = {
      findById: jest.fn().mockResolvedValue(user),
      deleteOne: jest.fn().mockResolvedValue({ deletedCount: 1 }),
    };
    const playersService = {
      deleteProfileAndMediaByUserId: jest.fn(),
    } as unknown as PlayersService;
    const clubsService = {
      deleteProfileAndLogoByUserId: jest.fn(),
    } as unknown as ClubsService;
    const videosService = {
      deleteUserFootprint: jest.fn(),
    } as unknown as VideosService;
    const service = new UsersService(
      model as never,
      playersService,
      clubsService,
      videosService,
    );
    return { service, model, playersService, clubsService, videosService };
  }

  it('rejects deleting a user that does not exist', async () => {
    const { service } = buildService(null);

    await expect(service.deleteById('missing')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('cascade-deletes a player user profile, videos and viewer footprint', async () => {
    const { service, model, playersService, clubsService, videosService } =
      buildService({ role: UserRole.PLAYER });

    await service.deleteById('user-1');

    expect(playersService.deleteProfileAndMediaByUserId).toHaveBeenCalledWith(
      'user-1',
    );
    expect(clubsService.deleteProfileAndLogoByUserId).not.toHaveBeenCalled();
    expect(videosService.deleteUserFootprint).toHaveBeenCalledWith('user-1');
    expect(model.deleteOne).toHaveBeenCalledWith({ _id: 'user-1' });
  });

  it('cascade-deletes a club user profile and viewer footprint', async () => {
    const { service, playersService, clubsService, videosService } =
      buildService({ role: UserRole.CLUB });

    await service.deleteById('user-2');

    expect(clubsService.deleteProfileAndLogoByUserId).toHaveBeenCalledWith(
      'user-2',
    );
    expect(playersService.deleteProfileAndMediaByUserId).not.toHaveBeenCalled();
    expect(videosService.deleteUserFootprint).toHaveBeenCalledWith('user-2');
  });

  it('still cleans up the video footprint (likes/comments) for an admin user', async () => {
    const { service, playersService, clubsService, videosService } =
      buildService({ role: UserRole.ADMIN });

    await service.deleteById('user-3');

    expect(playersService.deleteProfileAndMediaByUserId).not.toHaveBeenCalled();
    expect(clubsService.deleteProfileAndLogoByUserId).not.toHaveBeenCalled();
    expect(videosService.deleteUserFootprint).toHaveBeenCalledWith('user-3');
  });
});
