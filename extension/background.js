// OwlCoder AI Background Service Worker

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'SUBMISSION_DETECTED') {
    const { platform, problem, difficulty, link } = request.data;
    
    // Retrieve Auth token from local storage
    chrome.storage.local.get(['token', 'backendUrl'], async (result) => {
      const token = result.token;
      const backendUrl = result.backendUrl || 'http://localhost:5000';
      
      if (!token) {
        console.warn('OwlCoder Extension: No auth token found. User needs to log in via the popup.');
        sendResponse({ success: false, message: 'No auth token found. Log in via popup.' });
        return;
      }

      console.log(`OwlCoder Extension: Sending solved problem "${problem}" on ${platform} to backend...`);
      
      try {
        const response = await fetch(`${backendUrl}/api/v1/sync/submission`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            platform: platform.toLowerCase(),
            problem: problem,
            difficulty: difficulty.toLowerCase(),
            link: link,
            timestamp: new Date().toISOString()
          })
        });

        const resData = await response.json();
        
        if (response.ok && resData.success) {
          console.log('OwlCoder Extension: Successfully synced submission!', resData);
          
          // Send notification of achievement
          chrome.action.setBadgeText({ text: '✔' });
          chrome.action.setBadgeBackgroundColor({ color: '#00E676' });
          setTimeout(() => chrome.action.setBadgeText({ text: '' }), 5000);
          
          // Broadcast to popup if open
          chrome.runtime.sendMessage({
            action: 'SYNCED_STATUS',
            data: { success: true, problem, xp: resData.xp?.xpGained, streak: resData.streak?.streak }
          }).catch(() => {}); // suppress error if popup is closed
          
          sendResponse({ success: true, data: resData });
        } else {
          console.error('OwlCoder Extension: Sync failed', resData);
          sendResponse({ success: false, message: resData.message || 'Sync failed' });
        }
      } catch (err) {
        console.error('OwlCoder Extension: Connection error', err);
        sendResponse({ success: false, message: `Server connection error: ${err.message}` });
      }
    });
    
    return true; // Keep message port open for async sendResponse
  }
});
