const axios = require('axios');
const cheerio = require('cheerio');

async function getCodeChefStats(username) {
    const profileUrl = `https://www.codechef.com/users/${username}`;
    try {
        const response = await axios.get(profileUrl, {
            headers: { 'User-Agent': 'Mozilla/5.0' },
            timeout: 10000
        });

        const $ = cheerio.load(response.data);
        const ratingText = $(".rating-number").first().text().trim();
        const rating = ratingText ? parseInt(ratingText) : 0;

        const solvedText = $(".rating-data-section.problems-solved h3").eq(3).text();
        const totalSolved = solvedText ? parseInt(solvedText.match(/\d+/)?.[0] || '0') : 0;

        const maxRatingText = $(".rating-header .rating-data-section small").text().trim();
        const maxRatingMatch = maxRatingText.match(/Highest Rating\s+(\d+)/i);
        const highestRating = maxRatingMatch ? parseInt(maxRatingMatch[1]) : rating;

        console.log({ username, rating, highestRating, totalSolved });
    } catch (error) {
        console.error('Error fetching CodeChef data:', error.message);
    }
}
getCodeChefStats('dhanushkoti');
