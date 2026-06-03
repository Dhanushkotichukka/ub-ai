const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const Note = require('../models/Note');
const axios = require('axios');

router.use(protect);

const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

const callGemini = async (prompt) => {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('Gemini API key not configured');
  const { data } = await axios.post(
    `${GEMINI_API_URL}?key=${apiKey}`,
    { contents: [{ parts: [{ text: prompt }] }] },
    { headers: { 'Content-Type': 'application/json' }, timeout: 30000 }
  );
  return data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
};

// Helper: Extract plain text from Quill delta
const extractText = (content) => {
  if (!content) return '';
  if (typeof content === 'string') return content;
  if (content?.ops) return content.ops.map(op => (typeof op.insert === 'string' ? op.insert : '')).join('');
  return '';
};

// ─── GET /notes/stats ─────────────────────────────────────────────
router.get('/stats', async (req, res, next) => {
  try {
    const userId = req.user._id;
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    const todayStr = new Date().toISOString().slice(0, 10);

    const [total, thisWeek, withFlashcards, withQuiz, dueForReview, chatMessages] = await Promise.all([
      Note.countDocuments({ userId, isArchived: false }),
      Note.countDocuments({ userId, isArchived: false, createdAt: { $gte: oneWeekAgo } }),
      Note.countDocuments({ userId, isArchived: false, 'flashcards.0': { $exists: true } }),
      Note.countDocuments({ userId, isArchived: false, 'quiz.0': { $exists: true } }),
      Note.countDocuments({ userId, isArchived: false, nextReviewDate: { $lte: todayStr } }),
      Note.aggregate([
        { $match: { userId } },
        { $project: { chatCount: { $size: { $ifNull: ['$aiChatHistory', []] } } } },
        { $group: { _id: null, total: { $sum: '$chatCount' } } },
      ]),
    ]);

    res.json({
      success: true,
      stats: {
        total,
        thisWeek,
        flashcardsGenerated: withFlashcards,
        quizzesGenerated: withQuiz,
        dueForReview,
        aiChatsUsed: chatMessages[0]?.total || 0,
      },
    });
  } catch (err) { next(err); }
});

// ─── GET /notes/daily ─────────────────────────────────────────────
router.get('/daily', async (req, res, next) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    let note = await Note.findOne({ userId: req.user._id, noteType: 'daily', dailyDate: today });

    if (!note) {
      const dateObj = new Date();
      const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
      const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      const dateStr = `${days[dateObj.getDay()]}, ${dateObj.getDate()} ${months[dateObj.getMonth()]} ${dateObj.getFullYear()}`;

      const template = `# 📅 Daily Journal — ${dateStr}\n\n---\n\n😊 **Mood:** \n\n📚 **What did I study today?**\n\n\n\n💡 **What new concepts did I learn?**\n\n\n\n🎯 **What did I complete today?**\n\n- [ ] \n\n🚀 **Goals for tomorrow:**\n\n- [ ] \n\n📝 **Additional Notes:**\n\n`;

      note = await Note.create({
        userId: req.user._id,
        title: `Journal — ${dateStr}`,
        contentText: template,
        content: { ops: [{ insert: template }] },
        noteType: 'daily',
        dailyDate: today,
        folderPath: 'Journal',
        folder: 'Journal',
        collection: 'Personal Journal',
        color: 'blue',
      });
    }

    res.json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── GET /notes/revision ─────────────────────────────────────────
router.get('/revision', async (req, res, next) => {
  try {
    const today = new Date().toISOString().slice(0, 10);
    const notes = await Note.find({
      userId: req.user._id,
      isArchived: false,
      nextReviewDate: { $lte: today },
    }).sort({ nextReviewDate: 1 }).limit(20).select('-content');
    res.json({ success: true, notes });
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

// ─── GET /notes/:id ───────────────────────────────────────────────
router.get('/:id', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });
    res.json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── GET /notes ───────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const { folder, tag, search, type, collection, limit = 50, skip = 0, pinned, favorited, dueReview } = req.query;
    const filter = { userId: req.user._id, isArchived: false };

    if (folder) filter.folderPath = { $regex: `^${folder}`, $options: 'i' };
    if (tag) filter.tags = tag.toLowerCase();
    if (pinned === 'true') filter.isPinned = true;
    if (favorited === 'true') filter.isFavorited = true;
    if (type) filter.noteType = type;
    if (collection) filter.collection = collection;
    if (dueReview === 'true') {
      const today = new Date().toISOString().slice(0, 10);
      filter.nextReviewDate = { $lte: today };
    }
    if (search) filter.$text = { $search: search };

    const notes = await Note.find(filter)
      .sort({ isPinned: -1, isFavorited: -1, updatedAt: -1 })
      .limit(Number(limit))
      .skip(Number(skip))
      .select('-content -aiChatHistory');

    const total = await Note.countDocuments(filter);
    res.json({ success: true, notes, total });
  } catch (err) { next(err); }
});

// ─── POST /notes ──────────────────────────────────────────────────
router.post('/', async (req, res, next) => {
  try {
    const { title, content, folder, tags, color, isPinned, noteType, collection, dailyDate } = req.body;
    const folderPath = folder || 'General';
    const contentText = extractText(content) || (typeof content === 'string' ? content : '');

    const note = await Note.create({
      userId: req.user._id,
      title: title || 'Untitled Note',
      content: content || { ops: [{ insert: '\n' }] },
      contentText,
      folder: folderPath.split('/').pop(),
      folderPath,
      collection: collection || 'General',
      tags: (tags || []).map(t => t.toLowerCase()),
      color: color || 'default',
      isPinned: isPinned || false,
      noteType: noteType || 'quick',
      dailyDate: dailyDate || null,
      hasCode: contentText.includes('```'),
    });

    res.status(201).json({ success: true, note });
  } catch (err) { next(err); }
});

// ─── PUT /notes/:id ───────────────────────────────────────────────
router.put('/:id', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const allowed = ['title', 'content', 'folder', 'folderPath', 'collection', 'tags', 'color',
      'isPinned', 'isFavorited', 'isArchived', 'flashcards', 'quiz', 'noteType', 'revisionSchedule', 'nextReviewDate'];
    allowed.forEach(f => { if (req.body[f] !== undefined) note[f] = req.body[f]; });

    if (req.body.content) {
      note.contentText = extractText(req.body.content);
      note.hasCode = note.contentText.includes('```');
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

// ─── POST /notes/:id/ai-chat ──────────────────────────────────────
router.post('/:id/ai-chat', async (req, res, next) => {
  try {
    const { message } = req.body;
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const noteContent = note.contentText?.slice(0, 3000) || 'No content yet.';
    const recentHistory = (note.aiChatHistory || []).slice(-6).map(m => `${m.role === 'user' ? 'User' : 'AI'}: ${m.content}`).join('\n');

    const prompt = `You are an AI study assistant. The user is asking about their note titled: "${note.title}".

Note Content:
---
${noteContent}
---

Recent Chat History:
${recentHistory || 'None'}

User Question: ${message}

Answer helpfully and concisely, directly related to this note's content. If relevant, suggest practice problems or next steps.`;

    const reply = await callGemini(prompt);

    note.aiChatHistory = note.aiChatHistory || [];
    note.aiChatHistory.push({ role: 'user', content: message });
    note.aiChatHistory.push({ role: 'assistant', content: reply });
    // Keep only last 50 messages
    if (note.aiChatHistory.length > 50) note.aiChatHistory = note.aiChatHistory.slice(-50);
    await note.save();

    res.json({ success: true, reply });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/auto-tag ─────────────────────────────────────
router.post('/:id/auto-tag', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const content = note.contentText?.slice(0, 2000) || '';
    const prompt = `Given this note content, suggest a concise title (max 8 words) and 3-6 relevant tags.
Return only JSON: {"title": "...", "tags": ["tag1", "tag2", "tag3"]}

Note content:
${content}`;

    const reply = await callGemini(prompt);
    let result = {};
    try {
      const match = reply.match(/\{[\s\S]*\}/);
      if (match) result = JSON.parse(match[0]);
    } catch (e) { result = { title: note.title, tags: [] }; }

    res.json({ success: true, title: result.title || note.title, tags: result.tags || [] });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/summary ──────────────────────────────────────
router.post('/:id/summary', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const content = note.contentText?.slice(0, 2000) || '';
    const prompt = `Summarize this note in exactly one sentence (max 15 words), capturing the key concept:\n\n${content}`;
    const summary = await callGemini(prompt);

    note.aiSummary = summary.trim();
    await note.save();

    res.json({ success: true, aiSummary: note.aiSummary });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/quiz ─────────────────────────────────────────
router.post('/:id/quiz', async (req, res, next) => {
  try {
    const { questionCount = 5 } = req.body;
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const content = note.contentText?.slice(0, 3000) || '';
    const prompt = `Generate ${questionCount} quiz questions from this note. Include a mix of MCQ, true/false, and short answer types.
Return JSON array:
[
  {"type": "mcq", "question": "...", "options": ["A", "B", "C", "D"], "answer": "A", "explanation": "..."},
  {"type": "truefalse", "question": "...", "options": ["True", "False"], "answer": "True", "explanation": "..."},
  {"type": "short", "question": "...", "answer": "...", "explanation": "..."}
]
Note content:
${content}`;

    const reply = await callGemini(prompt);
    let quiz = [];
    try {
      const match = reply.match(/\[[\s\S]*\]/);
      if (match) quiz = JSON.parse(match[0]);
    } catch (e) { quiz = []; }

    note.quiz = quiz;
    await note.save();

    res.json({ success: true, quiz });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/roadmap ──────────────────────────────────────
router.post('/:id/roadmap', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const content = note.contentText?.slice(0, 2000) || '';
    const prompt = `Based on this study note, create a learning roadmap with next recommended topics and resources.
Format as clear markdown with sections: Prerequisites, Current Topic, Next Steps, Practice Problems, Resources.
Note: ${note.title}\nContent:\n${content}`;

    const roadmap = await callGemini(prompt);
    note.aiRoadmap = roadmap;
    await note.save();

    res.json({ success: true, roadmap });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/flashcards ───────────────────────────────────
router.post('/:id/flashcards', async (req, res, next) => {
  try {
    const { count = 7 } = req.body;
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const content = note.contentText?.slice(0, 3000) || '';
    const prompt = `Create ${count} high-quality flashcards from this note. Focus on key concepts and definitions.
Return JSON: [{"question": "...", "answer": "..."}]
Note:
${content}`;

    const reply = await callGemini(prompt);
    let flashcards = [];
    try {
      const match = reply.match(/\[[\s\S]*\]/);
      if (match) flashcards = JSON.parse(match[0]);
    } catch (e) { flashcards = []; }

    note.flashcards = flashcards;
    await note.save();

    res.json({ success: true, flashcards });
  } catch (err) { next(err); }
});

// ─── POST /notes/:id/revision-schedule ───────────────────────────
router.post('/:id/revision-schedule', async (req, res, next) => {
  try {
    const note = await Note.findOne({ _id: req.params.id, userId: req.user._id });
    if (!note) return res.status(404).json({ success: false, message: 'Note not found' });

    const today = new Date();
    const intervals = [1, 3, 7, 30];
    const schedule = intervals.map(days => {
      const date = new Date(today);
      date.setDate(date.getDate() + days);
      return { reviewDate: date.toISOString().slice(0, 10), interval: days, reviewed: false };
    });

    note.revisionSchedule = schedule;
    note.nextReviewDate = schedule[0].reviewDate;
    note.lastReviewedAt = today;
    note.reviewCount = (note.reviewCount || 0) + 1;
    await note.save();

    res.json({ success: true, revisionSchedule: schedule, nextReviewDate: note.nextReviewDate });
  } catch (err) { next(err); }
});

// ─── POST /notes/semantic-search ──────────────────────────────────
router.post('/semantic-search', async (req, res, next) => {
  try {
    const { query } = req.body;
    if (!query) return res.status(400).json({ success: false, message: 'Query required' });

    // First try full-text search
    const textResults = await Note.find({
      userId: req.user._id,
      isArchived: false,
      $text: { $search: query },
    }).limit(10).select('-content -aiChatHistory');

    // If enough results, return them
    if (textResults.length >= 3) {
      return res.json({ success: true, notes: textResults, searchType: 'text' });
    }

    // Semantic fallback: get all titles + summaries and let AI rank them
    const allNotes = await Note.find({ userId: req.user._id, isArchived: false })
      .select('title tags contentText aiSummary noteType').limit(100);

    const notesList = allNotes.map((n, i) => `[${i}] ${n.title} | Tags: ${n.tags.join(', ')} | ${(n.aiSummary || n.contentText || '').slice(0, 100)}`).join('\n');

    const prompt = `User is searching for: "${query}"
Here are notes (index | title | tags | preview):
${notesList}

Return the indices of the most relevant notes as a JSON array of numbers (max 8), ordered by relevance.
Example: [2, 0, 5]
Only return the JSON array.`;

    const reply = await callGemini(prompt);
    let indices = [];
    try {
      const match = reply.match(/\[[\s\S]*?\]/);
      if (match) indices = JSON.parse(match[0]).filter(i => typeof i === 'number' && i < allNotes.length);
    } catch (e) { indices = []; }

    const semanticResults = indices.map(i => allNotes[i]).filter(Boolean);
    const combined = [...textResults, ...semanticResults.filter(n => !textResults.find(t => t._id.equals(n._id)))].slice(0, 10);

    res.json({ success: true, notes: combined, searchType: 'semantic' });
  } catch (err) { next(err); }
});

module.exports = router;
