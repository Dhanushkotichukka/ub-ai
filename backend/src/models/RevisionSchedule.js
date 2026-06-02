const mongoose = require('mongoose');

const revisionScheduleSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  logId: { type: mongoose.Schema.Types.ObjectId, ref: 'DailyLog' },
  problemName: { type: String, required: true },
  topic: { type: String, required: true },
  platform: { type: String, required: true },
  link: { type: String, default: '' },
  difficulty: { type: String, enum: ['easy', 'medium', 'hard'] },

  // Spaced Repetition (Ebbinghaus Forgetting Curve)
  nextRevisionDate: { type: Date, required: true },
  revisionCount: { type: Number, default: 0 },
  intervalDays: { type: Number, default: 1 }, // 1, 3, 7, 14, 30, 60, 90
  lastRevised: { type: Date },
  isCompleted: { type: Boolean, default: false }, // mastered = no more revisions
  confidence: { type: Number, min: 1, max: 5, default: 3 },
}, { timestamps: true });

// Standard spaced repetition intervals (days)
revisionScheduleSchema.statics.INTERVALS = [1, 3, 7, 14, 30, 60, 90];

revisionScheduleSchema.methods.markRevised = function (newConfidence) {
  const intervals = [1, 3, 7, 14, 30, 60, 90];
  this.revisionCount += 1;
  this.confidence = newConfidence || this.confidence;
  this.lastRevised = new Date();

  if (this.revisionCount >= intervals.length || newConfidence === 5) {
    this.isCompleted = true;
  } else {
    this.intervalDays = intervals[this.revisionCount];
    const next = new Date();
    next.setDate(next.getDate() + this.intervalDays);
    this.nextRevisionDate = next;
  }
};

revisionScheduleSchema.index({ userId: 1, nextRevisionDate: 1 });
revisionScheduleSchema.index({ userId: 1, isCompleted: 1 });

module.exports = mongoose.model('RevisionSchedule', revisionScheduleSchema);
