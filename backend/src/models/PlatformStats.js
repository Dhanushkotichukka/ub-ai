const mongoose = require('mongoose');

const platformStatsSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  platform: {
    type: String,
    required: true,
    enum: ['leetcode', 'gfg', 'codeforces', 'codechef', 'hackerrank'],
  },
  totalSolved: { type: Number, default: 0 },
  easySolved: { type: Number, default: 0 },
  mediumSolved: { type: Number, default: 0 },
  hardSolved: { type: Number, default: 0 },
  rating: { type: Number, default: 0 },
  rank: { type: String, default: '' },
  badges: [{ type: String }],
  contestCount: { type: Number, default: 0 },
  streak: { type: Number, default: 0 },
  score: { type: Number, default: 0 }, // GFG score
  globalRank: { type: Number },
  countryRank: { type: Number },
  // LeetCode specific
  acceptanceRate: { type: Number },
  contributionPoints: { type: Number },
  // Extra metadata
  profileUrl: { type: String },
  avatarUrl: { type: String },
  lastSynced: { type: Date, default: Date.now },
}, { timestamps: true });

platformStatsSchema.index({ userId: 1, platform: 1 }, { unique: true });

module.exports = mongoose.model('PlatformStats', platformStatsSchema);
