const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: { type: String, required: true, trim: true, default: 'Untitled Note' },
  content: { type: mongoose.Schema.Types.Mixed, default: null }, // Quill delta JSON
  contentText: { type: String, default: '' }, // Plain text for search
  folder: { type: String, default: 'All Notes', trim: true },
  folderPath: { type: String, default: 'All Notes' }, // Nested: "DSA/Arrays"
  tags: [{ type: String, trim: true, lowercase: true }],
  color: {
    type: String,
    enum: ['default', 'red', 'orange', 'yellow', 'green', 'blue', 'purple'],
    default: 'default',
  },
  isPinned: { type: Boolean, default: false },
  hasImages: { type: Boolean, default: false },
  hasCode: { type: Boolean, default: false },
  isArchived: { type: Boolean, default: false },
  // AI generated flashcards from this note
  flashcards: [{
    question: String,
    answer: String,
    _id: false,
  }],
}, { timestamps: true });

noteSchema.index({ userId: 1, folder: 1 });
noteSchema.index({ userId: 1, tags: 1 });
noteSchema.index({ userId: 1, isPinned: -1, updatedAt: -1 });
// Full-text search on title + contentText
noteSchema.index({ title: 'text', contentText: 'text', tags: 'text' });

module.exports = mongoose.model('Note', noteSchema);
