const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const TopicTracker = require('../models/TopicTracker');
const DailyLog = require('../models/DailyLog');

router.use(protect);

// ─── GET /topics ──────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const topics = await TopicTracker.find({ userId: req.user._id }).sort({ totalSolved: -1 });
    res.json({ success: true, topics });
  } catch (err) { next(err); }
});

// ─── GET /topics/:topicName ───────────────────────────────────────
router.get('/:topicName', async (req, res, next) => {
  try {
    const topic = await TopicTracker.findOne({ userId: req.user._id, topic: req.params.topicName });
    if (!topic) return res.status(404).json({ success: false, message: 'Topic not found' });

    // Get recent problems for this topic
    const recentProblems = await DailyLog.find({
      userId: req.user._id,
      topic: req.params.topicName,
    }).sort({ date: -1 }).limit(10).select('problemName difficulty platform link date confidence');

    res.json({ success: true, topic, recentProblems });
  } catch (err) { next(err); }
});

// ─── PUT /topics/:topicName/target ────────────────────────────────
router.put('/:topicName/target', async (req, res, next) => {
  try {
    const { target } = req.body;
    const topic = await TopicTracker.findOneAndUpdate(
      { userId: req.user._id, topic: req.params.topicName },
      { target },
      { new: true }
    );
    res.json({ success: true, topic });
  } catch (err) { next(err); }
});

// ─── POST /topics/recalculate ─────────────────────────────────────
// Recalculate all topic stats from daily logs
router.post('/recalculate', async (req, res, next) => {
  try {
    const userId = req.user._id;

    const aggregated = await DailyLog.aggregate([
      { $match: { userId } },
      {
        $group: {
          _id: '$topic',
          totalSolved: { $sum: 1 },
          easySolved: { $sum: { $cond: [{ $eq: ['$difficulty', 'easy'] }, 1, 0] } },
          mediumSolved: { $sum: { $cond: [{ $eq: ['$difficulty', 'medium'] }, 1, 0] } },
          hardSolved: { $sum: { $cond: [{ $eq: ['$difficulty', 'hard'] }, 1, 0] } },
          lastPracticed: { $max: '$date' },
        },
      },
    ]);

    for (const t of aggregated) {
      await TopicTracker.findOneAndUpdate(
        { userId, topic: t._id },
        {
          totalSolved: t.totalSolved,
          easySolved: t.easySolved,
          mediumSolved: t.mediumSolved,
          hardSolved: t.hardSolved,
          lastPracticed: t.lastPracticed,
          status: 'active',
        },
        { upsert: true, new: true }
      );
    }

    const topics = await TopicTracker.find({ userId });
    res.json({ success: true, topics });
  } catch (err) { next(err); }
});

module.exports = router;
