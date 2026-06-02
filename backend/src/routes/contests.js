const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const axios = require('axios');

router.use(protect);

// ─── GET /contests/upcoming ───────────────────────────────────────
router.get('/upcoming', async (req, res, next) => {
  try {
    const [cfContests, lcContests] = await Promise.allSettled([
      fetchCodeforcesContests(),
      fetchLeetCodeContests(),
    ]);

    const all = [
      ...(cfContests.status === 'fulfilled' ? cfContests.value : []),
      ...(lcContests.status === 'fulfilled' ? lcContests.value : []),
    ].sort((a, b) => new Date(a.startTime) - new Date(b.startTime));

    res.json({ success: true, contests: all });
  } catch (err) { next(err); }
});

// ─── Fetch Codeforces upcoming contests ──────────────────────────
const fetchCodeforcesContests = async () => {
  const { data } = await axios.get('https://codeforces.com/api/contest.list?gym=false', { timeout: 8000 });
  const upcoming = (data.result || [])
    .filter(c => c.phase === 'BEFORE')
    .slice(0, 10)
    .map(c => ({
      id: `cf-${c.id}`,
      platform: 'Codeforces',
      name: c.name,
      startTime: new Date(c.startTimeSeconds * 1000).toISOString(),
      durationSeconds: c.durationSeconds,
      registerUrl: `https://codeforces.com/contests/${c.id}`,
      type: c.type,
    }));
  return upcoming;
};

// ─── Fetch LeetCode upcoming contests via GraphQL ─────────────────
const fetchLeetCodeContests = async () => {
  const query = `
    query {
      allContests {
        title
        titleSlug
        startTime
        duration
        isVirtual
      }
    }
  `;
  const { data } = await axios.post('https://leetcode.com/graphql', { query }, {
    headers: { 'Content-Type': 'application/json', 'Referer': 'https://leetcode.com' },
    timeout: 8000,
  });
  const now = Date.now() / 1000;
  return (data?.data?.allContests || [])
    .filter(c => c.startTime > now && !c.isVirtual)
    .slice(0, 5)
    .map(c => ({
      id: `lc-${c.titleSlug}`,
      platform: 'LeetCode',
      name: c.title,
      startTime: new Date(c.startTime * 1000).toISOString(),
      durationSeconds: c.duration,
      registerUrl: `https://leetcode.com/contest/${c.titleSlug}`,
    }));
};

module.exports = router;
