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

const defaultSaveState = {
  level: 1,
  stats: {
    moves: 0,
    fails: 0,
    time: 0,
    continues: 0,
  },
};

const app = Elm.Main.init({
  node: document.getElementById('app'),
  flags: {
    mobile: 'ontouchstart' in document.documentElement,
    lastSave: JSON.parse(window.localStorage?.getItem("lastSave") || JSON.stringify(defaultSaveState)),
  },
});

app.ports.saveGame.subscribe(saveState => {
  localStorage?.setItem("lastSave", JSON.stringify(saveState));
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
