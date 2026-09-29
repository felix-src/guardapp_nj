import {
  CRISIS_LINE,
  JOB_SECTIONS,
  NATIONAL_RESOURCES,
  NEW_JERSEY_RESOURCES,
} from './resources.data';

describe('resource links', () => {
  const groups = [
    ...NEW_JERSEY_RESOURCES,
    ...NATIONAL_RESOURCES,
    ...JOB_SECTIONS,
  ];
  const links = [CRISIS_LINE, ...groups.flatMap((g) => g.items)];

  it('uses https URLs only', () => {
    for (const link of links) expect(link.url).toMatch(/^https:\/\//);
  });

  it('gives every phone number digits and a label', () => {
    for (const link of links.filter((l) => l.phone)) {
      expect(link.phone).toMatch(/^\d+$/);
      expect(link.phoneLabel).toBeTruthy();
    }
  });

  it('has no empty groups', () => {
    for (const group of groups) expect(group.items.length).toBeGreaterThan(0);
  });
});
