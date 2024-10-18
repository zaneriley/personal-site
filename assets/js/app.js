import "phoenix_html";
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "topbar";

import ThemeSwitcherHook from "./hooks/theme_switcher_hook";

// Define hooks before using them
const Hooks = {};
Hooks.ThemeSwitcher = ThemeSwitcherHook;

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks, // Now Hooks is defined and contains ThemeSwitcherHook
  params: { _csrf_token: csrfToken },
});

// Topbar loader during page loading
topbar.config({
  barColors: { 0: "#C4FB50" },
  shadowColor: "rgba(0, 0, 0, .3)",
});

let topBarScheduled = undefined;
window.addEventListener("phx:page-loading-start", () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200);
  }
});
window.addEventListener("phx:page-loading-stop", () => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// Page transition animations
window.addEventListener("phx:page-loading-start", (info) => {
  if (info.detail.kind === "redirect") {
    document
      .querySelector("[data-main-view]")
      .classList.add("phx-page-loading");
  }
});

window.addEventListener("phx:page-loading-stop", (info) => {
  document
    .querySelector("[data-main-view]")
    .classList.remove("phx-page-loading");
});

(liveSocket.connect() >>
  // Expose liveSocket on window for console debug logs and latency simulation:
  liveSocket.enableDebug()) >>
  // >> liveSocket.enableLatencySim(1000)  // active for current browser session
  liveSocket.disableLatencySim(); // you'll need to run this after disabling the above
window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
  // Enable server log streaming to client.
  // Disable with reloader.disableServerLogs()
  reloader.enableServerLogs();
  window.liveReloader = reloader;
});

window.liveSocket = liveSocket;

// REMOVE FOR PRODUCTION
// This logs the time to first contentful paint (FCP) to the console.
new PerformanceObserver((entryList) => {
  for (const entry of entryList.getEntriesByName("first-contentful-paint")) {
    console.log("FCP candidate:", entry.startTime, entry);
  }
}).observe({ type: "paint", buffered: true });

// Add some fun messages to the console
console.log(
  "%c" +
    `
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
  "color: #fff; font-size: 8px; font-family: monospace; font-weight: bold; line-height: 0.5;",
);
const messageContent = [
  "H̴̭͇̋̈́e̷͓̿l̶͙̈́l̷̰̈́o̷͚̿ ̵͙̈́t̵̟̆h̷͚̆e̶͚̓r̶̹̈́e̷͇̓!̶̦̓ ̵͚̒N̵̰̒i̶̹͌c̷͚̈́e̶͇̓ ̶͚̒t̵͇̆o̶͇̔ ̶̹̒m̶̭̒e̶̝̓e̶̝͒t̶̟̆ ̶͇̒y̶̭̔o̵̭͒u̶̦͒!̵̰̒",
  "YOUR CURIOSITY IS DELIGHTFUL AND WELCOME.",
  "THE CODE IS ON GITHUB https://github.com/zaneriley/personal-site",
  "AND DESIGNS IN FIGMA https://www.figma.com/design/zDOcBhnjTDCWmc6OFgeoUc/Zane-Riley's-Product-Portfolio?node-id=2209-559&t=0gZqDDkC2pYanuW3-0",
  "MAY YOUR JOURNEY BE FILLED WITH WONDER AND DISCOVERY.",
  "THIS TERMINAL WISHES YOU WELL, FELLOW SEEKER OF KNOWLEDGE.",
  "<̴̗̈́s̵̭̒y̶͚̔s̶̭̈́t̵̟̆e̶̦̓m̶̦̒p̶͇̒i̶̭̓l̶̰̒y̶̦̒ ̶̦̓h̶̭̆a̶͇̓p̶̦̒p̶͇̒i̶̭̓l̶̰̒y̶̦̒ ̶̦̓h̶͚͒u̶̹͌m̶̦̒m̶̦̒i̶̹͌n̶̰̒g̶̦̒≯̭̒",
];

const baseStyle =
  'font-family: "Courier New", monospace; font-size: 14px; line-height: 1.5; text-shadow: 0 0 5px rgba(255,255,255,0.7);';
const glitchStyle = `${baseStyle} color: #e0e0e0; text-shadow: 2px 2px #ff00de, -2px -2px #00ff9f;`;
const normalStyle = `${baseStyle} color: #b0b0b0;`;
const highlightStyle = `${baseStyle} color: #ffffff; font-weight: bold;`;
const systemStyle = `${baseStyle} color: #00ff9f; font-style: italic;`;

console.log("%c[SYSTEM BOOT]", systemStyle);

messageContent.forEach((line, index) => {
  setTimeout(() => {
    if (index === 0 || index === messageContent.length - 1) {
      console.log(`%c${line}`, glitchStyle);
    } else {
      console.log(`%c${line}`, normalStyle);
    }

    if (index === messageContent.length - 1) {
      console.log("%c[SYSTEM SHUTDOWN]", systemStyle);
    }
  }, index * 1000); // Delay each line by 1 second
});

// Remove the direct call to initThemeToggle(); the hook will handle initialization
// initThemeToggle(); // Remove or comment out this line
