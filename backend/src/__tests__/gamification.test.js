const { getLevelFromXP } = require('../services/gamificationService');

describe('Gamification Service - XP and Leveling Logic', () => {
  test('should return level 1 for 0 XP', () => {
    const info = getLevelFromXP(0);
    expect(info.level).toBe(1);
    expect(info.name).toBe('Beginner');
    expect(info.progress).toBe(0);
  });

  test('should correctly transition to level 2 at 200 XP', () => {
    const info = getLevelFromXP(200);
    expect(info.level).toBe(2);
    expect(info.name).toBe('Novice');
    expect(info.progress).toBe(0);
  });

  test('should calculate correct intermediate level progress', () => {
    // Level 2 is from 200 to 500. XP 350 is exactly midpoint (50% progress)
    const info = getLevelFromXP(350);
    expect(info.level).toBe(2);
    expect(info.progress).toBe(50);
  });

  test('should return max level details for extremely high XP values', () => {
    const info = getLevelFromXP(500000);
    expect(info.level).toBe(12);
    expect(info.name).toBe('Legend');
    expect(info.progress).toBe(100);
  });
});
