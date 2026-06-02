const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const TopicTracker = require('../models/TopicTracker');
const PlatformStats = require('../models/PlatformStats');

router.use(protect);

// ─── GET /analytics/overview ──────────────────────────────────────
router.get('/overview', async (req, res, next) => {
  try {
    const userId = req.user._id;
    const now = new Date();
    const weekAgo = new Date(now - 7 * 24 * 3600 * 1000);
    const monthAgo = new Date(now - 30 * 24 * 3600 * 1000);

    const [
      totalSolved, weekSolved, monthSolved,
      avgTime, byDifficulty, platformStats,
      topTopics, recentStreak,
    ] = await Promise.all([
      DailyLog.countDocuments({ userId }),
      DailyLog.countDocuments({ userId, date: { $gte: weekAgo } }),
      DailyLog.countDocuments({ userId, date: { $gte: monthAgo } }),
      DailyLog.aggregate([
        { $match: { userId, timeTaken: { $gt: 0 } } },
        { $group: { _id: null, avg: { $avg: '$timeTaken' } } },
      ]),
      DailyLog.aggregate([
        { $match: { userId } },
        { $group: { _id: '$difficulty', count: { $sum: 1 } } },
      ]),
      PlatformStats.find({ userId }),
      TopicTracker.find({ userId }).sort({ totalSolved: -1 }).limit(5),
      DailyLog.aggregate([
        { $match: { userId } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } }, count: { $sum: 1 } } },
        { $sort: { _id: -1 } },
        { $limit: 30 },
      ]),
    ]);

    const diffMap = {};
    byDifficulty.forEach(d => { diffMap[d._id] = d.count; });

    // Interview readiness score
    const easy = diffMap.easy || 0;
    const medium = diffMap.medium || 0;
    const hard = diffMap.hard || 0;
    const readiness = Math.min(100, Math.round(
      (Math.min(easy, 200) / 200 * 20) +
      (Math.min(medium, 300) / 300 * 50) +
      (Math.min(hard, 100) / 100 * 30)
    ));

    res.json({
      success: true,
      overview: {
        totalSolved,
        thisWeek: weekSolved,
        thisMonth: monthSolved,
        avgTime: Math.round(avgTime[0]?.avg || 0),
        easySolved: easy,
        mediumSolved: medium,
        hardSolved: hard,
        interviewReadiness: readiness,
        streak: req.user.streak,
        xp: req.user.xp,
        level: req.user.level,
        topTopics,
        platformStats,
        recentActivity: recentStreak,
      },
    });
  } catch (err) { next(err); }
});

// ─── GET /analytics/heatmap ───────────────────────────────────────
router.get('/heatmap', async (req, res, next) => {
  try {
    const { year } = req.query;
    const targetYear = parseInt(year) || new Date().getFullYear();
    const startDate = new Date(targetYear, 0, 1);
    const endDate = new Date(targetYear, 11, 31, 23, 59, 59);

    const activity = await DailyLog.aggregate([
      { $match: { userId: req.user._id, date: { $gte: startDate, $lte: endDate } } },
      { $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
        count: { $sum: 1 },
        totalTime: { $sum: '$timeTaken' },
      }},
      { $sort: { _id: 1 } },
    ]);

    res.json({ success: true, year: targetYear, heatmap: activity });
  } catch (err) { next(err); }
});

// ─── GET /analytics/topics ────────────────────────────────────────
router.get('/topics', async (req, res, next) => {
  try {
    const topics = await TopicTracker.find({ userId: req.user._id }).sort({ totalSolved: -1 });
    res.json({ success: true, topics });
  } catch (err) { next(err); }
});

// ─── GET /analytics/weekly ────────────────────────────────────────
router.get('/weekly', async (req, res, next) => {
  try {
    const userId = req.user._id;
    const weeks = [];
    for (let i = 0; i < 12; i++) {
      const end = new Date(Date.now() - i * 7 * 24 * 3600 * 1000);
      const start = new Date(end - 7 * 24 * 3600 * 1000);
      weeks.push({ start, end });
    }

    const weeklyData = await DailyLog.aggregate([
      { $match: { userId, date: { $gte: weeks[weeks.length - 1].start } } },
      { $group: {
        _id: { $dateToString: { format: '%Y-W%V', date: '$date' } },
        count: { $sum: 1 },
        totalTime: { $sum: '$timeTaken' },
      }},
      { $sort: { _id: 1 } },
    ]);

    res.json({ success: true, weeklyData });
  } catch (err) { next(err); }
});

module.exports = router;
