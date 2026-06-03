const express = require('express');
const router = express.Router();
const { OAuth2Client } = require('google-auth-library');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const User = require('../models/User');
const { generateTokens } = require('../middleware/auth');
const { awardXP } = require('../services/gamificationService');
const sgMail = require('@sendgrid/mail');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const sendEmail = async (to, subject, html) => {
  if (!process.env.SENDGRID_API_KEY) {
    throw new Error('SendGrid API Key is missing in environment variables');
  }
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  
  const msg = {
    to,
    from: process.env.EMAIL_FROM || 'testusercreatoros@gmail.com',
    subject,
    html,
  };
  
  await sgMail.send(msg);
};

// ─── Helper: send token response ─────────────────────────────────
const sendTokenResponse = (user, statusCode, res) => {
  const { access, refresh } = generateTokens(user._id);
  const userObj = user.toObject();
  delete userObj.password;
  delete userObj.emailOtp;
  delete userObj.emailOtpExpiry;

  res.status(statusCode).json({
    success: true,
    accessToken: access,
    refreshToken: refresh,
    user: userObj,
  });
};

// ─── POST /auth/google ────────────────────────────────────────────
// Google OAuth — verify ID token from Flutter Google Sign-In
router.post('/google', async (req, res, next) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ success: false, message: 'ID token required' });

    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;

    let user = await User.findOne({ $or: [{ googleId }, { email }] });

    if (!user) {
      user = await User.create({
        googleId,
        email,
        name,
        profilePic: picture,
        isEmailVerified: true,
      });
    } else if (!user.googleId) {
      user.googleId = googleId;
      user.isEmailVerified = true;
      if (!user.profilePic) user.profilePic = picture;
      await user.save();
    }

    sendTokenResponse(user, 200, res);
  } catch (err) {
    next(err);
  }
});

// ─── POST /auth/register ──────────────────────────────────────────
router.post('/register', async (req, res, next) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password || !name) {
      return res.status(400).json({ success: false, message: 'Name, email, and password are required' });
    }
    if (password.length < 8) {
      return res.status(400).json({ success: false, message: 'Password must be at least 8 characters' });
    }

    const exists = await User.findOne({ email });
    if (exists) return res.status(409).json({ success: false, message: 'Email already registered' });

    const otp = crypto.randomInt(100000, 999999).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    const user = await User.create({ email, password, name, emailOtp: otp, emailOtpExpiry: otpExpiry });

    // Send OTP via SendGrid
    try {
      await sendEmail(
        user.email,
        'Verify your OwlCoder account',
        `
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; background-color: #1a1a2e; color: #fff; border-radius: 12px;">
          <h1 style="color: #4e44ce;">Welcome to OwlCoder AI!</h1>
          <p style="font-size: 16px; margin-bottom: 30px;">Use the OTP below to verify your email address.</p>
          <div style="background-color: rgba(255, 255, 255, 0.1); padding: 20px; border-radius: 8px; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #fff;">
            ${otp}
          </div>
          <p style="font-size: 14px; margin-top: 30px; color: #aaa;">This code expires in 10 minutes.</p>
        </div>
        `
      );
    } catch (mailErr) {
      console.error('Email send failed:', mailErr.message);
      // Delete the unverified user since we couldn't send the OTP
      await User.deleteOne({ _id: user._id });
      return res.status(500).json({ success: false, message: 'Failed to send verification email: ' + mailErr.message });
    }

    res.status(201).json({ success: true, message: 'Account created. OTP sent to email.', email: user.email });
  } catch (err) {
    next(err);
  }
});

// ─── POST /auth/login ─────────────────────────────────────────────
router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password required' });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user || !user.password) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

    if (!user.isEmailVerified) {
      return res.status(403).json({ success: false, message: 'Please verify your email first', requiresVerification: true, email: user.email });
    }

    sendTokenResponse(user, 200, res);
  } catch (err) {
    next(err);
  }
});

// ─── POST /auth/verify-otp ────────────────────────────────────────
router.post('/verify-otp', async (req, res, next) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email }).select('+emailOtp +emailOtpExpiry');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (user.emailOtp !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });
    if (user.emailOtpExpiry < Date.now()) return res.status(400).json({ success: false, message: 'OTP expired' });

    user.isEmailVerified = true;
    user.emailOtp = undefined;
    user.emailOtpExpiry = undefined;
    await user.save();

    // Send Welcome Email
    try {
      await sendEmail(
        email,
        '🚀 Welcome to OwlCoder AI!',
        `
          <div style="font-family: Inter, sans-serif; max-width: 500px; margin: 0 auto; color: #333;">
            <h2 style="color: #6C63FF;">You are all set! 🎉</h2>
            <p>Welcome to <strong>OwlCoder AI</strong>, ${user.name || 'Developer'}!</p>
            <p>Your email has been successfully verified. You can now log in and start tracking your DSA journey across all major platforms, get personalized AI coaching, and level up your skills.</p>
            <p>Happy Coding! 🦉</p>
          </div>
        `
      );
    } catch (mailErr) {
      console.error('Welcome email failed:', mailErr.message);
    }

    res.json({ success: true, message: 'Email verified successfully' });
  } catch (err) {
    next(err);
  }
});

// ─── POST /auth/forgot-password ───────────────────────────────────
router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'No account with that email' });

    const otp = crypto.randomInt(100000, 999999).toString();
    user.emailOtp = otp;
    user.emailOtpExpiry = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    try {
      await sendEmail(
        email,
        '🔐 Reset your OwlCoder AI password',
        `
          <div style="font-family: Inter, sans-serif; max-width: 500px; margin: 0 auto;">
            <h2 style="color: #6C63FF;">Password Reset 🔐</h2>
            <p>Your OTP to reset your password:</p>
            <div style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #6C63FF; padding: 20px; background: #f0f0f8; border-radius: 12px; text-align: center;">${otp}</div>
            <p style="color: #666;">Expires in 10 minutes. If you didn't request this, ignore this email.</p>
          </div>
        `
      );
    } catch (mailErr) {
      console.error('Reset email failed:', mailErr.message);
      return res.status(500).json({ success: false, message: 'Failed to send reset email. Please try again later.' });
    }

    res.json({ success: true, message: 'OTP sent to your email' });
  } catch (err) {
    next(err);
  }
});

// ─── POST /auth/reset-password ────────────────────────────────────
router.post('/reset-password', async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!newPassword || newPassword.length < 8) {
      return res.status(400).json({ success: false, message: 'Password must be at least 8 characters' });
    }

    const user = await User.findOne({ email }).select('+emailOtp +emailOtpExpiry +password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (user.emailOtp !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });
    if (user.emailOtpExpiry < Date.now()) return res.status(400).json({ success: false, message: 'OTP expired' });

    user.password = newPassword;
    user.emailOtp = undefined;
    user.emailOtpExpiry = undefined;
    await user.save();

    res.json({ success: true, message: 'Password reset successful' });
  } catch (err) {
    next(err);
  }
});

// ─── GET /auth/me ─────────────────────────────────────────────────
const { protect } = require('../middleware/auth');
router.get('/me', protect, async (req, res) => {
  res.json({ success: true, user: req.user });
});

// ─── POST /auth/refresh ───────────────────────────────────────────
const jwt = require('jsonwebtoken');
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh token required' });

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET);
    const user = await User.findById(decoded.id);
    if (!user) return res.status(401).json({ success: false, message: 'User not found' });

    const { access } = generateTokens(user._id);
    res.json({ success: true, accessToken: access });
  } catch (err) {
    res.status(401).json({ success: false, message: 'Invalid or expired refresh token' });
  }
});

module.exports = router;
