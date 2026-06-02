const axios = require('axios');

axios.get('https://www.hackerrank.com/rest/hackers/shashank/scores_elo', { headers: { 'User-Agent': 'Mozilla/5.0' }})
.then(r => console.log('Scores:', JSON.stringify(r.data, null, 2)))
.catch(e => console.error(e.message));
