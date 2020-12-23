import { Elm } from "./Main.elm"
import soundUrls from "../assets/sounds/*.mp3";

const soundBuffers = {};
const audioContext = window.AudioContext && new AudioContext();

if (audioContext) {
  Object.entries(soundUrls).forEach(
    ([file, url]) => {
      window.fetch(url)
        .then(response => response.arrayBuffer())
        .then(arrayBuffer => audioContext.decodeAudioData(
          arrayBuffer,
          audioBuffer => soundBuffers[file] = audioBuffer)
        );
    }
  );
} else {
  alert("Unfortunately, no audio support for your browser :-(");
}

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    mobile: 'ontouchstart' in document.documentElement,
    lastLevel: parseInt(localStorage.getItem("lastLevel") || "0")
  },
});

app.ports.saveGame.subscribe(lastLevel => {
  localStorage.setItem("lastLevel", String(lastLevel));
});

app.ports.playSound.subscribe(filename => {
  if (!audioContext || !(filename in soundBuffers)) {
    return;
  }

  const source = audioContext.createBufferSource();
  source.buffer = soundBuffers[filename];
  source.connect(audioContext.destination);
  source.start(0);
});

// Prevent scrolling with arrow and space keys
window.addEventListener('keydown', e => {
  if ([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
    e.preventDefault();
  }
}, false);

// Capture focus
window.focus();
