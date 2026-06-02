const axios = require('axios');
axios.post('https://leetcode.com/graphql', { query: 'query { matchedUser(username: "23mh1a1252") { username } }' }, { headers: { 'Content-Type': 'application/json' } }).then(r => console.log('LeetCode:', r.data)).catch(e => console.log('LC Error', e.message));
axios.get('https://geeks-for-geeks-stats-api.vercel.app/?raw=Y&userName=chukkadhabzy3').then(r => console.log('GFG:', r.data.info)).catch(e => console.log('GFG Error'));
axios.get('https://codeforces.com/api/user.info?handles=dhanushkoti_chukka').then(r => console.log('CF:', r.data.status)).catch(e => console.log('CF Error'));
