import loadPlugin from "./loadPlugin"
import spectrometer from "./spectrometer"
import oscilloscope from "./oscilloscope"
import slider from "./slider"

function loadPluginAndStartVis() {
  const ctx = new AudioContext()
  const FFT_SIZE = 1024
  const analyser = ctx.createAnalyser()
  analyser.fftSize = FFT_SIZE
  loadPlugin(ctx, "./melody.wasm").then((node) => {
    if (node) {
      node.setOutputParamHandler((path: string, value: number | undefined) => {
        switch (path) {
          case "/melody/output/kick-beat":
            ;(document.getElementById("kick") as HTMLInputElement).checked =
              (value ?? 0) > 0 ? true : false
            break
          case "/melody/output/phasor":
            console.log(value)
            ;(
              document.getElementById("djembe-freqs") as HTMLInputElement
            ).value = typeof value !== "undefined" && value >= 0 ? value?.toString(10) : ""
            break
        }
      })
      node.connect(analyser)
      node.connect(ctx.destination)
      spectrometer(
        document.getElementById("spectrum") as HTMLCanvasElement,
        analyser
      )
      oscilloscope(
        document.getElementById("oscilloscope") as HTMLCanvasElement,
        analyser
      )
      node.setParamValue("/melody/input/bpm", 120)
      slider(
        document.getElementById("bpm")! as HTMLInputElement,
        (value: number) => node.setParamValue("/melody/input/bpm", value),
        { min: 30, max: 180, step: 1, init: 120 }
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
