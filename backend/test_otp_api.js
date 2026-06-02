const axios = require('axios');
const mongoose = require('mongoose');

const baseUrl = 'http://localhost:5000/api/v1';

async function runTest() {
  const email = `test_${Date.now()}@example.com`;
  const password = 'password123';
  
  try {
    console.log('1. Registering user...');
    const regRes = await axios.post(`${baseUrl}/auth/register`, {
      name: 'Integration Test User',
      email,
      password
    });
    console.log('Registration response:', regRes.data);

    console.log('\n2. Attempting to log in before verification (should fail)...');
    try {
      await axios.post(`${baseUrl}/auth/login`, { email, password });
      console.log('Login Succeeded - THIS IS A FAILURE OF THE TEST!');
    } catch (err) {
      console.log('Login failed as expected:', err.response.data);
    }

    console.log('\n3. Connecting to DB to fetch OTP...');
    await mongoose.connect('mongodb+srv://ubmini:UBmini2226@ubmini.gqya3xx.mongodb.net/owlcoder?appName=ubmini');
    const user = await mongoose.model('User', new mongoose.Schema({ emailOtp: String }, { strict: false })).findOne({ email });
    const otp = user.emailOtp;
    console.log('Fetched OTP from DB:', otp);

    console.log('\n4. Verifying OTP...');
    const verifyRes = await axios.post(`${baseUrl}/auth/verify-otp`, { email, otp });
    console.log('Verify response:', verifyRes.data);

    console.log('\n5. Attempting to log in after verification...');
    const loginRes = await axios.post(`${baseUrl}/auth/login`, { email, password });
    console.log('Login response after verification:', { success: loginRes.data.success, accessToken: loginRes.data.accessToken ? 'PRESENT' : 'MISSING' });

    console.log('\n--- SUCCESS! ALL FLOWS WORKED ---');
  } catch (e) {
    console.error('Test Failed:', e.response ? e.response.data : e.message);
  } finally {
    await mongoose.disconnect();
  }
}

runTest();
