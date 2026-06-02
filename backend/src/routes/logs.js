const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const DailyLog = require('../models/DailyLog');
const TopicTracker = require('../models/TopicTracker');
const RevisionSchedule = require('../models/RevisionSchedule');
const { awardXP, checkAndAwardBadges, updateStreak } = require('../services/gamificationService');

router.use(protect);

// ─── GET /logs ────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { date, topic, platform, difficulty, limit = 50, skip = 0, bookmark, needsRevision } = req.query;
    const filter = { userId: req.user._id };

    if (date) {
      const start = new Date(date); start.setHours(0, 0, 0, 0);
      const end = new Date(date); end.setHours(23, 59, 59, 999);
      filter.date = { $gte: start, $lte: end };
    }
    if (topic) filter.topic = topic;
    if (platform) filter.platform = platform;
    if (difficulty) filter.difficulty = difficulty;
    if (bookmark === 'true') filter.isBookmarked = true;
    if (needsRevision === 'true') filter.needsRevision = true;

    const [logs, total] = await Promise.all([
      DailyLog.find(filter).sort({ date: -1, createdAt: -1 }).limit(Number(limit)).skip(Number(skip)),
      DailyLog.countDocuments(filter),
    ]);

    // Today's summary
    const today = new Date(); today.setHours(0, 0, 0, 0);
    const todayEnd = new Date(today); todayEnd.setHours(23, 59, 59, 999);
    const todayStats = await DailyLog.aggregate([
      { $match: { userId: req.user._id, date: { $gte: today, $lte: todayEnd } } },
      { $group: { _id: null, count: { $sum: 1 }, totalTime: { $sum: '$timeTaken' } } },
    ]);

    res.json({
      success: true,
      logs,
      total,
      todaySummary: todayStats[0] || { count: 0, totalTime: 0 },
    });
  } catch (err) { next(err); }
});

// ─── POST /logs ───────────────────────────────────────────────────
router.post('/', async (req, res, next) => {
  try {
    const {
      problemName, topic, platform, difficulty, timeTaken,
      link, notes, approach, needsRevision, confidence, isBookmarked, isFavorite, date,
    } = req.body;

    const logDate = date ? new Date(date) : new Date();
    logDate.setHours(0, 0, 0, 0);

    // XP for this problem
    const xpMap = { easy: 'easy_solved', medium: 'medium_solved', hard: 'hard_solved' };
    const xpEvent = xpMap[difficulty] || 'easy_solved';
    const xpResult = await awardXP(req.user._id, xpEvent, { problemName, platform, topic });

    const log = await DailyLog.create({
      userId: req.user._id,
      date: logDate,
      problemName, topic, platform, difficulty,
      timeTaken: timeTaken || 0,
      link: link || '',
      notes: notes || '',
      approach: approach || '',
      needsRevision: needsRevision || false,
      confidence: confidence || 3,
      isBookmarked: isBookmarked || false,
      isFavorite: isFavorite || false,
      xpAwarded: xpResult?.xpGained || 0,
    });

    // ─── Auto-update Topic Tracker ───────────────────────────────
    const topicUpdate = {
      $inc: { totalSolved: 1 },
      $set: { lastPracticed: new Date(), status: 'active' },
    };
    if (difficulty === 'easy') topicUpdate.$inc.easySolved = 1;
    if (difficulty === 'medium') topicUpdate.$inc.mediumSolved = 1;
    if (difficulty === 'hard') topicUpdate.$inc.hardSolved = 1;

    await TopicTracker.findOneAndUpdate(
      { userId: req.user._id, topic },
      topicUpdate,
      { upsert: true, new: true }
    );

    // ─── Create revision schedule if needed ───────────────────────
    if (needsRevision || confidence <= 2) {
      const nextRevDate = new Date();
      nextRevDate.setDate(nextRevDate.getDate() + 1);
      await RevisionSchedule.create({
        userId: req.user._id,
        logId: log._id,
        problemName, topic, platform,
        link: link || '',
        difficulty,
        nextRevisionDate: nextRevDate,
        confidence: confidence || 3,
      });
    }

    // ─── Update streak ────────────────────────────────────────────
    const streakResult = await updateStreak(req.user._id);

    // ─── Check badges ─────────────────────────────────────────────
    const totalSolved = await DailyLog.countDocuments({ userId: req.user._id });
    const newBadges = await checkAndAwardBadges(req.user._id, {
      totalSolved, difficulty, streak: streakResult.streak, topic,
    });

    res.status(201).json({
      success: true,
      log,
      xp: xpResult,
      streak: streakResult,
      newBadges,
    });
  } catch (err) { next(err); }
});

// ─── PUT /logs/:id ────────────────────────────────────────────────
router.put('/:id', async (req, res, next) => {
  try {
    const log = await DailyLog.findOne({ _id: req.params.id, userId: req.user._id });
    if (!log) return res.status(404).json({ success: false, message: 'Log not found' });

    const allowed = ['problemName','topic','platform','difficulty','timeTaken','link','notes','approach','needsRevision','confidence','isBookmarked','isFavorite'];
    allowed.forEach(f => { if (req.body[f] !== undefined) log[f] = req.body[f]; });
    await log.save();

    res.json({ success: true, log });
  } catch (err) { next(err); }
});

// ─── DELETE /logs/:id ─────────────────────────────────────────────
router.delete('/:id', async (req, res, next) => {
  try {
    const log = await DailyLog.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!log) return res.status(404).json({ success: false, message: 'Log not found' });
    res.json({ success: true, message: 'Log deleted' });
  } catch (err) { next(err); }
});

// ─── GET /logs/stats ──────────────────────────────────────────────
router.get('/stats/overview', async (req, res, next) => {
  try {
    const userId = req.user._id;
    const [total, byDiff, byPlatform, byTopic, weeklyActivity] = await Promise.all([
      DailyLog.countDocuments({ userId }),
      DailyLog.aggregate([
        { $match: { userId } },
        { $group: { _id: '$difficulty', count: { $sum: 1 }, totalTime: { $sum: '$timeTaken' } } },
      ]),
      DailyLog.aggregate([
        { $match: { userId } },
        { $group: { _id: '$platform', count: { $sum: 1 } } },
      ]),
      DailyLog.aggregate([
        { $match: { userId } },
        { $group: { _id: '$topic', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      // Last 7 days activity
      DailyLog.aggregate([
        { $match: { userId, date: { $gte: new Date(Date.now() - 7 * 24 * 3600 * 1000) } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]),
    ]);

    res.json({ success: true, stats: { total, byDiff, byPlatform, byTopic, weeklyActivity } });
  } catch (err) { next(err); }
});

module.exports = router;
