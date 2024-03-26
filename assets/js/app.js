import "phoenix_html"

// TODO: Figure out how we plan to handle JS frameworks.
document.addEventListener('DOMContentLoaded', function() {
    const themeToggle = document.getElementById('theme-toggle');
    themeToggle.addEventListener('change', function() {
      fetch('/api/light-dark-mode/toggle', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        const theme = data.theme;
        // Assuming you have CSS classes for .light-mode and .dark-mode
        if (theme === 'light') {
          document.body.classList.add('light-mode');
          document.body.classList.remove('dark-mode');
        } else {
          document.body.classList.add('dark-mode');
          document.body.classList.remove('light-mode');
        }
      })
      .catch(error => console.error('Error toggling theme:', error));
    });
  });
  
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
