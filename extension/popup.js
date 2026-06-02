// OwlCoder AI Popup Script

document.addEventListener('DOMContentLoaded', () => {
  const backendUrlInput = document.getElementById('backendUrl');
  const tokenInput = document.getElementById('token');
  const saveBtn = document.getElementById('saveBtn');
  const statusDot = document.getElementById('statusDot');
  const statusLabel = document.getElementById('statusLabel');
  const statusDesc = document.getElementById('statusDesc');
  const syncLog = document.getElementById('syncLog');
  const openDashboardLink = document.getElementById('openDashboard');

  // Load saved credentials
  chrome.storage.local.get(['token', 'backendUrl', 'lastSyncedProblem', 'lastSyncedTime'], (result) => {
    if (result.backendUrl) {
      backendUrlInput.value = result.backendUrl;
    }
    if (result.token) {
      tokenInput.value = result.token;
      updateStatus(true);
    } else {
      updateStatus(false);
    }
    
    if (result.lastSyncedProblem) {
      syncLog.style.display = 'block';
      syncLog.textContent = `Last Synced:\n${result.lastSyncedProblem}\nat ${new Date(result.lastSyncedTime).toLocaleTimeString()}`;
    }
  });

  // Save button click
  saveBtn.addEventListener('click', () => {
    const token = tokenInput.value.trim();
    const backendUrl = backendUrlInput.value.trim() || 'http://localhost:5000';

    chrome.storage.local.set({ token, backendUrl }, () => {
      if (token) {
        // Optionally verify token by pinging backend health check or profiles route
        fetch(`${backendUrl}/health`)
          .then(res => res.json())
          .then(() => {
            updateStatus(true);
            showBanner('Settings saved & verified! 🦉', '#00E676');
          })
          .catch(err => {
            updateStatus(true, 'Token saved, but server unreachable');
            showBanner('Saved, but server connection failed.', '#FFAB40');
          });
      } else {
        updateStatus(false);
        showBanner('Credentials cleared.', '#FF5252');
      }
    });
  });

  // Open Dashboard Link
  openDashboardLink.addEventListener('click', (e) => {
    e.preventDefault();
    const backendUrl = backendUrlInput.value.trim() || 'http://localhost:5000';
    // Redirect to web client URL if configured, fallback to standard web server/port
    chrome.tabs.create({ url: 'http://localhost:54321/home' }); // matches Flutter Web dev port or local page
  });

  // Listener for successful synchronization reports
  chrome.runtime.onMessage.addListener((message) => {
    if (message.action === 'SYNCED_STATUS' && message.data.success) {
      syncLog.style.display = 'block';
      syncLog.textContent = `Last Synced:\n${message.data.problem}\nat ${new Date().toLocaleTimeString()}\nStreak: ${message.data.streak} days`;
      
      // Save last synced info to storage
      chrome.storage.local.set({
        lastSyncedProblem: message.data.problem,
        lastSyncedTime: new Date().toISOString()
      });
    }
  });

  function updateStatus(connected, customMessage) {
    if (connected) {
      statusDot.className = 'status-dot status-active';
      statusLabel.textContent = customMessage || 'Connected & Active';
      statusDesc.textContent = 'Extension is active. Submissions on LeetCode and GeeksforGeeks will automatically sync to your dashboard.';
    } else {
      statusDot.className = 'status-dot status-inactive';
      statusLabel.textContent = 'Disconnected';
      statusDesc.textContent = 'Sync is inactive. Copy/paste your JWT token from the App Settings screen to configure automatic tracking.';
    }
  }

  function showBanner(text, color) {
    const originalText = saveBtn.textContent;
    saveBtn.textContent = text;
    saveBtn.style.background = color;
    
    setTimeout(() => {
      saveBtn.textContent = originalText;
      saveBtn.style.background = '';
    }, 2500);
  }
});
