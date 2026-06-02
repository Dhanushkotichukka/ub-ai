const mongoose = require('mongoose');

const topicTrackerSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
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
  easySolved: { type: Number, default: 0 },
  mediumSolved: { type: Number, default: 0 },
  hardSolved: { type: Number, default: 0 },
  totalSolved: { type: Number, default: 0 },
  target: { type: Number, default: 30 },
  // Mastery: 0=Not Started, 1=Beginner, 2=Basic, 3=Intermediate, 4=Advanced, 5=Master
  mastery: { type: Number, default: 0, min: 0, max: 5 },
  lastPracticed: { type: Date },
  status: {
    type: String,
    enum: ['not_started', 'active', 'mastered', 'needs_practice'],
    default: 'not_started',
  },
  // AI-generated recommendations
  recommendedProblems: [{
    name: String,
    difficulty: String,
    link: String,
    platform: String,
  }],
}, { timestamps: true });

topicTrackerSchema.index({ userId: 1, topic: 1 }, { unique: true });

// Calculate mastery level from solved counts
topicTrackerSchema.methods.calculateMastery = function () {
  const total = this.totalSolved;
  const hardWeight = this.hardSolved * 3;
  const medWeight = this.mediumSolved * 2;
  const score = total + hardWeight + medWeight;
  if (score === 0) return 0;
  if (score < 10) return 1;
  if (score < 30) return 2;
  if (score < 70) return 3;
  if (score < 150) return 4;
  return 5;
};

module.exports = mongoose.model('TopicTracker', topicTrackerSchema);
