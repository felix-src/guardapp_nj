import { redactUrl } from './logger.middleware';

describe('redactUrl', () => {
  it('hides unit join codes in paths and query strings', () => {
    expect(redactUrl('/auth/join/K7QM-4XPA')).toBe('/auth/join/***');
    expect(redactUrl('/join?code=K7QM-4XPA&x=1')).toBe('/join?code=***&x=1');
  });

  it('leaves other URLs alone', () => {
    expect(redactUrl('/units/2/org-chart')).toBe('/units/2/org-chart');
  });
});
