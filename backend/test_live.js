const axios = require('axios');

async function testLive() {
  try {
    console.log('Sending request to Render...');
    const res = await axios.post('https://ub-ai.onrender.com/api/v1/auth/register', {
      name: 'Render Test',
      email: `render_test_${Date.now()}@example.com`,
      password: 'password123'
    });
    console.log('Success:', res.data);
  } catch (err) {
    if (err.response) {
      console.log('Error Response:', err.response.status, err.response.data);
    } else {
      console.log('Network Error:', err.message);
    }
  }
}
testLive();
