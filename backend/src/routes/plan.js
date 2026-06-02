const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const TodoPlan = require('../models/TodoPlan');
const { v4: uuidv4 } = require('uuid');

router.use(protect);

// ─── GET /plan ────────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { date } = req.query;
    const queryDate = date ? new Date(date) : new Date();
    queryDate.setHours(0, 0, 0, 0);

    let plan = await TodoPlan.findOne({ userId: req.user._id, date: queryDate });

    // Auto-generate plan if not exists for today
    if (!plan && !date) {
      plan = await autoGeneratePlan(req.user._id, queryDate);
    }

    res.json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── POST /plan ───────────────────────────────────────────────────
router.post('/', async (req, res, next) => {
  try {
    const { date, title, tasks, notes } = req.body;
    const planDate = date ? new Date(date) : new Date();
    planDate.setHours(0, 0, 0, 0);

    const plan = await TodoPlan.findOneAndUpdate(
      { userId: req.user._id, date: planDate },
      { title: title || "Today's Plan", tasks: tasks || [], notes: notes || '' },
      { upsert: true, new: true }
    );

    res.status(201).json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── POST /plan/task ──────────────────────────────────────────────
router.post('/task', async (req, res, next) => {
  try {
    const { date, task } = req.body;
    const planDate = date ? new Date(date) : new Date();
    planDate.setHours(0, 0, 0, 0);

    const newTask = { id: uuidv4(), isCompleted: false, ...task };

    const plan = await TodoPlan.findOneAndUpdate(
      { userId: req.user._id, date: planDate },
      { $push: { tasks: newTask } },
      { upsert: true, new: true }
    );

    res.json({ success: true, plan, task: newTask });
  } catch (err) { next(err); }
});

// ─── PUT /plan/task/:taskId ───────────────────────────────────────
router.put('/task/:taskId', async (req, res, next) => {
  try {
    const { date, isCompleted, text, priority, link } = req.body;
    const planDate = date ? new Date(date) : new Date();
    planDate.setHours(0, 0, 0, 0);

    const setFields = {};
    if (isCompleted !== undefined) {
      setFields['tasks.$.isCompleted'] = isCompleted;
      if (isCompleted) setFields['tasks.$.completedAt'] = new Date();
    }
    if (text !== undefined) setFields['tasks.$.text'] = text;
    if (priority !== undefined) setFields['tasks.$.priority'] = priority;
    if (link !== undefined) setFields['tasks.$.link'] = link;

    const plan = await TodoPlan.findOneAndUpdate(
      { userId: req.user._id, date: planDate, 'tasks.id': req.params.taskId },
      { $set: setFields },
      { new: true }
    );

    if (!plan) return res.status(404).json({ success: false, message: 'Plan or task not found' });

    // Award XP when daily goal completed
    const completedCount = plan.tasks.filter(t => t.isCompleted).length;
    if (isCompleted && completedCount === plan.tasks.length) {
      const { awardXP } = require('../services/gamificationService');
      await awardXP(req.user._id, 'daily_goal_completed', { date: planDate });
    }

    res.json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── DELETE /plan/task/:taskId ────────────────────────────────────
router.delete('/task/:taskId', async (req, res, next) => {
  try {
    const { date } = req.query;
    const planDate = date ? new Date(date) : new Date();
    planDate.setHours(0, 0, 0, 0);

    const plan = await TodoPlan.findOneAndUpdate(
      { userId: req.user._id, date: planDate },
      { $pull: { tasks: { id: req.params.taskId } } },
      { new: true }
    );

    res.json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── POST /plan/auto-generate ─────────────────────────────────────
router.post('/auto-generate', async (req, res, next) => {
  try {
    const { date } = req.body;
    const planDate = date ? new Date(date) : new Date();
    planDate.setHours(0, 0, 0, 0);

    const plan = await autoGeneratePlan(req.user._id, planDate);
    res.json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── Helper: Auto-generate daily plan ────────────────────────────
const autoGeneratePlan = async (userId, date) => {
  const TopicTracker = require('../models/TopicTracker');
  const RevisionSchedule = require('../models/RevisionSchedule');
  const { fetchLeetCodePOTD } = require('../services/platformService');

  const tasks = [];

  // 1. Get weak topics (lowest mastery)
  const weakTopics = await TopicTracker.find({ userId })
    .sort({ mastery: 1, totalSolved: 1 })
    .limit(3);

  const topics = ['Arrays', 'Dynamic Programming', 'Graphs'];
  const problemsForTopics = [
    { name: 'Find Minimum in Rotated Sorted Array', link: 'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/', platform: 'LeetCode', topic: 'Arrays', difficulty: 'medium' },
    { name: 'Coin Change', link: 'https://leetcode.com/problems/coin-change/', platform: 'LeetCode', topic: 'Dynamic Programming', difficulty: 'medium' },
    { name: 'Number of Islands', link: 'https://leetcode.com/problems/number-of-islands/', platform: 'LeetCode', topic: 'Graphs', difficulty: 'medium' },
  ];

  for (let i = 0; i < Math.min(weakTopics.length, 3); i++) {
    const t = weakTopics[i];
    const suggestion = problemsForTopics[i] || {};
    tasks.push({
      id: uuidv4(),
      text: suggestion.name || `Practice ${t.topic}`,
      type: 'problem',
      platform: suggestion.platform || 'LeetCode',
      link: suggestion.link || `https://leetcode.com/problems/`,
      isCompleted: false,
      priority: 'high',
      estimatedMinutes: 30,
    });
  }

  // 2. Add due revision
  const dueRevision = await RevisionSchedule.findOne({
    userId,
    nextRevisionDate: { $lte: new Date() },
    isCompleted: false,
  }).sort({ nextRevisionDate: 1 });

  if (dueRevision) {
    tasks.push({
      id: uuidv4(),
      text: `Revise: ${dueRevision.problemName}`,
      type: 'revision',
      platform: dueRevision.platform,
      link: dueRevision.link,
      isCompleted: false,
      priority: 'medium',
      estimatedMinutes: 20,
    });
  }

  // 3. Add LeetCode POTD
  const potd = await fetchLeetCodePOTD().catch(() => null);
  if (potd) {
    tasks.push({
      id: uuidv4(),
      text: `LeetCode POTD: ${potd.title}`,
      type: 'problem',
      platform: 'LeetCode',
      link: potd.link,
      isCompleted: false,
      priority: 'low',
      estimatedMinutes: 30,
    });
  }

  const plan = await TodoPlan.findOneAndUpdate(
    { userId, date },
    { tasks, isAutoGenerated: true, aiGenerated: false },
    { upsert: true, new: true }
  );

  return plan;
};

module.exports = router;
