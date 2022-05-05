import loadPlugin from "./loadPlugin"
import spectrometer from "./spectrometer"
import oscilloscope from "./oscilloscope"
import slider from "./slider"
import button from "./button"

let clean: () => void;

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
          case "/melody/output/log":
            ;(
              document.getElementById("log") as HTMLInputElement
            ).value = typeof value !== "undefined" && value >= 0 ? value?.toString(10) : ""
            break
        }
      })
      node.connect(analyser)
      node.connect(ctx.destination)
      const cl1 = spectrometer(
        document.getElementById("spectrum") as HTMLCanvasElement,
        analyser
      )
      const cl2 = oscilloscope(
        document.getElementById("oscilloscope") as HTMLCanvasElement,
        analyser
      )
      const bpmEl = document.getElementById("bpm")! as HTMLInputElement
      node.setParamValue("/melody/input/bpm", bpmEl.valueAsNumber)
      const cl3 = slider(
        bpmEl,
        (value: number) => node.setParamValue("/melody/input/bpm", value),
        { min: 30, max: 180, step: 1, init: bpmEl.valueAsNumber }
      )
      const cl4 = button(document.getElementById("restart")! as HTMLButtonElement, (value: number) => node.setParamValue("/melody/input/restart", value)
      )

      clean = () => {
        cl1()
        cl2()
        cl3()
        cl4()
      }
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
    clean()
    ctx.close()
    ctx = loadPluginAndStartVis()
  })
}
