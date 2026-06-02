const mongoose = require('mongoose');

const dailyLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  date: { type: Date, required: true, default: () => new Date().setHours(0, 0, 0, 0) },
  problemName: { type: String, required: true, trim: true },
  topic: {
    type: String,
    required: true,
    enum: [
      'Arrays', 'Strings', 'Linked List', 'Stack', 'Queue', 'Trees', 'Binary Trees',
      'Binary Search Trees', 'Graphs', 'Dynamic Programming', 'Greedy', 'Backtracking',
      'Binary Search', 'Two Pointers', 'Sliding Window', 'Hashing', 'Heap/Priority Queue',
      'Tries', 'Segment Trees', 'Fenwick Trees', 'Math', 'Bit Manipulation',
      'Recursion', 'Divide and Conquer', 'Design', 'Other',
    ],
  },
  platform: {
    type: String,
    required: true,
    enum: ['LeetCode', 'GFG', 'Codeforces', 'CodeChef', 'HackerRank', 'AtCoder', 'Other'],
  },
  difficulty: { type: String, enum: ['easy', 'medium', 'hard'], required: true },
  timeTaken: { type: Number, default: 0 }, // minutes
  link: { type: String, default: '' },
  notes: { type: String, default: '' },
  approach: { type: String, default: '' },
  needsRevision: { type: Boolean, default: false },
  confidence: { type: Number, min: 1, max: 5, default: 3 },
  isBookmarked: { type: Boolean, default: false },
  isFavorite: { type: Boolean, default: false },
  // Source tracking
  source: { type: String, enum: ['manual', 'extension', 'import'], default: 'manual' },
  // XP awarded
  xpAwarded: { type: Number, default: 0 },
}, { timestamps: true });

// Compound index for efficient date-based queries
dailyLogSchema.index({ userId: 1, date: -1 });
dailyLogSchema.index({ userId: 1, topic: 1 });
dailyLogSchema.index({ userId: 1, needsRevision: 1 });
dailyLogSchema.index({ userId: 1, platform: 1 });

module.exports = mongoose.model('DailyLog', dailyLogSchema);
