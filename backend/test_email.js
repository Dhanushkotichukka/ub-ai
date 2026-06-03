require('dotenv').config();
const nodemailer = require('nodemailer');

async function testEmail() {
  const start = Date.now();
  const transporter = nodemailer.createTransport({
    host: process.env.EMAIL_HOST,
    port: parseInt(process.env.EMAIL_PORT),
    secure: false,
    auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
  });

  try {
    console.log('Sending email...');
    await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      to: 'test@example.com',
      subject: 'Test',
      text: 'Test body'
    });
    console.log('Email sent in', Date.now() - start, 'ms');
  } catch (err) {
    console.error('Error sending:', err.message);
  }
}

testEmail();
