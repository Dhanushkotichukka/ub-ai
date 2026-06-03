const mongoose = require('mongoose');

const flashcardSchema = new mongoose.Schema({
  question: String,
  answer: String,
  lastReviewed: Date,
  confidence: { type: Number, default: 0 }, // 0-3 spaced rep score
}, { _id: false });

const quizQuestionSchema = new mongoose.Schema({
  type: { type: String, enum: ['mcq', 'truefalse', 'fillblank', 'short'], default: 'mcq' },
  question: String,
  options: [String],       // for MCQ
  answer: String,
  explanation: String,
}, { _id: false });

const aiChatSchema = new mongoose.Schema({
  role: { type: String, enum: ['user', 'assistant'] },
  content: String,
  createdAt: { type: Date, default: Date.now },
}, { _id: false });

const noteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: { type: String, required: true, trim: true, default: 'Untitled Note' },
  content: { type: mongoose.Schema.Types.Mixed, default: null }, // Quill delta JSON
  contentText: { type: String, default: '' }, // Plain text for search
  folder: { type: String, default: 'General', trim: true },
  folderPath: { type: String, default: 'General' },
  collection: { type: String, default: 'General', trim: true }, // DSA, Flutter, Linux, etc.
  tags: [{ type: String, trim: true, lowercase: true }],
  color: {
    type: String,
    enum: ['default', 'red', 'orange', 'yellow', 'green', 'blue', 'purple', 'pink', 'teal'],
    default: 'default',
  },
  noteType: {
    type: String,
    enum: ['quick', 'daily', 'dsa', 'meeting', 'snippet', 'study'],
    default: 'quick',
  },
  isPinned: { type: Boolean, default: false },
  isFavorited: { type: Boolean, default: false },
  hasImages: { type: Boolean, default: false },
  hasCode: { type: Boolean, default: false },
  isArchived: { type: Boolean, default: false },
  dailyDate: { type: String, default: null }, // "YYYY-MM-DD" for journal notes

  // AI generated content
  aiSummary: { type: String, default: null }, // 1-line AI summary for card preview
  aiRoadmap: { type: String, default: null }, // study roadmap markdown
  aiMindMap: { type: String, default: null }, // mind map text repr

  // Flashcards
  flashcards: [flashcardSchema],

  // Quiz
  quiz: [quizQuestionSchema],

  // AI Chat history per note
  aiChatHistory: [aiChatSchema],

  // Spaced Repetition
  revisionSchedule: [{
    reviewDate: String,   // "YYYY-MM-DD"
    interval: Number,     // days
    reviewed: { type: Boolean, default: false },
    _id: false,
  }],
  nextReviewDate: { type: String, default: null },
  lastReviewedAt: { type: Date, default: null },
  reviewCount: { type: Number, default: 0 },

}, { timestamps: true });

noteSchema.index({ userId: 1, folder: 1 });
noteSchema.index({ userId: 1, tags: 1 });
noteSchema.index({ userId: 1, noteType: 1 });
noteSchema.index({ userId: 1, collection: 1 });
noteSchema.index({ userId: 1, dailyDate: 1 });
noteSchema.index({ userId: 1, isPinned: -1, updatedAt: -1 });
noteSchema.index({ userId: 1, nextReviewDate: 1 });
noteSchema.index({ title: 'text', contentText: 'text', tags: 'text' });

module.exports = mongoose.model('Note', noteSchema);
