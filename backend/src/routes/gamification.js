const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { XpEvent, Badge, BADGES, XP_VALUES } = require('../models/Gamification');
const { getLevelFromXP, LEVEL_THRESHOLDS, LEVEL_NAMES } = require('../services/gamificationService');

router.use(protect);

// ─── GET /gamification/level ──────────────────────────────────────
router.get('/level', async (req, res, next) => {
  try {
    const levelInfo = getLevelFromXP(req.user.xp);
    res.json({
      success: true,
      level: levelInfo,
      xp: req.user.xp,
      streak: req.user.streak,
      longestStreak: req.user.longestStreak,
      allLevels: LEVEL_THRESHOLDS.map((t, i) => ({
        level: i + 1,
        name: LEVEL_NAMES[i],
        xpRequired: t,
      })),
    });
  } catch (err) { next(err); }
});

// ─── GET /gamification/badges ─────────────────────────────────────
router.get('/badges', async (req, res, next) => {
  try {
    const earnedBadges = await Badge.find({ userId: req.user._id }).sort({ earnedAt: -1 });
    const earnedIds = earnedBadges.map(b => b.badgeId);

    // All available badges with earned status
    const allBadges = Object.values(BADGES).map(b => ({
      ...b,
      earned: earnedIds.includes(b.id),
      earnedAt: earnedBadges.find(eb => eb.badgeId === b.id)?.earnedAt || null,
    }));

    res.json({ success: true, earnedBadges, allBadges });
  } catch (err) { next(err); }
});

// ─── GET /gamification/xp ─────────────────────────────────────────
router.get('/xp', async (req, res, next) => {
  try {
    const events = await XpEvent.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({
      success: true,
      totalXP: req.user.xp,
      level: req.user.level,
      events,
      xpValues: XP_VALUES,
    });
  } catch (err) { next(err); }
});

module.exports = router;
