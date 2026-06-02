const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const TopicTracker = require('../models/TopicTracker');
const { awardXP, updateStreak, checkAndAwardBadges } = require('../services/gamificationService');

// Chrome Extension submission sync (uses bearer token)
router.use(protect);

// ─── POST /sync/submission ────────────────────────────────────────
router.post('/submission', async (req, res, next) => {
  try {
    const { platform, problem, difficulty, link, timestamp, topic } = req.body;

    if (!problem || !platform) {
      return res.status(400).json({ success: false, message: 'Problem name and platform required' });
    }

    const date = timestamp ? new Date(timestamp) : new Date();
    date.setHours(0, 0, 0, 0);

    // Check for duplicate (same problem same day)
    const existing = await DailyLog.findOne({
      userId: req.user._id,
      problemName: problem,
      date,
      platform: platform.charAt(0).toUpperCase() + platform.slice(1),
    });

    if (existing) {
      return res.json({ success: true, message: 'Already logged', duplicate: true });
    }

    const diff = difficulty || 'medium';
    const xpEvent = { easy: 'easy_solved', medium: 'medium_solved', hard: 'hard_solved' }[diff];
    const xpResult = await awardXP(req.user._id, xpEvent, { problemName: problem, source: 'extension' });

    const log = await DailyLog.create({
      userId: req.user._id,
      date,
      problemName: problem,
      topic: topic || 'Other',
      platform: platform.charAt(0).toUpperCase() + platform.slice(1),
      difficulty: diff,
      link: link || '',
      source: 'extension',
      xpAwarded: xpResult?.xpGained || 0,
    });

    // Update topic tracker
    await TopicTracker.findOneAndUpdate(
      { userId: req.user._id, topic: topic || 'Other' },
      {
        $inc: { totalSolved: 1, [`${diff}Solved`]: 1 },
        $set: { lastPracticed: new Date(), status: 'active' },
      },
      { upsert: true }
    );

    const streakResult = await updateStreak(req.user._id);
    const totalSolved = await DailyLog.countDocuments({ userId: req.user._id });
    const newBadges = await checkAndAwardBadges(req.user._id, { totalSolved, difficulty: diff, streak: streakResult.streak, topic });

    res.json({ success: true, log, xp: xpResult, streak: streakResult, newBadges });
  } catch (err) { next(err); }
});

module.exports = router;
