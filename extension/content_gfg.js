// OwlCoder AI GeeksforGeeks Submission Detector

console.log('🦉 OwlCoder AI: GeeksforGeeks Detector Activated');

let lastSubmissionUrl = '';

function detectSubmission() {
  // GFG displays success prompts on successful runs, e.g., "Problem Solved Successfully"
  const successBadge = document.querySelector('.problems_correct_ans__') || 
                      document.querySelector('.success-card') ||
                      document.querySelector('.problem-solved-modal') ||
                      document.querySelector('.solved_status_text') ||
                      document.body.innerText.includes('Problem Solved Successfully');

  if (successBadge) {
    const currentUrl = window.location.href;
    
    // Avoid double logging a submission on the same load
    if (currentUrl === lastSubmissionUrl) return;
    lastSubmissionUrl = currentUrl;
    
    console.log('🦉 OwlCoder AI: Detected successful GeeksforGeeks submission!');
    
    // Extract problem name
    let problemName = 'Unknown Problem';
    const titleElement = document.querySelector('.problem-heading') || 
                         document.querySelector('h3[class*="ProblemHeading"]') ||
                         document.querySelector('.problems_header_div__ h4');
    
    if (titleElement) {
      problemName = titleElement.textContent.trim();
    } else {
      // Fallback: extract from URL
      const pathParts = window.location.pathname.split('/');
      const problemSlug = pathParts[2];
      if (problemSlug) {
        problemName = problemSlug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
      }
    }
    
    // Extract difficulty
    let difficulty = 'medium'; // default
    const difficultyElement = document.querySelector('.problem-difficulty') || 
                              document.querySelector('span[class*="Difficulty"]');
    if (difficultyElement) {
      const diffText = difficultyElement.textContent.trim().toLowerCase();
      if (['easy', 'school', 'basic'].includes(diffText)) difficulty = 'easy';
      else if (['medium'].includes(diffText)) difficulty = 'medium';
      else if (['hard'].includes(diffText)) difficulty = 'hard';
    }
    
    // Clean problem link
    const link = window.location.origin + window.location.pathname;

    chrome.runtime.sendMessage({
      action: 'SUBMISSION_DETECTED',
      data: {
        platform: 'GFG',
        problem: problemName,
        difficulty: difficulty,
        link: link
      }
    }, (response) => {
      if (chrome.runtime.lastError) {
        console.error('OwlCoder Extension Error:', chrome.runtime.lastError.message);
      } else if (response && response.success) {
        console.log('🦉 OwlCoder AI: Solved GFG problem logged!', problemName);
      }
    });
  }
}

// Observe GFG DOM modifications
const observer = new MutationObserver((mutations) => {
  detectSubmission();
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});
