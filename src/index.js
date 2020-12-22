import { Elm } from "./Main.elm"

var app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    mobile: 'ontouchstart' in document.documentElement,
    lastLevel: parseInt(localStorage.getItem("lastLevel") || "0")
  },
});

app.ports.saveGame.subscribe(function (lastLevel) {
  localStorage.setItem("lastLevel", String(lastLevel));
});

// Prevent scrolling with arrow and space keys
window.addEventListener('keydown', function (e) {
  if ([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
    e.preventDefault();
  }
}, false);

// Capture focus
window.focus();
