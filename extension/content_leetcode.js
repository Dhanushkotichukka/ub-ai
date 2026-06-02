// OwlCoder AI LeetCode Submission Detector

console.log('🦉 OwlCoder AI: LeetCode Detector Activated');

let lastSubmissionUrl = '';

function detectSubmission() {
  // Check if we are on a submissions page or a result card is shown
  const successBadge = document.querySelector('[data-e2e-locator="submission-result"]') || 
                      document.querySelector('.text-success') || 
                      document.querySelector('.success__3ebe') ||
                      document.querySelector('.css-10o4wqw'); // Leetcode legacy success selector
                      
  if (successBadge && successBadge.textContent.includes('Accepted')) {
    const currentUrl = window.location.href;
    
    // Avoid double logging a submission on the same load
    if (currentUrl === lastSubmissionUrl) return;
    lastSubmissionUrl = currentUrl;
    
    console.log('🦉 OwlCoder AI: Detected successful LeetCode submission!');
    
    // Extract problem name
    let problemName = 'Unknown Problem';
    const titleElement = document.querySelector('div[class*="text-title-large"]') || 
                         document.querySelector('[data-cy="question-title"]') ||
                         document.querySelector('.css-v373jf'); // legacy
    
    if (titleElement) {
      // Remove index prefix like "1. Two Sum" -> "Two Sum"
      problemName = titleElement.textContent.replace(/^\d+\.\s*/, '').trim();
    } else {
      // Fallback: extract from page title or URL
      const pathParts = window.location.pathname.split('/');
      const problemSlug = pathParts[2];
      if (problemSlug) {
        problemName = problemSlug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      }
    }
    
    // Extract difficulty
    let difficulty = 'medium'; // default
    const difficultyElement = document.querySelector('div[class*="text-difficulty-"]') || 
                              document.querySelector('[diff]');
    if (difficultyElement) {
      difficulty = difficultyElement.textContent.trim().toLowerCase();
    }
    
    // Clean problem link
    const link = window.location.origin + window.location.pathname;

    chrome.runtime.sendMessage({
      action: 'SUBMISSION_DETECTED',
      data: {
        platform: 'LeetCode',
        problem: problemName,
        difficulty: difficulty,
        link: link
      }
    }, (response) => {
      if (chrome.runtime.lastError) {
        console.error('OwlCoder Extension Error:', chrome.runtime.lastError.message);
      } else if (response && response.success) {
        console.log('🦉 OwlCoder AI: Solved problem logged to dashboard!', problemName);
      }
    });
  }
}

// Observe page changes (LeetCode is a single-page app and updates DOM dynamically)
const observer = new MutationObserver((mutations) => {
  detectSubmission();
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});
