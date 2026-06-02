const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const platformsSchema = new mongoose.Schema({
  leetcode: { type: String, default: '' },
  gfg: { type: String, default: '' },
  codeforces: { type: String, default: '' },
  codechef: { type: String, default: '' },
  hackerrank: { type: String, default: '' },
  github: { type: String, default: '' },
}, { _id: false });

const settingsSchema = new mongoose.Schema({
  darkMode: { type: Boolean, default: true },
  accentColor: { type: String, default: '#6C63FF' },
  fontSize: { type: String, enum: ['small', 'medium', 'large'], default: 'medium' },
  notifications: {
    dailyReminder: { type: Boolean, default: true },
    dailyReminderTime: { type: String, default: '19:00' },
    contestReminders: { type: Boolean, default: true },
    revisionReminders: { type: Boolean, default: true },
    streakWarnings: { type: Boolean, default: true },
    extensionNotifications: { type: Boolean, default: true },
  },
  platformVisibility: {
    leetcode: { type: Boolean, default: true },
    gfg: { type: Boolean, default: true },
    codeforces: { type: Boolean, default: true },
    codechef: { type: Boolean, default: true },
    hackerrank: { type: Boolean, default: false },
    github: { type: Boolean, default: true },
  },
  platformOrder: {
    type: [String],
    default: ['leetcode', 'gfg', 'codeforces', 'codechef', 'hackerrank', 'github'],
  },
}, { _id: false });

const userSchema = new mongoose.Schema({
  // Auth
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, select: false },
  googleId: { type: String, sparse: true, unique: true },
  isEmailVerified: { type: Boolean, default: false },
  emailOtp: { type: String, select: false },
  emailOtpExpiry: { type: Date, select: false },

  // Profile
  name: { type: String, required: true, trim: true },
  profilePic: { type: String, default: '' },
  rollNumber: { type: String, default: '' },
  branch: {
    type: String,
    enum: ['CSE', 'IT', 'AIML', 'ECE', 'EEE', 'MECH', 'CIVIL', 'OTHER', ''],
    default: '',
  },
  year: { type: Number, min: 1, max: 5 },
  phone: { type: String, default: '' },
  college: { type: String, default: '' },
  graduationYear: { type: Number },
  dreamCompany: { type: String, default: '' },
  cgpa: { type: Number, min: 0, max: 10 },
  preferredLanguage: {
    type: String,
    enum: ['Java', 'Python', 'C++', 'JavaScript', 'C', 'Go', 'Rust', ''],
    default: '',
  },
  appPurpose: {
    type: String,
    enum: ['study_dsa', 'placement', 'competitive', 'job_switch', 'college', ''],
    default: '',
  },

  // Platforms
  platforms: { type: platformsSchema, default: () => ({}) },

  // Gamification
  xp: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  streak: { type: Number, default: 0 },
  lastActiveDate: { type: Date },
  longestStreak: { type: Number, default: 0 },
  badges: [{ type: String }],

  // Onboarding
  onboardingComplete: { type: Boolean, default: false },
  onboardingStep: { type: Number, default: 0 },

  // Settings
  settings: { type: settingsSchema, default: () => ({}) },

  // FCM
  fcmToken: { type: String, default: '' },

  // Chrome Extension
  extensionLinked: { type: Boolean, default: false },

}, { timestamps: true });

// ─── Indexes ──────────────────────────────────────────────────────
userSchema.index({ email: 1 });
userSchema.index({ googleId: 1 });

// ─── Pre-save: Hash password ──────────────────────────────────────
userSchema.pre('save', async function () {
  if (!this.isModified('password') || !this.password) return;
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
});

// ─── Instance method: Compare password ───────────────────────────
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// ─── Instance method: Calculate level from XP ─────────────────────
userSchema.methods.getLevelFromXP = function () {
  const thresholds = [0, 200, 500, 1000, 2000, 3500, 5500, 8000, 12000, 18000, 25000, 35000];
  const names = ['Beginner','Novice','Learner','Apprentice','Intermediate','Skilled','Proficient','Advanced','Expert','Master','Champion','Legend'];
  let level = 1;
  for (let i = thresholds.length - 1; i >= 0; i--) {
    if (this.xp >= thresholds[i]) { level = i + 1; break; }
  }
  return { level, name: names[level - 1], nextThreshold: thresholds[level] || null };
};

// ─── Virtual: Full platform URLs ──────────────────────────────────
userSchema.virtual('platformUrls').get(function () {
  const p = this.platforms;
  return {
    leetcode: p?.leetcode ? `https://leetcode.com/u/${p.leetcode}` : null,
    gfg: p?.gfg ? `https://www.geeksforgeeks.org/user/${p.gfg}` : null,
    codeforces: p?.codeforces ? `https://codeforces.com/profile/${p.codeforces}` : null,
    codechef: p?.codechef ? `https://www.codechef.com/users/${p.codechef}` : null,
    hackerrank: p?.hackerrank ? `https://www.hackerrank.com/${p.hackerrank}` : null,
    github: p?.github ? `https://github.com/${p.github}` : null,
  };
});

module.exports = mongoose.model('User', userSchema);
