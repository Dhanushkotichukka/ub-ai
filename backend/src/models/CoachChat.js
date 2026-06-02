const mongoose = require('mongoose');

const coachChatSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  messages: [{
    role: { type: String, enum: ['user', 'assistant'], required: true },
    content: { type: String, required: true },
    timestamp: { type: Date, default: Date.now }
  }],
}, { timestamps: true });

module.exports = mongoose.model('CoachChat', coachChatSchema);
