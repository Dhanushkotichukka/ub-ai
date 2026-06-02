const mongoose = require('mongoose');

// XP event log for audit trail
const xpEventSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  event: {
    type: String,
    enum: [
      'easy_solved', 'medium_solved', 'hard_solved',
      'daily_goal_completed', 'contest_participated', 'revision_completed',
      'streak_7', 'streak_30', 'streak_100',
      'badge_earned', 'onboarding_complete',
    ],
    required: true,
  },
  xpGained: { type: Number, required: true },
  totalXpAfter: { type: Number, required: true },
  levelAfter: { type: Number, required: true },
  metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

// Badge definition
const badgeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  badgeId: { type: String, required: true },
  badgeName: { type: String, required: true },
  badgeIcon: { type: String, required: true },
  description: { type: String, required: true },
  earnedAt: { type: Date, default: Date.now },
}, { timestamps: false });

badgeSchema.index({ userId: 1, badgeId: 1 }, { unique: true });

// Static badge definitions
const BADGES = {
  first_step: { id: 'first_step', name: 'First Step', icon: '🌱', description: 'Solve your first problem' },
  on_fire: { id: 'on_fire', name: 'On Fire', icon: '🔥', description: 'Maintain a 7-day streak' },
  hard_nut: { id: 'hard_nut', name: 'Hard Nut', icon: '💎', description: 'Solve your first hard problem' },
  centurion: { id: 'centurion', name: 'Centurion', icon: '💯', description: 'Solve 100 problems' },
  champion: { id: 'champion', name: 'Champion', icon: '🏆', description: 'Solve 500 problems' },
  maang_ready: { id: 'maang_ready', name: 'MAANG Ready', icon: '👑', description: 'Solve 1000 problems' },
  dp_destroyer: { id: 'dp_destroyer', name: 'DP Destroyer', icon: '🧠', description: 'Solve 50 DP problems' },
  tree_titan: { id: 'tree_titan', name: 'Tree Titan', icon: '🌳', description: 'Solve 50 tree problems' },
  graph_guru: { id: 'graph_guru', name: 'Graph Guru', icon: '📊', description: 'Solve 50 graph problems' },
  streak_warrior: { id: 'streak_warrior', name: 'Streak Warrior', icon: '⚡', description: 'Maintain a 30-day streak' },
  night_owl: { id: 'night_owl', name: 'Night Owl', icon: '🦉', description: 'Solve 10 problems after midnight' },
  speed_demon: { id: 'speed_demon', name: 'Speed Demon', icon: '⚡', description: 'Solve a hard problem in under 20 min' },
};

xpEventSchema.statics.BADGES = BADGES;
badgeSchema.statics.BADGES = BADGES;

// XP per event
const XP_VALUES = {
  easy_solved: 10,
  medium_solved: 25,
  hard_solved: 50,
  daily_goal_completed: 30,
  contest_participated: 40,
  revision_completed: 15,
  streak_7: 100,
  streak_30: 500,
  streak_100: 2000,
  onboarding_complete: 50,
};

xpEventSchema.statics.XP_VALUES = XP_VALUES;
badgeSchema.statics.XP_VALUES = XP_VALUES;

const XpEvent = mongoose.model('XpEvent', xpEventSchema);
const Badge = mongoose.model('Badge', badgeSchema);

module.exports = { XpEvent, Badge, BADGES, XP_VALUES };
