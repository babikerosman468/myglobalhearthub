MIDI.loadPlugin({
  soundfontUrl: "https://gleitz.github.io/midi-js-soundfonts/FluidR3_GM/",
  instrument: ["violin","flute","timpani","choir_aahs"],
  onsuccess: () => {
    document.querySelectorAll('.bar').forEach(bar => {
      bar.addEventListener('click', () => {
        MIDI.Player.loadFile(bar.dataset.midi, MIDI.Player.start);
      });
    });
  }
});
