require('dotenv').config();
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { startCronJobs } = require('./src/services/cronService');

const PORT = process.env.PORT || 5000;

// Connect to MongoDB
connectDB().then(() => {
  // Start HTTP server
  const server = app.listen(PORT, () => {
    console.log(`\n🦉 OwlCoder AI Backend running on port ${PORT}`);
    console.log(`   Environment : ${process.env.NODE_ENV}`);
    console.log(`   API Base    : http://localhost:${PORT}/api/v1\n`);
  });

  // Start cron jobs
  startCronJobs();

  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    server.close(() => process.exit(0));
  });
}).catch((err) => {
  console.error('Failed to connect to MongoDB:', err.message);
  process.exit(1);
});
