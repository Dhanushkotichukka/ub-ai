const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Note = require('../models/Note');

router.use(protect);

// ─── GET /notes ───────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { folder, tag, search, limit = 50, skip = 0, pinned } = req.query;
    const filter = { userId: req.user._id, isArchived: false };

    if (folder) filter.folderPath = { $regex: `^${folder}`, $options: 'i' };
    if (tag) filter.tags = tag.toLowerCase();
    if (pinned === 'true') filter.isPinned = true;
    if (search) filter.$text = { $search: search };

    const notes = await Note.find(filter)
      .sort({ isPinned: -1, updatedAt: -1 })
      .limit(Number(limit))
      .skip(Number(skip))
      .select('-content'); // exclude heavy content from list view

    const total = await Note.countDocuments(filter);
    res.json({ success: true, notes, total });
  } catch (err) { next(err); }
});

// ─── GET /notes/folders ───────────────────────────────────────────
router.get('/folders', async (req, res, next) => {
  try {
    const folders = await Note.aggregate([
      { $match: { userId: req.user._id, isArchived: false } },
      { $group: { _id: '$folderPath', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]);
    res.json({ success: true, folders });
  } catch (err) { next(err); }
});

// ─── POST /notes/folders ──────────────────────────────────────────
router.post('/folders', async (req, res, next) => {
  try {
    const { name, parentPath } = req.body;
    const fullPath = parentPath ? `${parentPath}/${name}` : name;
    res.json({ success: true, folder: { path: fullPath, name } });
  } catch (err) { next(err); }
});

// ─── GET /notes/:id ───────────────────────────────────────────────
router.get('/:id', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });
    res.json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── POST /notes ──────────────────────────────────────────────────
router.post('/', async (req, res, next) => {
  try {
    const { title, content, folder, tags, color, isPinned } = req.body;
    const folderPath = folder || 'All Notes';

    // Extract plain text from Quill delta for search
    let contentText = '';
    if (content?.ops) {
      contentText = content.ops.map(op => (typeof op.insert === 'string' ? op.insert : '')).join('');
    }

    const note = await Note.create({
      userId: req.user._id,
      title: title || 'Untitled Note',
      content,
      contentText,
      folder: folderPath.split('/').pop(),
      folderPath,
      tags: (tags || []).map(t => t.toLowerCase()),
      color: color || 'default',
      isPinned: isPinned || false,
      hasCode: contentText.includes('```') || contentText.includes('code'),
    });

    res.status(201).json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── PUT /notes/:id ───────────────────────────────────────────────
router.put('/:id', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const allowed = ['title', 'content', 'folder', 'folderPath', 'tags', 'color', 'isPinned', 'isArchived', 'flashcards'];
    allowed.forEach(f => { if (req.body[f] !== undefined) note[f] = req.body[f]; });

    if (req.body.content?.ops) {
      note.contentText = req.body.content.ops.map(op => (typeof op.insert === 'string' ? op.insert : '')).join('');
    }

    await note.save();
    res.json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── DELETE /notes/:id ────────────────────────────────────────────
router.delete('/:id', async (req, res, next) => {
  try {
    const note = await Note.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });
    res.json({ success: true, message: 'Note deleted' });
  } catch (err) { next(err); }
});

module.exports = router;
