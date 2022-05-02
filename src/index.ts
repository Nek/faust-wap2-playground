import loadPlugin from "./loadPlugin"
import spectrometer from "./spectrometer"
import oscilloscope from "./oscilloscope"

var ctx = new AudioContext()

const FFT_SIZE = 1024

var splitter = ctx.createChannelSplitter(3)
var analyser = ctx.createAnalyser()
analyser.fftSize = FFT_SIZE

loadPlugin(ctx, "./melody.wasm").then((node) => {
  node.setOutputParamHandler((path, value) => console.log(path, value))
  node.connect(splitter)
  node.connect(analyser)
  node.connect(ctx.destination)
  spectrometer(analyser, document.getElementById("spectrum"))
  oscilloscope(analyser, document.getElementById("oscilloscope"))
})
