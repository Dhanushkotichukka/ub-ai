const User = require('../models/User');
const { XpEvent, Badge, BADGES, XP_VALUES } = require('../models/Gamification');
const TopicTracker = require('../models/TopicTracker');

// Level thresholds
const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 2000, 3500, 5500, 8000, 12000, 18000, 25000, 35000];
const LEVEL_NAMES = ['Beginner','Novice','Learner','Apprentice','Intermediate','Skilled','Proficient','Advanced','Expert','Master','Champion','Legend'];

const getLevelFromXP = (xp) => {
  let level = 1;
  for (let i = LEVEL_THRESHOLDS.length - 1; i >= 0; i--) {
    if (xp >= LEVEL_THRESHOLDS[i]) { level = i + 1; break; }
  }
  return {
    level,
    name: LEVEL_NAMES[level - 1],
    currentThreshold: LEVEL_THRESHOLDS[level - 1],
    nextThreshold: LEVEL_THRESHOLDS[level] || null,
    progress: LEVEL_THRESHOLDS[level]
      ? Math.round(((xp - LEVEL_THRESHOLDS[level - 1]) / (LEVEL_THRESHOLDS[level] - LEVEL_THRESHOLDS[level - 1])) * 100)
      : 100,
  };
};

/**
 * Award XP to a user for an event.
 * @param {string} userId
 * @param {string} event - one of XP_VALUES keys
 * @param {object} metadata - optional context (problemName, etc.)
 * @returns {object} { xpGained, newXP, levelInfo, leveledUp }
 */
const awardXP = async (userId, event, metadata = {}) => {
  const xpGained = XP_VALUES[event] || 0;
  if (xpGained === 0) return null;

  const user = await User.findById(userId).select('xp level badges streak');
  if (!user) return null;

  const oldLevel = user.level;
  user.xp += xpGained;

  const levelInfo = getLevelFromXP(user.xp);
  user.level = levelInfo.level;

  await user.save();

  // Log XP event
  await XpEvent.create({
    userId,
    event,
    xpGained,
    totalXpAfter: user.xp,
    levelAfter: user.level,
    metadata,
  });

  const leveledUp = levelInfo.level > oldLevel;

  return { xpGained, newXP: user.xp, levelInfo, leveledUp };
};

/**
 * Check and award badges based on user stats.
 * @param {string} userId
 * @param {object} stats - { totalSolved, difficulty, streak, topic, timeTaken }
 * @returns {Array} newly earned badges
 */
const checkAndAwardBadges = async (userId, stats = {}) => {
  const { totalSolved = 0, difficulty, streak = 0, topic, timeTaken } = stats;
  const newBadges = [];

  const existingBadges = (await Badge.find({ userId })).map(b => b.badgeId);

  const tryAward = async (badgeId) => {
    if (existingBadges.includes(badgeId)) return;
    const def = BADGES[badgeId];
    if (!def) return;
    await Badge.create({ userId, badgeId: def.id, badgeName: def.name, badgeIcon: def.icon, description: def.description });
    await User.findByIdAndUpdate(userId, { $addToSet: { badges: badgeId } });
    await awardXP(userId, 'badge_earned', { badge: badgeId });
    newBadges.push(def);
  };

  // First problem
  if (totalSolved >= 1) await tryAward('first_step');
  // Hard problem
  if (difficulty === 'hard') await tryAward('hard_nut');
  // 100 problems
  if (totalSolved >= 100) await tryAward('centurion');
  // 500 problems
  if (totalSolved >= 500) await tryAward('champion');
  // 1000 problems
  if (totalSolved >= 1000) await tryAward('maang_ready');
  // Streak badges
  if (streak >= 7) await tryAward('on_fire');
  if (streak >= 30) await tryAward('streak_warrior');

  // Topic-specific badges
  if (topic) {
    const topicDoc = await TopicTracker.findOne({ userId, topic });
    if (topicDoc) {
      if (topic === 'Dynamic Programming' && topicDoc.totalSolved >= 50) await tryAward('dp_destroyer');
      if ((topic === 'Trees' || topic === 'Binary Trees') && topicDoc.totalSolved >= 50) await tryAward('tree_titan');
      if (topic === 'Graphs' && topicDoc.totalSolved >= 50) await tryAward('graph_guru');
    }
  }

  return newBadges;
};

/**
 * Update user streak based on last active date.
 * @param {string} userId
 * @returns {{ streak: number, streakBroken: boolean }}
 */
const updateStreak = async (userId) => {
  const user = await User.findById(userId).select('streak lastActiveDate longestStreak');
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let streakBroken = false;

  if (!user.lastActiveDate) {
    user.streak = 1;
  } else {
    const last = new Date(user.lastActiveDate);
    last.setHours(0, 0, 0, 0);
    const diffDays = Math.round((today - last) / (1000 * 60 * 60 * 24));

    if (diffDays === 0) {
      // Already active today — no change
    } else if (diffDays === 1) {
      user.streak += 1;
    } else {
      // Streak broken
      user.streak = 1;
      streakBroken = true;
    }
  }

  if (user.streak > (user.longestStreak || 0)) {
    user.longestStreak = user.streak;
  }
  user.lastActiveDate = today;
  await user.save();

  // Award streak-based XP
  if (user.streak === 7) await awardXP(userId, 'streak_7');
  if (user.streak === 30) await awardXP(userId, 'streak_30');
  if (user.streak === 100) await awardXP(userId, 'streak_100');

  return { streak: user.streak, streakBroken, longestStreak: user.longestStreak };
};

module.exports = { awardXP, checkAndAwardBadges, updateStreak, getLevelFromXP, LEVEL_THRESHOLDS, LEVEL_NAMES };
