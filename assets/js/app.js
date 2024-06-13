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

window.addEventListener("phx:page-loading-start", info => {
    if (info.detail.kind === "redirect") {
      document.querySelector("body").classList.add("phx-page-loading")
    }
  })
  

window.addEventListener("phx:page-loading-stop", info => {
    document.querySelector("body").classList.remove("phx-page-loading")
})

liveSocket.connect()
// Expose liveSocket on window for console debug logs and latency simulation:
>> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // active for current browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


// // -----------------------------------------------------------------------------
// // Theme toggle
// // TODO: Figure out if we want to use a JS framework
// // -----------------------------------------------------------------------------
// let userThemeChannel; 

// async function manageConnection() {
//   const userToken = localStorage.getItem('userToken');
//   try {
//     if (userToken) {
//       console.log("Existing token found. Using existing token:", userToken);
//       userThemeChannel = await connectToSocket(userToken);
//       setupThemeToggle(userThemeChannel); 
//     } else {
//       console.log("No existing token found. Requesting a new token.");
//       await requestTokenAndConnect(); 
//     }
//   } catch (error) {
//     console.error("Error managing connection:", error);
//   }
// }

// function requestTokenAndConnect() {
//   console.log("Requesting new token...");
//   return new Promise((resolve, reject) => {
//     fetch("/api/session/generate", { method: "POST" })
//       .then(response => response.json())
//       .then(data => {
//         console.log("New token received:", data.token);
//         localStorage.setItem('userToken', data.token);
//         localStorage.setItem('userId', data.user_id);
//         connectToSocket(data.token).then(channel => {
//           console.log("Connected with new token");
//           resolve(channel);
//         }).catch(reject);
//       })
//       .catch(error => {
//         console.error("Error fetching user token:", error);
//         reject(error);
//       });
//   });
// }

// function connectToSocket(token) {
//   console.log("Connecting to socket with token:", token);
//   return new Promise((resolve, reject) => {
//     let themeSocket = new Socket("/socket", {params: {token: token}});

//     themeSocket.onOpen(() => {
//       console.log("Socket opened.");
//       const userId = localStorage.getItem('userId');
//       console.log("User ID:", userId);
//       if (userId && userId !== "null") {
//         let userThemeChannel = themeSocket.channel(`user_theme:${userId}`, {});
//         userThemeChannel.join()
//           .receive("ok", resp => {
//               console.log("Joining user theme channel:", userThemeChannel);
//               resolve(userThemeChannel);
//           })
//           .receive("error", resp => {
//               console.error("Unable to join user theme channel", resp);
//               reject("Unable to join channel");
//           });
//       } else {
//         console.error("Invalid or missing userId. Cannot join user-specific theme channel.");
//         reject("Invalid userId");
//       }
//     });

//     themeSocket.onError((err) => {
//       console.log("Socket error:", err);

//       if (err.reason === "invalid_token") {
//         console.log("Token is invalid. Requesting a new token.");
//         requestTokenAndConnect().then(resolve).catch(reject);
//       } else {
//         console.error("Socket connection error:", err);
//         reject(err);
//       }
//     });

//     themeSocket.connect();
//   });
// }

// document.addEventListener('DOMContentLoaded', () => {
//   setupThemeToggle(); 
//   manageConnection(); 
// });

// function setupThemeToggle() {
//   const themeToggle = document.getElementById('theme-toggle');
//   if (!themeToggle) return;

//   applyStoredThemePreference();

//   if (userThemeChannel) {
//     userThemeChannel.on("theme_changed", payload => {
//       const theme = payload.theme;
//       console.log("Theme changed to: ", theme);
//       document.body.classList.toggle('dark-mode', theme === 'dark');
//       localStorage.setItem('themePreference', theme);
//       themeToggle.checked = theme === 'dark';
//     });
//   } else {
//     console.warn("userThemeChannel is not defined. Cannot listen for theme changes.");
//   }

//   themeToggle.addEventListener('change', handleThemeToggleChange);
// }

// let debounceTimer;
// function handleThemeToggleChange() {
//   const themeToggle = document.getElementById('theme-toggle');
//   if (!themeToggle) return;

//   const newTheme = themeToggle.checked ? 'dark' : 'light';
//   console.log("Theme toggle changed. New theme:", newTheme);
//   document.body.classList.toggle('dark-mode', themeToggle.checked);
//   localStorage.setItem('themePreference', newTheme);

//   clearTimeout(debounceTimer);
//   debounceTimer = setTimeout(() => {
//     console.log("Updating theme preference to user's channel...", userThemeChannel);
//     if (userThemeChannel) {
//       console.log("Sending theme change to server, new theme:", newTheme);
//       userThemeChannel.push("toggle_theme", { theme: newTheme })
//         .receive("error", () => {
//           console.log("Error updating theme. Retrying...");
//           retryThemeUpdate(newTheme);
//         });
//     } else {
//       console.log("User not connected. Storing theme preference locally.");
//       localStorage.setItem('temporaryThemePreference', newTheme);
//     }
//   }, 250);
// }

// function retryThemeUpdate(newTheme, attempts = 0) {
//   console.log(`Retrying theme update. Attempt ${attempts + 1}`);
//   if (attempts < 3) { 
//     setTimeout(() => {
//       console.log("Attempting to push new theme preference to the channel on retry...");
//       userThemeChannel.push("toggle_theme", { theme: newTheme })
//         .receive("ok", () => console.log("Theme preference updated successfully on the server on retry."))
//         .receive("error", () => retryThemeUpdate(newTheme, attempts + 1));
//     }, 1000 * (attempts + 1));
//   } else {
//     console.error("Failed to update theme after 3 attempts.");
//   }
// }


// function applyStoredThemePreference() {
//   const storedTheme = localStorage.getItem('themePreference');
//   if (storedTheme) {
//     document.body.classList.toggle('dark-mode', storedTheme === 'dark');
//     console.log("Theme preference found in localStorage: ", storedTheme);
//     const themeToggle = document.getElementById('theme-toggle');
//     if (themeToggle) themeToggle.checked = storedTheme === 'dark';
//   }
// }