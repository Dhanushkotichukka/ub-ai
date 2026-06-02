const axios = require('axios');

// ─── LeetCode (GraphQL API) ───────────────────────────────────────────────────
const fetchLeetCodeStats = async (username) => {
  if (!username) return null;
  try {
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
          userContestRanking { rating attendedContestsCount globalRanking }
        }
        userContestRankingHistory(username: $username) {
          attended rating
        }
      }
    `;

    const { data } = await axios.post(
      process.env.LEETCODE_GRAPHQL_URL || 'https://leetcode.com/graphql',
      { query, variables: { username } },
      {
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
          'User-Agent': 'Mozilla/5.0',
        },
        timeout: 10000,
      }
    );

    const user = data?.data?.matchedUser;
    if (!user) return null;

    const stats = user.submitStats?.acSubmissionNum || [];
    const getCount = (diff) => stats.find(s => s.difficulty === diff)?.count || 0;

    return {
      platform: 'leetcode',
      totalSolved: getCount('All'),
      easySolved: getCount('Easy'),
      mediumSolved: getCount('Medium'),
      hardSolved: getCount('Hard'),
      rating: Math.round(user.userContestRanking?.rating || 0),
      contestCount: user.userContestRanking?.attendedContestsCount || 0,
      globalRank: user.userContestRanking?.globalRanking,
      badges: user.badges?.map(b => b.name) || [],
      avatarUrl: user.profile?.userAvatar,
      profileUrl: `https://leetcode.com/u/${username}`,
    };
  } catch (err) {
    console.error(`[LeetCode] Failed to fetch stats for ${username}:`, err.message);
    return null;
  }
};

// ─── Codeforces (Official REST API) ──────────────────────────────────────────
const fetchCodeforcesStats = async (handle) => {
  if (!handle) return null;
  try {
    const [userRes, submissionRes] = await Promise.all([
      axios.get(`https://codeforces.com/api/user.info?handles=${handle}`, { timeout: 8000 }),
      axios.get(`https://codeforces.com/api/user.status?handle=${handle}&from=1&count=10000`, { timeout: 15000 }),
    ]);

    const user = userRes.data?.result?.[0];
    const submissions = submissionRes.data?.result || [];

    // Count unique accepted problems
    const acceptedProblems = new Set(
      submissions
        .filter(s => s.verdict === 'OK')
        .map(s => `${s.problem.contestId}-${s.problem.index}`)
    );

    return {
      platform: 'codeforces',
      totalSolved: acceptedProblems.size,
      rating: user?.rating || 0,
      rank: user?.rank || '',
      globalRank: user?.maxRank,
      contestCount: 0,
      avatarUrl: user?.avatar ? `https:${user.avatar}` : null,
      profileUrl: `https://codeforces.com/profile/${handle}`,
      badges: user?.rank ? [user.rank] : [],
    };
  } catch (err) {
    console.error(`[Codeforces] Failed to fetch stats for ${handle}:`, err.message);
    return null;
  }
};

// ─── GFG (Unofficial scraping via public API) ─────────────────────────────
const fetchGFGStats = async (username) => {
  if (!username) return null;
  try {
    // Using the unofficial GFG API endpoint
    const { data } = await axios.get(
      `https://geeks-for-geeks-stats-api.vercel.app/?raw=Y&userName=${username}`,
      { timeout: 10000 }
    );

    if (data?.status === 'error') return null;

    return {
      platform: 'gfg',
      totalSolved: data?.totalProblemsSolved || 0,
      easySolved: data?.School || 0,
      mediumSolved: (data?.Basic || 0) + (data?.Easy || 0) + (data?.Medium || 0),
      hardSolved: data?.Hard || 0,
      score: data?.userHandle?.score || 0,
      streak: data?.currentStreak || 0,
      rating: data?.userHandle?.score || 0,
      profileUrl: `https://www.geeksforgeeks.org/user/${username}`,
      badges: [],
    };
  } catch (err) {
    console.error(`[GFG] Failed to fetch stats for ${username}:`, err.message);
    return null;
  }
};

// ─── CodeChef (Limited public data) ──────────────────────────────────────────
const fetchCodeChefStats = async (username) => {
  if (!username) return null;
  try {
    // CodeChef doesn't have a clean public API — use codechef-api
    const { data } = await axios.get(
      `https://codechef-api.vercel.app/handle/${username}`,
      { timeout: 10000 }
    );

    if (!data?.success) return null;

    return {
      platform: 'codechef',
      totalSolved: data?.problem_solved_count || 0,
      rating: data?.currentRating || 0,
      rank: data?.highestRating ? `${data.highestRating} peak` : '',
      contestCount: data?.contest_participated_count || 0,
      globalRank: data?.globalRank,
      profileUrl: `https://www.codechef.com/users/${username}`,
      avatarUrl: data?.profile,
      badges: data?.stars ? [`${data.stars} ⭐`] : [],
    };
  } catch (err) {
    console.error(`[CodeChef] Failed to fetch stats for ${username}:`, err.message);
    return null;
  }
};

// ─── LeetCode POTD ────────────────────────────────────────────────────────────
const fetchLeetCodePOTD = async () => {
  try {
    const query = `
      query questionOfToday {
        activeDailyCodingChallengeQuestion {
          date
          link
          question {
            questionFrontendId
            title
            titleSlug
            difficulty
            topicTags { name }
          }
        }
      }
    `;
    const { data } = await axios.post(
      'https://leetcode.com/graphql',
      { query },
      { headers: { 'Content-Type': 'application/json', 'Referer': 'https://leetcode.com' }, timeout: 8000 }
    );

    const q = data?.data?.activeDailyCodingChallengeQuestion;
    if (!q) return null;

    return {
      platform: 'leetcode',
      date: q.date,
      title: q.question.title,
      slug: q.question.titleSlug,
      difficulty: q.question.difficulty.toLowerCase(),
      link: `https://leetcode.com${q.link}`,
      tags: q.question.topicTags.map(t => t.name),
    };
  } catch (err) {
    console.error('[LeetCode POTD] Fetch failed:', err.message);
    return null;
  }
};

// ─── GFG POTD ─────────────────────────────────────────────────────────────────
const fetchGFGPOTD = async () => {
  try {
    const { data } = await axios.get(
      'https://practiceapi.geeksforgeeks.org/api/vr/problems-of-day/problem/today/',
      { timeout: 8000 }
    );

    return {
      platform: 'gfg',
      title: data?.problem_name || 'Problem of the Day',
      difficulty: (data?.difficulty || 'medium').toLowerCase(),
      link: data?.problem_url || 'https://practice.geeksforgeeks.org/problem-of-the-day',
      date: new Date().toISOString().split('T')[0],
    };
  } catch (err) {
    console.error('[GFG POTD] Fetch failed:', err.message);
    return {
      platform: 'gfg',
      title: 'Problem of the Day',
      difficulty: 'medium',
      link: 'https://practice.geeksforgeeks.org/problem-of-the-day',
      date: new Date().toISOString().split('T')[0],
    };
  }
};

module.exports = {
  fetchLeetCodeStats,
  fetchCodeforcesStats,
  fetchGFGStats,
  fetchCodeChefStats,
  fetchLeetCodePOTD,
  fetchGFGPOTD,
};
