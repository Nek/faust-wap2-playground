// Reload the page when DSP is updated! This code is removed in final build
if (import.meta.hot) {
  import.meta.hot.on("dsp-update", () => {
    location.reload()
  })
}

import { Atom } from "@thi.ng/atom/atom"
import { canvas } from "@thi.ng/hdom-canvas"
import { DEFAULT_THEME, Key, type GUITheme } from "@thi.ng/imgui/api"
import { buttonH } from "@thi.ng/imgui/components/button"
import { dropdown } from "@thi.ng/imgui/components/dropdown"
import { ring } from "@thi.ng/imgui/components/ring"
import { sliderV } from "@thi.ng/imgui/components/sliderv"
import { textLabel } from "@thi.ng/imgui/components/textlabel"
import { IMGUI } from "@thi.ng/imgui/gui"
import { gridLayout } from "@thi.ng/layout/grid-layout"
import { PI } from "@thi.ng/math/api"
import { gestureStream } from "@thi.ng/rstream-gestures"
import { fromDOMEvent } from "@thi.ng/rstream/event"
import { fromRAF } from "@thi.ng/rstream/raf"
import { float } from "@thi.ng/strings/float"
import { updateDOM } from "@thi.ng/transducers-hdom"
import { map } from "@thi.ng/transducers/map"
import { Vec2 } from "@thi.ng/vectors"
import { canvas2D } from "@thi.ng/hdom-components"
import loadPlugin from "./loadPlugin"

const unlockAudioContext = (ctx: AudioContext) => {
  if (ctx.state !== "suspended") return
  const b = document.body
  const events = ["touchstart", "touchend", "mousedown", "keydown"]
  const unlock: () => void = () => ctx.resume().then(clean)
  const clean: () => void = () =>
    events.forEach((e) => b.removeEventListener(e, unlock))
  events.forEach((e) => b.addEventListener(e, unlock, false))
}
const ctx = new AudioContext()
unlockAudioContext(ctx)

const node = await loadPlugin(ctx, "./melody.wasm")
const analyser = ctx.createAnalyser()
const timeDomain = new Uint8Array(analyser.fftSize)
const bufferLength = analyser.frequencyBinCount
const floatFrequencyData = new Float32Array(bufferLength)
if (node) {
  node.setOutputParamHandler((path: string, value: number | undefined) => {
    console.log(path, value)
  })
  node.connect(ctx.destination)
  node.connect(analyser)
}

// define theme colors in RGBA format for future compatibility with
// WebGL backend
const THEMES: Partial<GUITheme>[] = [
  DEFAULT_THEME,
  {
    globalBg: "#ccc",
    focus: [1, 0.66, 0, 1],
    cursor: [0, 0, 0, 1],
    bg: [1, 1, 1, 0.66],
    bgDisabled: [1, 1, 1, 0.33],
    bgHover: [1, 1, 1, 0.9],
    fg: [0.8, 0, 0.8, 1],
    fgDisabled: [0.8, 0, 0.8, 0.5],
    fgHover: [1, 0, 1, 1],
    text: [0.3, 0.3, 0.3, 1],
    textDisabled: [0.3, 0.3, 0.3, 0.5],
    textHover: [0.2, 0.2, 0.4, 1],
    bgTooltip: [1, 1, 0.8, 0.85],
    textTooltip: [0, 0, 0, 1]
  }
]

// float value formatters
const F1 = float(0)
const F2 = float(2)

// UI constants
const FONT = "12px 'IBM Plex Mono'"
const CHANNEL_LABELS = ["KICK", "HATS", "CHRD", "MRMB", "DJMB"]
const CHANNEL_PARAMS = [
  "kick/volume",
  "hat/volume",
  "chords/volume",
  "marimba/volume",
  "djembe/volume"
]
interface AppState {
  theme: number
  channels: number[]
  bpm: number
  progression: number
  key: number
}

const PROGRESSIONS = [
  "i-iv-VI-v",
  "i-iv-III-VI",
  "i-VI-III-VII",
  "i-VI-III-iv",
  "I-vi-IV-V",
  "I-V-vi-IV",
  "I-IV-V-IV",
  "vi-IV-I-V",
  "I-IV-ii-V",
  "I-IV-I-V"
]
const KEYS = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

// main immutable app state wrapper (with time travel)
const DB = new Atom<AppState>({
  theme: 0,
  channels: [0, 0, 0, 0, 0],
  bpm: 118,
  progression: 0,
  key: 0
})

// theme merging helper
const themeForID = (theme: number): Partial<GUITheme> => ({
  ...THEMES[theme % THEMES.length],
  font: FONT,
  cursorBlink: 0
})

// main application
const app = () => {
  // GUI instance
  const gui = new IMGUI({ theme: themeForID(DB.deref().theme) })

  // augment hdom-canvas component with init lifecycle method to
  // attach event streams once canvas has been mounted
  const _canvas = {
    ...canvas,
    init(canv: HTMLCanvasElement) {
      gestureStream(canv, {}).subscribe({
        next(e) {
          gui.setMouse(e.pos, e.buttons)
        }
      }),
        // keydown & undo/redo handler:
        fromDOMEvent(window, "keydown").subscribe({
          next(e) {
            if (e.key === Key.TAB) {
              e.preventDefault()
            }

            gui.setKey(e)
          }
        }),
        fromDOMEvent(window, "keyup").subscribe({
          next(e) {
            gui.setKey(e)
          }
        })
    }
  }

  const oscilloscope = canvas2D({
    init(_el: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {},
    update(_el: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {
      const x0 = 0
      const y0 = 0
      const width = _el.width
      const height = _el.height
      analyser.getByteTimeDomainData(timeDomain)
      const step = width / timeDomain.length

      ctx.clearRect(0, 0, width, height)

      ctx.beginPath()

      for (let i = 0; i < timeDomain.length; i += 4) {
        const percent = timeDomain[i] / 256
        const x = x0 + i * step
        const y = y0 + height * percent
        ctx.lineTo(x, y)
      }

      ctx.stroke()
    }
  })

  const INCREMENT_PER_FRAME = 1
  const COLOR_GAIN = 19
  const BASE_COLOR_HUE = 120

  const spectrometer = canvas2D({
    init(_el: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {},
    update(_el: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {
      analyser.getFloatFrequencyData(floatFrequencyData)

      const canvasHeightUnit = _el.height / bufferLength

      for (let i = 0; i < bufferLength; i++) {
        const output = Math.pow(1.8, floatFrequencyData[i] / COLOR_GAIN)
        const colorShift = +BASE_COLOR_HUE + i / 3

        ctx.fillStyle = `hsl(${360 * -output + colorShift}deg, 100%, ${
          output * 100
        }%)`
        ctx.fillRect(
          _el.width - INCREMENT_PER_FRAME,
          -i * canvasHeightUnit + _el.height,
          INCREMENT_PER_FRAME,
          canvasHeightUnit
        )
      }

      ctx.save()
      ctx.translate(-INCREMENT_PER_FRAME, 0)
      ctx.drawImage(_el, 0, 0)
      ctx.restore()
    }
  })

  // main GUI update function
  const updateGUI = (draw: boolean) => {
    // obtain atom value
    const state = DB.deref()
    // setup initial layout (single column)
    const width = window.innerWidth
    const rowH = width / 20
    const grid = gridLayout(10, 10, width - 20, 1, rowH, 4)

    const size = (width * 18) / 600
    gui.setTheme({
      ...themeForID(state.theme),
      font: `${size}px 'IBM Plex Mono'`
    })

    // start frame
    gui.begin(draw)

    let res: any

    const row1 = grid.nest(1, [1, 5])

    const path = (name: string) => `/melody/input/${name}`

    textLabel(gui, row1, "PROGRESSION")
    if (
      (res = dropdown(
        gui,
        row1,
        "progression",
        state.progression,
        PROGRESSIONS,
        ""
      )) !== undefined
    ) {
      node?.setParamValue(path("progression"), res)
      node?.setParamValue(path("scale"), res > 3 ? 1 : 0)
      DB.resetIn(["progression"], res)
    }
    textLabel(gui, row1, "KEY")
    if ((res = dropdown(gui, row1, "key", state.key, KEYS, "")) !== undefined) {
      node?.setParamValue(path("key"), res)
      DB.resetIn(["key"], res)
    }

    const row2 = grid.nest(5, [1, 10])

    CHANNEL_PARAMS.forEach((param, i) => {
      const column = row2.nest(1)
      if (
        (res = sliderV(
          gui,
          column,
          param,
          0,
          1,
          0.01,
          state.channels[i],
          8,
          "",
          F2
        )) !== undefined
      ) {
        node?.setParamValue(path(param), res)
        DB.resetIn(["channels", i], res)
      }
      textLabel(gui, column, CHANNEL_LABELS[i])
    })

    const row3 = grid.nest(5, [2, 3])

    if (
      (res = ring(
        gui,
        row3,
        "bpm",
        30,
        180,
        1,
        state.bpm,
        PI,
        0.5,
        "BPM",
        F1
      )) !== undefined
    ) {
      node?.setParamValue(path("bpm"), res)
      DB.resetIn(["bpm"], res)
    }

    if (buttonH(gui, row3, "resync", "RESYNC")) {
      node?.setParamValue(path("reset"), 1)
      node?.setParamValue(path("reset"), 0)
    }

    gui.end()
  }

  // main component function
  return () => {
    const width = window.innerWidth
    const height = window.innerHeight

    // this is only needed because we're NOT using a RAF update loop:
    // call updateGUI twice to compensate for lack of regular 60fps update
    // Note: Unless your GUI is super complex, this cost is pretty neglible
    // and no actual drawing takes place here ...
    // updateGUI(false)
    updateGUI(true)
    // return hdom-canvas component with embedded GUI
    return [
      "div",
      [oscilloscope, { width, height: 100 }],
      [spectrometer, {width, height: 100}],
      ,
      [
        _canvas,
        {
          width,
          height: height - 200,
          style: { background: gui.theme.globalBg, cursor: gui.cursor },
          oncontextmenu: (e: Event) => e.preventDefault(),
          ...gui.attribs
        },
        // IMGUI implements IToHiccup interface so just supply as is
        gui
      ]
    ]
  }
}

// main stream combinator
// the trigger() input is merely used to kick off the system
// once the 1st frame renders, the canvas component will create and attach
// event streams to this stream sync, which are then used to trigger future
// updates on demand...
// const main = sync({
//   src: {
//     state: fromAtom(DB)
//   }
// })

// subscription & transformation of app state stream. uses a RAF
// sidechain to buffer intra-frame state updates. then only passes the
// most recent one to `app()` and its resulting UI tree to the
// `updateDOM()` transducer
fromRAF().transform(map(app()), updateDOM())
// sidechainPartitionRAF(main).transform(map(app()), updateDOM())
