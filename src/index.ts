import loadPlugin from "./loadPlugin"
import spectrometer from "./spectrometer"
import oscilloscope from "./oscilloscope"

function loadPluginAndStartVis() {
  const ctx = new AudioContext()
  const FFT_SIZE = 1024
  const analyser = ctx.createAnalyser()
  analyser.fftSize = FFT_SIZE
  loadPlugin(ctx, "./melody.wasm").then((node) => {
    if (node) {
      node.setOutputParamHandler((path: string, value: number | undefined) =>
        console.log(path, value)
      )
      node.connect(analyser)
      node.connect(ctx.destination)
      spectrometer(
        analyser,
        document.getElementById("spectrum") as HTMLCanvasElement
      )
      oscilloscope(
        analyser,
        document.getElementById("oscilloscope") as HTMLCanvasElement
      )
    }
  })
  return ctx
}

let ctx = loadPluginAndStartVis()

const unlockAudioContext = (ctx: AudioContext) => {
  if (ctx.state !== "suspended") return
  const b = document.body
  const events = ["touchstart", "touchend", "mousedown", "keydown"]
  const unlock: () => void = () => ctx.resume().then(clean)
  const clean: () => void = () =>
    events.forEach((e) => b.removeEventListener(e, unlock))
  events.forEach((e) => b.addEventListener(e, unlock, false))
}

unlockAudioContext(ctx)

// Hot reload when DSP updates! This code is removed in production
if (import.meta.hot) {
  import.meta.hot.on("dsp-update", () => {
    ctx.close()
    ctx = loadPluginAndStartVis()
  })
}
