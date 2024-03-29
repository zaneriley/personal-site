import "phoenix_html"

// If you don't plan to use LV or websockets you can delete all of the code below.
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})
let topBarScheduled = undefined

topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(500))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

liveSocket.connect()
// Expose liveSocket on window for console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // active for current browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


// -----------------------------------------------------------------------------
// Theme toggle
// TODO: Figure out if we want to use a JS framework
// -----------------------------------------------------------------------------
let userThemeChannel; 

async function manageConnection() {
  const userToken = localStorage.getItem('userToken');
  try {
    if (userToken) {
      console.log("Existing token found. Using the existing token.");
      userThemeChannel = await connectToSocket(userToken);
      setupThemeToggle(userThemeChannel); 
    } else {
      console.log("No existing token found. Requesting a new token.");
      await requestTokenAndConnect(); 
    }
  } catch (error) {
    console.error("Error managing connection:", error);
  }
}

function requestTokenAndConnect() {
  fetch("/api/session/generate", { method: "POST" })
    .then(response => response.json())
    .then(data => {
      localStorage.setItem('userToken', data.token);
      localStorage.setItem('userId', data.user_id);
      console.log("New token generated: ", data.token);
      connectToSocket(data.token);
    })
    .catch(error => {
      console.error("Error fetching user token:", error);
    });
}

function connectToSocket(token) {
  return new Promise((resolve, reject) => {
    let themeSocket = new Socket("/socket", {params: {token: token}})
    themeSocket.onOpen(() => console.log("Socket opened."))
    themeSocket.onError((err) => {
      console.log("Socket error:", err);
      // Handle token issues
      if (err.reason === "invalid_token") {
        console.log("Token is invalid. Requesting a new token.");
        requestTokenAndConnect(); 
      } else {
        reject(err); 
      }
    });
    themeSocket.connect()

    const userId = localStorage.getItem('userId');
    if (userId && userId !== "null") { 
      let userThemeChannel = themeSocket.channel(`user_theme:${userId}`, {});

      userThemeChannel.join()
        .receive("ok", resp => {
            console.log(`Joined user theme channel successfully`, resp);
            resolve(userThemeChannel); // Resolve the promise with the channel
        })
        .receive("error", resp => {
            console.log("Unable to join user theme channel", resp);
            reject("Unable to join channel");
        });
    } else {
      console.error("Invalid or missing userId. Cannot join user-specific theme channel.");
      reject("Invalid userId");
    }
  });
}

function setupThemeToggle() {
  if (!userThemeChannel) {
      console.warn("userThemeChannel not yet defined. Skipping setup.");
      return;
  } 
  const themeToggle = document.getElementById('theme-toggle');
  if (!themeToggle) return;

  applyStoredThemePreference();

  userThemeChannel.on("theme_changed", payload => {
    const theme = payload.theme;
    console.log("Theme changed to: ", theme);
    document.body.classList.toggle('dark-mode', theme === 'dark');
    localStorage.setItem('themePreference', theme);
    themeToggle.checked = theme === 'dark';
  });

  themeToggle.removeEventListener('change', handleThemeToggleChange);
  themeToggle.addEventListener('change', handleThemeToggleChange);
}

function applyStoredThemePreference() {
  const storedTheme = localStorage.getItem('themePreference');
  if (storedTheme) {
    document.body.classList.toggle('dark-mode', storedTheme === 'dark');
    console.log("Theme preference found in localStorage: ", storedTheme);
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) themeToggle.checked = storedTheme === 'dark';
  }
}

function handleThemeToggleChange() {
  console.log("UI theme toggled");
  const themeToggle = document.getElementById('theme-toggle');
  if (!themeToggle) return;

  const newTheme = themeToggle.checked ? 'dark' : 'light';
  console.log("Applying theme change to UI: ", newTheme);
  document.body.classList.toggle('dark-mode', themeToggle.checked);
  localStorage.setItem('themePreference', newTheme);

  debouncedThemeToggleChange(newTheme);
}

function debouncedThemeToggleChange(newTheme) {
  debounce(() => {
    console.log("Sending theme change to server, new theme: ", newTheme);
    userThemeChannel.push("toggle_theme", {theme: newTheme});
  }, 250)();
}

function debounce(func, wait, immediate) {
  let timeout;
  return function() {
    const context = this, args = arguments;
    const later = function() {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}

document.addEventListener('DOMContentLoaded', () => {
  manageConnection();
});