const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

// Route imports
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const platformRoutes = require('./routes/platform');
const logRoutes = require('./routes/logs');
const topicRoutes = require('./routes/topics');
const planRoutes = require('./routes/plan');
const notesRoutes = require('./routes/notes');
const revisionRoutes = require('./routes/revision');
const contestRoutes = require('./routes/contests');
const analyticsRoutes = require('./routes/analytics');
const aiRoutes = require('./routes/ai');
const gamificationRoutes = require('./routes/gamification');
const placementRoutes = require('./routes/placement');
const syncRoutes = require('./routes/sync');
const reportsRoutes = require('./routes/reports');

const errorHandler = require('./middleware/errorHandler');

const app = express();

// ─── Security ────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// ─── CORS ────────────────────────────────────────────────────────
const allowedOrigins = [
  process.env.CLIENT_URL || 'http://localhost:3000',
  process.env.FLUTTER_WEB_URL || 'http://localhost:54321',
  'http://localhost:5000',
  'chrome-extension://',
];
app.use(cors({
  origin: (origin, callback) => {
    if (
      !origin || 
      origin.startsWith('http://localhost:') || 
      allowedOrigins.some(o => origin.startsWith(o))
    ) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
}));

// ─── Rate Limiting ────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use('/api/', limiter);

// ─── Body Parsing ─────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ─── Logging ──────────────────────────────────────────────────────
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ─── Health Check ─────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'OwlCoder AI Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// ─── API Routes ───────────────────────────────────────────────────
const API = '/api/v1';
app.use(`${API}/auth`, authRoutes);
app.use(`${API}/user`, userRoutes);
app.use(`${API}/platforms`, platformRoutes);
app.use(`${API}/logs`, logRoutes);
app.use(`${API}/topics`, topicRoutes);
app.use(`${API}/plan`, planRoutes);
app.use(`${API}/notes`, notesRoutes);
app.use(`${API}/revision`, revisionRoutes);
app.use(`${API}/contests`, contestRoutes);
app.use(`${API}/analytics`, analyticsRoutes);
app.use(`${API}/ai`, aiRoutes);
app.use(`${API}/gamification`, gamificationRoutes);
app.use(`${API}/placement`, placementRoutes);
app.use(`${API}/sync`, syncRoutes);
app.use(`${API}/reports`, reportsRoutes);

// ─── 404 Handler ──────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route ${req.originalUrl} not found` });
});

// ─── Global Error Handler ─────────────────────────────────────────
app.use(errorHandler);

module.exports = app;
