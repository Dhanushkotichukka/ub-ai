const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

router.use(protect);

// Placement company-wise question data (embedded — extend with DB later)
const COMPANY_QUESTIONS = require('../data/companyQuestions');

// ─── GET /placement/companies ─────────────────────────────────────
router.get('/companies', async (req, res) => {
  const companies = Object.keys(COMPANY_QUESTIONS).map(c => ({
    name: c,
    count: COMPANY_QUESTIONS[c].length,
    logo: getCompanyLogo(c),
  }));
  res.json({ success: true, companies });
});

// ─── GET /placement/:company ──────────────────────────────────────
router.get('/:company', async (req, res) => {
  const company = req.params.company;
  const questions = COMPANY_QUESTIONS[company];
  if (!questions) return res.status(404).json({ success: false, message: 'Company not found' });
  res.json({ success: true, company, questions, total: questions.length });
});

const getCompanyLogo = (company) => {
  const logos = {
    Google: '🔵', Amazon: '🟠', Microsoft: '🟦', Adobe: '🔴',
    Flipkart: '🟡', Uber: '⬛', Meta: '🔵', Apple: '⚫',
  };
  return logos[company] || '🏢';
};

module.exports = router;
