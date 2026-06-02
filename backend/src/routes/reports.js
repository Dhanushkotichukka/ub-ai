const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const AiReport = require('../models/AiReport');
const TopicTracker = require('../models/TopicTracker');
const DailyLog = require('../models/DailyLog');
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

// ─── GET /reports ─────────────────────────────────────────────────
router.get('/', async (req, res, next) => {
  try {
    const reports = await AiReport.find({ userId: req.user._id }).sort({ weekStartDate: -1 });
    res.json({ success: true, reports });
  } catch (err) { next(err); }
});

// ─── POST /reports/generate ───────────────────────────────────────
router.post('/generate', async (req, res, next) => {
  try {
    const user = req.user;
    
    // Determine week bounds (last 7 days)
    const weekEndDate = new Date();
    const weekStartDate = new Date();
    weekStartDate.setDate(weekEndDate.getDate() - 7);

    // Fetch user's activity for the week
    const recentLogs = await DailyLog.find({
      userId: user._id,
      date: { $gte: weekStartDate, $lte: weekEndDate }
    });

    const [weakTopics, strongTopics] = await Promise.all([
      TopicTracker.find({ userId: user._id }).sort({ mastery: 1 }).limit(3),
      TopicTracker.find({ userId: user._id }).sort({ mastery: -1 }).limit(3),
    ]);

    const weakList = weakTopics.map(t => t.topic);
    const strongList = strongTopics.map(t => t.topic);
    const problemsSolvedThisWeek = recentLogs.length;

    // Calculate a basic consistency score based on days active
    const activeDays = new Set(recentLogs.map(l => l.date.toISOString().split('T')[0])).size;
    let consistencyScore = Math.round((activeDays / 7) * 100);

    const prompt = `
Generate a weekly AI progress report for a coding student preparing for placements.

Student: ${user.name}
Goal: ${user.dreamCompany || 'Top Tech Companies'}
Problems Solved This Week: ${problemsSolvedThisWeek}
Active Days This Week: ${activeDays}/7
Consistency Score: ${consistencyScore}/100

Historically Strong Topics: ${strongList.join(', ') || 'None'}
Historically Weak Topics: ${weakList.join(', ') || 'None'}

Return a JSON object strictly matching this format:
{
  "interviewReadinessScore": (number between 0 and 100),
  "recommendedNextActions": ["Action 1", "Action 2", "Action 3"],
  "summary": "A brief encouraging summary of their week and what to focus on next."
}
Only output the JSON object without markdown fences.
`;

    const reply = await callGemini(prompt);
    let parsed = {
      interviewReadinessScore: 50,
      recommendedNextActions: ['Solve more problems consistently'],
      summary: 'Keep practicing!'
    };

    try {
      const match = reply.match(/\{[\s\S]*\}/);
      if (match) {
        parsed = JSON.parse(match[0]);
      }
    } catch (e) {
      console.error('Failed to parse AI report JSON:', reply);
    }

    const newReport = await AiReport.create({
      userId: user._id,
      weekStartDate,
      weekEndDate,
      strongTopics: strongList,
      weakTopics: weakList,
      consistencyScore,
      interviewReadinessScore: parsed.interviewReadinessScore,
      recommendedNextActions: parsed.recommendedNextActions,
      summary: parsed.summary,
    });

    res.status(201).json({ success: true, report: newReport });
  } catch (err) { next(err); }
});

module.exports = router;
