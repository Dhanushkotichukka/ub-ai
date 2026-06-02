const mongoose = require('mongoose');

const aiReportSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  weekStartDate: { type: Date, required: true },
  weekEndDate: { type: Date, required: true },
  strongTopics: [{ type: String }],
  weakTopics: [{ type: String }],
  consistencyScore: { type: Number, default: 0 },
  interviewReadinessScore: { type: Number, default: 0 },
  recommendedNextActions: [{ type: String }],
  summary: { type: String },
}, { timestamps: true });

aiReportSchema.index({ userId: 1, weekStartDate: -1 });

module.exports = mongoose.model('AiReport', aiReportSchema);
