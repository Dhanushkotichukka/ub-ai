const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const PlatformStats = require('../models/PlatformStats');
const { fetchLeetCodeStats, fetchCodeforcesStats, fetchGFGStats, fetchCodeChefStats, fetchLeetCodePOTD, fetchGFGPOTD } = require('../services/platformService');

router.use(protect);

// ─── GET /platforms/stats ─────────────────────────────────────────
router.get('/stats', async (req, res, next) => {
  try {
    const stats = await PlatformStats.find({ userId: req.user._id });
    res.json({ success: true, stats });
  } catch (err) { next(err); }
});

// ─── POST /platforms/sync ─────────────────────────────────────────
// Manual sync trigger — fetches fresh stats for all user platforms
router.post('/sync', async (req, res, next) => {
  try {
    const { platforms } = req.user;
    const results = [];

    const fetchers = [
      { key: 'leetcode', fn: () => fetchLeetCodeStats(platforms.leetcode) },
      { key: 'gfg', fn: () => fetchGFGStats(platforms.gfg) },
      { key: 'codeforces', fn: () => fetchCodeforcesStats(platforms.codeforces) },
      { key: 'codechef', fn: () => fetchCodeChefStats(platforms.codechef) },
    ];

    for (const { key, fn } of fetchers) {
      if (!platforms[key]) continue;
      try {
        const data = await fn();
        if (data) {
          const updated = await PlatformStats.findOneAndUpdate(
            { userId: req.user._id, platform: key },
            { ...data, lastSynced: new Date() },
            { upsert: true, new: true }
          );
          results.push(updated);
        }
      } catch (e) {
        console.error(`Sync failed for ${key}:`, e.message);
      }
    }

    res.json({ success: true, synced: results.length, stats: results });
  } catch (err) { next(err); }
});

// ─── GET /platforms/potd ──────────────────────────────────────────
router.get('/potd', async (req, res, next) => {
  try {
    const [lc, gfg] = await Promise.allSettled([fetchLeetCodePOTD(), fetchGFGPOTD()]);
    res.json({
      success: true,
      potd: {
        leetcode: lc.status === 'fulfilled' ? lc.value : null,
        gfg: gfg.status === 'fulfilled' ? gfg.value : null,
      },
    });
  } catch (err) { next(err); }
});

// ─── GET /platforms/stats/:platform ──────────────────────────────
router.get('/stats/:platform', async (req, res, next) => {
  try {
    const stat = await PlatformStats.findOne({
      userId: req.user._id,
      platform: req.params.platform,
    });
    if (!stat) return res.status(404).json({ success: false, message: 'No stats found for this platform' });
    res.json({ success: true, stat });
  } catch (err) { next(err); }
});

module.exports = router;
