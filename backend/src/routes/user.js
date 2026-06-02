const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const User = require('../models/User');

// All routes require authentication
router.use(protect);

// ─── GET /user/profile ────────────────────────────────────────────
router.get('/profile', async (req, res, next) => {
  try {
    res.json({ success: true, user: req.user });
  } catch (err) { next(err); }
});

// ─── PUT /user/profile ────────────────────────────────────────────
router.put('/profile', async (req, res, next) => {
  try {
    const allowed = [
      'name', 'profilePic', 'rollNumber', 'branch', 'year', 'phone',
      'college', 'graduationYear', 'dreamCompany', 'cgpa',
      'preferredLanguage', 'appPurpose', 'fcmToken',
    ];
    const updates = {};
    allowed.forEach(field => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true,
    });

    res.json({ success: true, user });
  } catch (err) { next(err); }
});

// ─── PUT /user/platforms ──────────────────────────────────────────
router.put('/platforms', async (req, res, next) => {
  try {
    const { leetcode, gfg, codeforces, codechef, hackerrank, github } = req.body;
    const platforms = {};
    if (leetcode !== undefined) platforms['platforms.leetcode'] = leetcode;
    if (gfg !== undefined) platforms['platforms.gfg'] = gfg;
    if (codeforces !== undefined) platforms['platforms.codeforces'] = codeforces;
    if (codechef !== undefined) platforms['platforms.codechef'] = codechef;
    if (hackerrank !== undefined) platforms['platforms.hackerrank'] = hackerrank;
    if (github !== undefined) platforms['platforms.github'] = github;

    const user = await User.findByIdAndUpdate(req.user._id, { $set: platforms }, { new: true });
    res.json({ success: true, platforms: user.platforms });
  } catch (err) { next(err); }
});

// ─── PUT /user/settings ───────────────────────────────────────────
router.put('/settings', async (req, res, next) => {
  try {
    const settingsFields = {};
    const { darkMode, accentColor, fontSize, notifications, platformVisibility, platformOrder } = req.body;
    if (darkMode !== undefined) settingsFields['settings.darkMode'] = darkMode;
    if (accentColor !== undefined) settingsFields['settings.accentColor'] = accentColor;
    if (fontSize !== undefined) settingsFields['settings.fontSize'] = fontSize;
    if (notifications) {
      Object.keys(notifications).forEach(k => {
        settingsFields[`settings.notifications.${k}`] = notifications[k];
      });
    }
    if (platformVisibility) {
      Object.keys(platformVisibility).forEach(k => {
        settingsFields[`settings.platformVisibility.${k}`] = platformVisibility[k];
      });
    }
    if (platformOrder) settingsFields['settings.platformOrder'] = platformOrder;

    const user = await User.findByIdAndUpdate(req.user._id, { $set: settingsFields }, { new: true });
    res.json({ success: true, settings: user.settings });
  } catch (err) { next(err); }
});

// ─── PUT /user/onboarding ─────────────────────────────────────────
router.put('/onboarding', async (req, res, next) => {
  try {
    const { step, complete, data } = req.body;
    const updates = {};
    if (step !== undefined) updates.onboardingStep = step;
    if (complete) updates.onboardingComplete = true;
    if (data) Object.assign(updates, data);

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true });

    // Award XP for completing onboarding
    if (complete) {
      const { awardXP } = require('../services/gamificationService');
      await awardXP(user._id, 'onboarding_complete', { step: 'completed' });
    }

    res.json({ success: true, user });
  } catch (err) { next(err); }
});

// ─── DELETE /user/account ─────────────────────────────────────────
router.delete('/account', async (req, res, next) => {
  try {
    const userId = req.user._id;
    // Cascade delete all user data
    const [DailyLog, TopicTracker, TodoPlan, Note, RevisionSchedule, PlatformStats, Badge, XpEvent] = [
      require('../models/DailyLog'),
      require('../models/TopicTracker'),
      require('../models/TodoPlan'),
      require('../models/Note'),
      require('../models/RevisionSchedule'),
      require('../models/PlatformStats'),
      require('../models/Gamification').Badge,
      require('../models/Gamification').XpEvent,
    ];

    await Promise.all([
      DailyLog.deleteMany({ userId }),
      TopicTracker.deleteMany({ userId }),
      TodoPlan.deleteMany({ userId }),
      Note.deleteMany({ userId }),
      RevisionSchedule.deleteMany({ userId }),
      PlatformStats.deleteMany({ userId }),
      Badge.deleteMany({ userId }),
      XpEvent.deleteMany({ userId }),
      User.findByIdAndDelete(userId),
    ]);

    res.json({ success: true, message: 'Account and all data deleted successfully' });
  } catch (err) { next(err); }
});

module.exports = router;
