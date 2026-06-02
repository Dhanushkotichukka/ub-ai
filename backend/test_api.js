const axios = require('axios');
const cheerio = require('cheerio');

axios.get('https://auth.geeksforgeeks.org/user/sidd2512/practice/', { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 10000 })
.then(r => {
    const $ = cheerio.load(r.data);
    $('.problemNavbar_head_nav--text__UaGCx').each((i, el) => {
        console.log('Found:', $(el).text());
    });
    console.log('Length:', r.data.length);
})
.catch(e => console.log('error:', e.response ? e.response.status : e.message));
