const jwt = require('jsonwebtoken');
const User = require('../models/User');

const protect = async (req, res, next) => {
  try {
    let token;
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({ success: false, message: 'Not authenticated. Please log in.' });
    }

    // Verify token
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ success: false, message: 'Token expired. Please log in again.', code: 'TOKEN_EXPIRED' });
      }
      return res.status(401).json({ success: false, message: 'Invalid token.' });
    }

    // Fetch user
    const user = await User.findById(decoded.id).select('-password -emailOtp -emailOtpExpiry');
    if (!user) {
      return res.status(401).json({ success: false, message: 'User no longer exists.' });
    }

    req.user = user;
    next();
  } catch (error) {
    next(error);
  }
};

// Generate access + refresh tokens
const generateTokens = (userId) => {
  const access = jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
  const refresh = jwt.sign({ id: userId }, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '90d',
  });
  return { access, refresh };
};

module.exports = { protect, generateTokens };
