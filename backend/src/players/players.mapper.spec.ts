import { MediaType, PreferredFoot } from './schemas/player-profile.schema';
import { toStatsView } from './players.mapper';

describe('toStatsView', () => {
  it('reports 0% complete and every field missing for a brand-new profile', () => {
    const profile = {
      achievements: [],
      socialLinks: [],
      media: [],
      contact: {},
      visibility: 'PRIVATE',
    };

    const stats = toStatsView(profile as never, 0);

    expect(stats.completionPercent).toBe(0);
    expect(stats.missingFields).toEqual(
      expect.arrayContaining([
        'firstName',
        'profilePhoto',
        'contact',
        'achievements',
        'socialLinks',
      ]),
    );
    expect(stats.mediaCount).toBe(0);
    expect(stats.achievementsCount).toBe(0);
    expect(stats.savedByClubsCount).toBe(0);
  });

  it('reports 100% complete once every checked field is filled in', () => {
    const profile = {
      firstName: 'Mo',
      lastName: 'Salah',
      dateOfBirth: new Date('1992-06-15'),
      nationality: 'Egyptian',
      country: 'Egypt',
      city: 'Cairo',
      sport: 'Football',
      position: 'Forward',
      preferredFoot: PreferredFoot.LEFT,
      bio: 'Professional footballer.',
      contact: { email: 'mo@example.com' },
      media: [
        { type: MediaType.PHOTO, isProfilePhoto: true, secureUrl: 'x.jpg' },
      ],
      achievements: [{ title: 'League Top Scorer', year: 2023 }],
      socialLinks: [{ platform: 'Instagram', url: 'https://instagram.com/x' }],
      visibility: 'PUBLIC',
    };

    const stats = toStatsView(profile as never, 5);

    expect(stats.completionPercent).toBe(100);
    expect(stats.missingFields).toEqual([]);
    expect(stats.savedByClubsCount).toBe(5);
    expect(stats.visibility).toBe('PUBLIC');
  });
});
