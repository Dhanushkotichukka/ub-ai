const axios = require('axios');

const API = 'http://localhost:5000/api/v1';
let token = '';

const delay = ms => new Promise(res => setTimeout(res, ms));

async function run() {
  try {
    console.log('1. Register / Login');
    let res = await axios.post(`${API}/auth/register`, {
      name: 'Test User',
      email: `test${Date.now()}@example.com`,
      password: 'password123'
    });
    token = res.data.accessToken;
    axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
    console.log('✅ Auth successful');

    console.log('2. Onboarding');
    res = await axios.put(`${API}/user/onboarding`, {
      level: 'beginner',
      dreamCompany: 'Google',
      preferredLanguage: 'C++',
      avatar: '🦉'
    });
    console.log('✅ Onboarding successful');

    console.log('3. Add Problem (Daily Tracker)');
    res = await axios.post(`${API}/logs`, {
      problemName: 'Two Sum',
      platform: 'LeetCode',
      link: 'https://leetcode.com/problems/two-sum/',
      difficulty: 'easy',
      topic: 'Arrays',
      timeTaken: 15,
      notes: 'Used a hash map'
    });
    const logId = res.data.log._id;
    console.log('✅ Problem added');

    console.log('4. Verify Topic Tracker');
    res = await axios.get(`${API}/topics/Arrays`);
    console.log('✅ Topic tracker fetched');

    console.log('5. Generate AI Plan');
    res = await axios.post(`${API}/plan/auto-generate`, {
      goal: 'Master Arrays in 2 days',
      durationDays: 2
    });
    console.log('✅ AI Plan generated');

    console.log('6. Create Note');
    res = await axios.post(`${API}/notes`, {
      title: 'Two Sum Concept',
      content: 'Store complements in hash map.',
      folder: 'Arrays',
      tags: ['arrays']
    });
    console.log('✅ Note created');

    console.log('7. Open AI Coach (Chat)');
    res = await axios.get(`${API}/ai/chat`);
    res = await axios.post(`${API}/ai/chat`, {
      message: 'Explain Two Sum'
    });
    console.log('✅ AI Coach replied');

    console.log('8. Generate Weekly Report');
    res = await axios.post(`${API}/reports/generate`);
    console.log('✅ Weekly Report generated');

    console.log('9. Spaced Repetition (Fetch Due Revisions)');
    res = await axios.get(`${API}/revision/due`);
    console.log(`✅ Due revisions fetched: ${res.data.revisions.length}`);

    console.log('10. Open Analytics');
    res = await axios.get(`${API}/analytics/overview`);
    console.log('✅ Analytics overview fetched');

    console.log('\n🎉 ALL TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('❌ ERROR:', err.response ? err.response.data : err.message);
  }
}

run();
