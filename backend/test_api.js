const axios = require('axios');
const query = `
      query getUserProfile($username: String!) {
        matchedUser(username: $username) {
          username
          profile { userAvatar ranking }
          submitStats: submitStatsGlobal {
            acSubmissionNum {
              difficulty
              count
            }
          }
          badges { name icon }
        }
        userContestRanking(username: $username) { rating attendedContestsCount globalRanking }
      }
    `;
axios.post('https://leetcode.com/graphql', { query, variables: { username: '23mh1a1252' } })
.then(r => console.log('LC:', JSON.stringify(r.data, null, 2)))
.catch(e => console.log(e.response ? e.response.data : e.message));
