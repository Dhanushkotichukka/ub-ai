const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
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

// ─── GET /ai/chat ─────────────────────────────────────────────────
router.get('/chat', async (req, res, next) => {
  try {
    const CoachChat = require('../models/CoachChat');
    let chat = await CoachChat.findOne({ userId: req.user._id });
    if (!chat) {
      chat = await CoachChat.create({
        userId: req.user._id,
        messages: [{
          role: 'assistant',
          content: 'Hello! I am your AI placement coach. 🦉\n\nI can help you review DSA topics, plan your prep schedule, conduct a mock interview, or debug code. What would you like to focus on today?'
        }]
      });
    }
    res.json({ success: true, messages: chat.messages });
  } catch (err) { next(err); }
});

// ─── POST /ai/chat ────────────────────────────────────────────────
router.post('/chat', async (req, res, next) => {
  try {
    const { message } = req.body;
    const user = req.user;
    const CoachChat = require('../models/CoachChat');

    // Build context from user stats
    const DailyLog = require('../models/DailyLog');
    const TopicTracker = require('../models/TopicTracker');

    const [totalSolved, weakTopics, chatDoc] = await Promise.all([
      DailyLog.countDocuments({ userId: user._id }),
      TopicTracker.find({ userId: user._id }).sort({ mastery: 1 }).limit(5),
      CoachChat.findOne({ userId: user._id }),
    ]);

    let chat = chatDoc;
    if (!chat) {
      chat = new CoachChat({ userId: user._id, messages: [] });
    }

    // Add user message to DB
    chat.messages.push({ role: 'user', content: message });
    await chat.save();

    const historyPrompt = chat.messages
      .slice(-10) // Only take last 10 for context window size
      .map(m => `${m.role === 'user' ? 'Student' : 'Coach'}: ${m.content}`)
      .join('\n');

    const contextPrompt = `
You are OwlCoder AI Coach — a friendly, smart coding mentor for placement preparation.

Student Context:
- Name: ${user.name}
- Dream Company: ${user.dreamCompany || 'Not set'}
- Total Problems Solved: ${totalSolved}
- Streak: ${user.streak} days
- Level: ${user.level} (${user.xp} XP)
- Weak Topics: ${weakTopics.map(t => t.topic).join(', ') || 'None identified yet'}

Conversation History:
${historyPrompt}

Reply as a mentor to the last Student message. Be concise, motivating, and actionable. When recommending problems, always include LeetCode/GFG links. Use emojis sparingly.
`;

    const reply = await callGemini(contextPrompt);

    // Add assistant reply to DB
    chat.messages.push({ role: 'assistant', content: reply });
    await chat.save();

    res.json({ success: true, reply, timestamp: new Date().toISOString() });
  } catch (err) {
    if (err.message?.includes('API key')) {
      return res.status(503).json({ success: false, message: 'AI service not configured. Please add GEMINI_API_KEY.' });
    }
    next(err);
  }
});

// ─── POST /ai/generate-plan ───────────────────────────────────────
router.post('/generate-plan', async (req, res, next) => {
  try {
    const { goal, timeline, level, dailyHours } = req.body;

    const prompt = `
Create a detailed DSA study plan for placement preparation.
Goal: ${goal}
Timeline: ${timeline}
Current Level: ${level}
Daily Study Time: ${dailyHours} hours

Format the plan as JSON with this structure:
{
  "weeks": [
    {
      "week": 1,
      "theme": "Arrays & Strings",
      "topics": ["Arrays", "Strings"],
      "problems": [
        {
          "name": "Two Sum",
          "difficulty": "easy",
          "platform": "LeetCode",
          "link": "https://leetcode.com/problems/two-sum/",
          "estimatedMinutes": 20
        }
      ],
      "goal": "Master array manipulation"
    }
  ],
  "summary": "Brief plan description"
}
Provide 4-8 problems per week. Be realistic about the timeline.
`;

    const reply = await callGemini(prompt);
    
    // Try to parse JSON from response
    let plan = null;
    try {
      const jsonMatch = reply.match(/\{[\s\S]*\}/);
      if (jsonMatch) plan = JSON.parse(jsonMatch[0]);
    } catch (e) {
      plan = { rawText: reply };
    }

    res.json({ success: true, plan });
  } catch (err) { next(err); }
});

// ─── POST /ai/analyze ─────────────────────────────────────────────
router.post('/analyze', async (req, res, next) => {
  try {
    const user = req.user;
    const DailyLog = require('../models/DailyLog');
    const TopicTracker = require('../models/TopicTracker');

    const [totalSolved, byDiff, weakTopics, strongTopics] = await Promise.all([
      DailyLog.countDocuments({ userId: user._id }),
      DailyLog.aggregate([
        { $match: { userId: user._id } },
        { $group: { _id: '$difficulty', count: { $sum: 1 } } },
      ]),
      TopicTracker.find({ userId: user._id }).sort({ mastery: 1 }).limit(5),
      TopicTracker.find({ userId: user._id }).sort({ mastery: -1 }).limit(3),
    ]);

    const diffMap = {};
    byDiff.forEach(d => { diffMap[d._id] = d.count; });

    const prompt = `
Analyze this coding student's profile and give a detailed placement readiness assessment:

Stats:
- Total Solved: ${totalSolved}
- Easy: ${diffMap.easy || 0}, Medium: ${diffMap.medium || 0}, Hard: ${diffMap.hard || 0}
- Streak: ${user.streak} days
- Dream Company: ${user.dreamCompany || 'FAANG'}
- Weak Topics: ${weakTopics.map(t => `${t.topic} (${t.totalSolved} solved)`).join(', ')}
- Strong Topics: ${strongTopics.map(t => `${t.topic} (${t.totalSolved} solved)`).join(', ')}

Provide:
1. Overall placement readiness (0-100%)
2. Strengths
3. Areas to improve with specific problem recommendations
4. Next 2-week action plan
5. One motivating insight

Keep it concise and actionable.
`;

    const analysis = await callGemini(prompt);
    res.json({ success: true, analysis });
  } catch (err) { next(err); }
});

// ─── POST /ai/suggest ─────────────────────────────────────────────
router.post('/suggest', async (req, res, next) => {
  try {
    const { topic, difficulty, count = 5 } = req.body;

    const prompt = `
Suggest ${count} LeetCode problems for topic: ${topic}, difficulty: ${difficulty || 'medium'}.
Return JSON array:
[{"name":"Two Sum","link":"https://leetcode.com/problems/two-sum/","difficulty":"easy","why":"Great intro to hashing"}]
Only return the JSON array.
`;

    const reply = await callGemini(prompt);
    let problems = [];
    try {
      const match = reply.match(/\[[\s\S]*\]/);
      if (match) problems = JSON.parse(match[0]);
    } catch (e) {
      problems = [];
    }

    res.json({ success: true, problems });
  } catch (err) { next(err); }
});

// ─── POST /ai/notes-assistant ─────────────────────────────────────
router.post('/notes-assistant', async (req, res, next) => {
  try {
    const { action, content, topic } = req.body;
    let prompt = '';

    switch (action) {
      case 'summarize':
        prompt = `Summarize this coding note concisely:\n\n${content}`;
        break;
      case 'flashcards':
        prompt = `Create 5 flashcard Q&A pairs from this note. Return JSON: [{"question":"Q","answer":"A"}]\n\n${content}`;
        break;
      case 'quiz':
        prompt = `Create a 5-question multiple choice quiz from this note. Return JSON with questions, options, and answers.\n\n${content}`;
        break;
      case 'explain':
        prompt = `Explain this concept simply with examples:\n\n${content}`;
        break;
      case 'complexity':
        prompt = `Analyze the time and space complexity of this code and explain:\n\n${content}`;
        break;
      case 'fix':
        prompt = `Find and fix bugs in this code, explain what was wrong:\n\n${content}`;
        break;
      default:
        prompt = content;
    }

    const reply = await callGemini(prompt);
    
    let result = reply;
    if (action === 'flashcards' || action === 'quiz') {
      try {
        const match = reply.match(/\[[\s\S]*\]/);
        if (match) result = JSON.parse(match[0]);
      } catch (e) { result = reply; }
    }

    res.json({ success: true, result });
  } catch (err) { next(err); }
});

module.exports = router;
