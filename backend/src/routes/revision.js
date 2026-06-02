const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const RevisionSchedule = require('../models/RevisionSchedule');
const { awardXP } = require('../services/gamificationService');

router.use(protect);

// ─── GET /revision/due ────────────────────────────────────────────
router.get('/due', async (req, res, next) => {
  try {
    const revisions = await RevisionSchedule.find({
      userId: req.user._id,
      nextRevisionDate: { $lte: new Date() },
      isCompleted: false,
    }).sort({ nextRevisionDate: 1 });
    res.json({ success: true, revisions, count: revisions.length });
  } catch (err) { next(err); }
});

// ─── GET /revision/schedule ───────────────────────────────────────
router.get('/schedule', async (req, res, next) => {
  try {
    const schedule = await RevisionSchedule.find({ userId: req.user._id, isCompleted: false })
      .sort({ nextRevisionDate: 1 });
    res.json({ success: true, schedule });
  } catch (err) { next(err); }
});

// ─── POST /revision/mark/:id ──────────────────────────────────────
router.post('/mark/:id', async (req, res, next) => {
  try {
    const { confidence } = req.body;
    const revision = await RevisionSchedule.findOne({ _id: req.params.id, userId: req.user._id });
    if (!revision) return res.status(404).json({ success: false, message: 'Revision not found' });

    revision.markRevised(confidence);
    await revision.save();

    await awardXP(req.user._id, 'revision_completed', { problemName: revision.problemName });

    res.json({ success: true, revision });
  } catch (err) { next(err); }
});

module.exports = router;
