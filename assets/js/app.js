import "phoenix_html"

import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})


// Topbar loader during page loading
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})

let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if(!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200);
  };
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// Page transition animations
window.addEventListener("phx:page-loading-start", info => {
    if (info.detail.kind === "redirect") {
      document.querySelector('[data-main-view]').classList.add("phx-page-loading")
    }
  })
  
window.addEventListener("phx:page-loading-stop", info => {
    document.querySelector('[data-main-view]').classList.remove("phx-page-loading")
})

liveSocket.connect()
// Expose liveSocket on window for console debug logs and latency simulation:
>> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // active for current browser session
>> liveSocket.disableLatencySim() // you'll need to run this after disabling the above
window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
  // Enable server log streaming to client.
  // Disable with reloader.disableServerLogs()
  reloader.enableServerLogs()
  window.liveReloader = reloader
})


window.liveSocket = liveSocket

// REMOVE FOR PRODUCTION
// This logs the time to first contentful paint (FCP) to the console.
new PerformanceObserver((entryList) => {
  for (const entry of entryList.getEntriesByName('first-contentful-paint')) {
    console.log('FCP candidate:', entry.startTime, entry);
  }
}).observe({type: 'paint', buffered: true});


// Add some fun messages to the console
console.log(
  '%c' + `
                                                                                 _     _g                     
        ggmmmmmmmmgg                                           =qg~~~~__        9@)  'T@                      
       ,P        @@                                             [@'    @@             @F                      
       /       _@P            _                                 @@     |@g           !@                       
      '       g@'       _  "B@'   gg@   o@@!     _/ T@         |@'     |@/    g@)    @/      _  9g  ,@@     @,
            _@D        +    @9     @9 _' |@     i   AD         @@      @W   , ,@    A@      g   @F ,  @g    @ 
           o@"        |    @@     /@ /   @/    @'  /"          @"    _@"      @T    @'     B   JF     @@    @ 
         ,@@         @     @'     @ /   gW    &F,<             @mmgj         {@    |@     g/_:'       [@    ' 
        /@F         @   , @9     @//   /@    ;@              ; /  {@        ,[    ,|     /@           |@   *  
      ,g@          @9  , /@  ,  /@/   .@' ,  @@              @     @@       @"    @|  ,  @N           |@  /   
     _@f          ;@  ;  @' '   @?    @F     @g   ,         ;@      @,     AW ,  /@  '   @]   ,       |@ ,    
    @@         f  @@y"  @B+    @F    {@;     @@_,+          @@      [@    ,@k"   @E:     @@  /        |@,     
  _@8        _@   <"    >      "     "        <>           ,@|       @p   0"    'P       "B+          [W      
 dBBmmmmmmm0BB'                                           _@@h       '@L                              )       
                                                                      "                                                                                                   
   _!@@@g____ ,q         __L    @g__               @@@@@@@@@@@@        __o@   @@@@@ !@@@@@              
   @@@@@@@@@@l_  ____g@@@@@@L  [@@@@@@             PPPPPPPPPPPP ___g@@@@@@@@, @@@@@ |@@@@@              
   BB@@@@BB@@@@  @@@@@@@@@@@D^   "4@@              @@@@@@@@@@@@ '@@@@@@@@@@D" @@@@@ |@@@@@|@@@@@@@@@@@@|
    [@@@g :@@@W  '@@@@@@@@]         ___g@@|        PPPPPPPP@@@@  Q@@B@@@@@    """""_|@@@@W|@@@@@@@@@@@@|
    [@@@@gggggg!     [@@@@]   @@@@@@@@@@@@@        gggggg@@@@@@      @@@@@    @@@@@@@@@@@|              
     @@@@@@@@@@|     [@@@@]   [@@@@@@@@@BP         [@@@@@@@@@P       @@@@@    @@@@@@@@@B"               
        """""""'              '"""'                                                                     
`,
  'color: #fff; font-size: 6px; font-family: monospace; font-weight: bold; line-height: 0.5;'
);
const messageContent = [
  "H̴̭͇̋̈́e̷͓̿l̶͙̈́l̷̰̈́o̷͚̿ ̵͙̈́t̵̟̆h̷͚̆e̶͚̓r̶̹̈́e̷͇̓!̶̦̓ ̵͚̒N̵̰̒i̶̹͌c̷͚̈́e̶͇̓ ̶͚̒t̵͇̆o̶͇̔ ̶̹̒m̶̭̒e̶̝̓e̶̝͒t̶̟̆ ̶͇̒y̶̭̔o̵̭͒u̶̦͒!̵̰̒",
  "YOUR CURIOSITY IS DELIGHTFUL AND WELCOME.",
  "GitHub: https://github.com/zaneriley/personal-site",
  "Figma: https://www.figma.com/design/zDOcBhnjTDCWmc6OFgeoUc/Zane-Riley's-Product-Portfolio?node-id=2209-559&t=0gZqDDkC2pYanuW3-0",
  "MAY YOUR JOURNEY BE FILLED WITH WONDER AND DISCOVERY.",
  "THIS TERMINAL WISHES YOU WELL, FELLOW SEEKER OF KNOWLEDGE.",
  "<̴̗̈́s̵̭̒y̶͚̔s̶̭̈́t̵̟̆e̶̦̓m̶̦̒ ̶̦̓h̶̭̆a̶͇̓p̶̦̒p̶͇̒i̶̭̓l̶̰̒y̶̦̒ ̶̦̓h̶͚͒u̶̹͌m̶̦̒m̶̦̒i̶̹͌n̶̰̒g̶̦̒≯̭̒"
];

const baseStyle = 'font-family: "Courier New", monospace; font-size: 14px; line-height: 1.5; text-shadow: 0 0 5px rgba(255,255,255,0.7);';
const glitchStyle = `${baseStyle} color: #e0e0e0; text-shadow: 2px 2px #ff00de, -2px -2px #00ff9f;`;
const normalStyle = `${baseStyle} color: #b0b0b0;`;
const highlightStyle = `${baseStyle} color: #ffffff; font-weight: bold;`;
const systemStyle = `${baseStyle} color: #00ff9f; font-style: italic;`;

console.log('%c[SYSTEM BOOT]', systemStyle);

messageContent.forEach((line, index) => {
  setTimeout(() => {
    if (index === 0 || index === messageContent.length - 1) {
      console.log(`%c${line}`, glitchStyle);
    } else {
      console.log(`%c${line}`, normalStyle);
    }
    
    if (index === messageContent.length - 1) {
      console.log('%c[SYSTEM SHUTDOWN]', systemStyle);
    }
  }, index * 1000); // Delay each line by 1 second
});

    function logCrypticMessage() {
      console.log(`
    /* 
    ${messageContent}
    */
    `);
    }
    logCrypticMessage();

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