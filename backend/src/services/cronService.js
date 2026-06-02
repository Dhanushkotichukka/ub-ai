const cron = require('node-cron');
const User = require('../models/User');
const PlatformStats = require('../models/PlatformStats');
const {
  fetchLeetCodeStats,
  fetchCodeforcesStats,
  fetchGFGStats,
  fetchCodeChefStats,
} = require('./platformService');

const startCronJobs = () => {
  console.log('⏰ Cron jobs registered');

  // ─── Nightly Platform Sync (11:55 PM every night) ────────────────────────
  cron.schedule('55 23 * * *', async () => {
    console.log('[Cron] Starting nightly platform sync...');
    try {
      const users = await User.find({
        $or: [
          { 'platforms.leetcode': { $exists: true, $ne: '' } },
          { 'platforms.gfg': { $exists: true, $ne: '' } },
          { 'platforms.codeforces': { $exists: true, $ne: '' } },
          { 'platforms.codechef': { $exists: true, $ne: '' } },
        ],
      }).select('platforms _id');

      let synced = 0;
      for (const user of users) {
        try {
          const platforms = [
            { key: 'leetcode', fetch: () => fetchLeetCodeStats(user.platforms.leetcode) },
            { key: 'gfg', fetch: () => fetchGFGStats(user.platforms.gfg) },
            { key: 'codeforces', fetch: () => fetchCodeforcesStats(user.platforms.codeforces) },
            { key: 'codechef', fetch: () => fetchCodeChefStats(user.platforms.codechef) },
          ];

          for (const p of platforms) {
            if (!user.platforms[p.key]) continue;
            const stats = await p.fetch();
            if (stats) {
              await PlatformStats.findOneAndUpdate(
                { userId: user._id, platform: p.key },
                { ...stats, lastSynced: new Date() },
                { upsert: true, new: true }
              );
            }
            // Delay between requests to avoid rate limiting
            await new Promise(r => setTimeout(r, 500));
          }
          synced++;
        } catch (err) {
          console.error(`[Cron] Failed sync for user ${user._id}:`, err.message);
        }
      }
      console.log(`[Cron] Nightly sync complete. Synced ${synced}/${users.length} users.`);
    } catch (err) {
      console.error('[Cron] Nightly sync error:', err.message);
    }
  }, { timezone: 'Asia/Kolkata' });

  // ─── Streak check (Midnight IST) ──────────────────────────────────────────
  cron.schedule('0 0 * * *', async () => {
    console.log('[Cron] Checking streaks...');
    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      // Users who were active yesterday but not today — streak at risk
      await User.updateMany(
        { lastActiveDate: { $lt: yesterday }, streak: { $gt: 0 } },
        { $set: { streak: 0 } }
      );
    } catch (err) {
      console.error('[Cron] Streak check error:', err.message);
    }
  }, { timezone: 'Asia/Kolkata' });
};

module.exports = { startCronJobs };
