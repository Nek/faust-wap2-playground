// Reload the page when DSP is updated! This code is removed in final build
if (import.meta.hot) {
  import.meta.hot.on("dsp-update", () => {
    location.reload()
  })
}

import { PI } from "@thi.ng/math/api"
import { Atom } from "@thi.ng/atom/atom"
import { line } from "@thi.ng/geom/line"
import { canvas } from "@thi.ng/hdom-canvas"
import { DEFAULT_THEME, Key, NONE, type GUITheme } from "@thi.ng/imgui/api"
import { sliderV } from "@thi.ng/imgui/components/sliderv"
import { ring } from "@thi.ng/imgui/components/ring"
import { IMGUI } from "@thi.ng/imgui/gui"
import { gridLayout, GridLayout } from "@thi.ng/layout/grid-layout"
import { clamp } from "@thi.ng/math/interval"
import { gestureStream } from "@thi.ng/rstream-gestures"
import { fromAtom } from "@thi.ng/rstream/atom"
import { fromDOMEvent } from "@thi.ng/rstream/event"
import { merge } from "@thi.ng/rstream/merge"
import { sidechainPartitionRAF } from "@thi.ng/rstream/sidechain-partition"
import { sync } from "@thi.ng/rstream/sync"
import { float } from "@thi.ng/strings/float"
import { updateDOM } from "@thi.ng/transducers-hdom"
import { map } from "@thi.ng/transducers/map"
import loadPlugin from "./loadPlugin"
import { textLabel, textLabelRaw } from "@thi.ng/imgui/components/textlabel"

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
if (node) {
  node.setOutputParamHandler((path: string, value: number | undefined) => {
    console.log(path, value)
  })
  node.connect(ctx.destination)
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
const F2 = float(3)

// UI constants
const FONT = "10px 'IBM Plex Mono'"
const CHANNEL_LABELS = ["KICK", "HATS", "CHRD", "MRMB", "DJMB"]
const CHANNEL_PARAMS = ["kick/volume", "hat/volume", "chords/volume", "marimba/volume", "djembe/volume"]
interface AppState {
  theme: number
  channels: number[]
  bpm: number
}

// main immutable app state wrapper (with time travel)
const DB = new Atom<AppState>({
  theme: 0,
  channels: [
    0,
    0,
    0,
    0,
    0
  ],
  bpm: 118
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
      // add event streams to main stream combinator
      // in order to trigger GUI updates...
      main.add(
        // merge all event streams into a single input to `main`
        // (we don't actually care about their actual values and merely
        // use them as mechanism to trigger updates)
        merge<any, any>({
          src: [
            // mouse & touch events
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
          ]
        })
      )
    }
  }

  // main GUI update function
  const updateGUI = (draw: boolean) => {
    // obtain atom value
    const state = DB.deref()
    // setup initial layout (single column)
    const grid = gridLayout(10, 10, window.innerWidth - 20, 1, 16, 4)

    gui.setTheme(themeForID(state.theme))

    // start frame
    gui.begin(draw)

    let res: any

    const row1 = grid.nest(5, [1, 12])
    const row2 = grid.nest(5)
    row2.next()
    row2.next()

    const path = (name: string) => `/melody/input/${name}`

    CHANNEL_PARAMS.forEach((param, i) => {
      const column = row1.nest(1)
      if (
        (res = sliderV(
          gui,
          column,
          param,
          0,
          1,
          0.05,
          state.channels[i],
          8,
          CHANNEL_LABELS[i],
          F2
        )) !== undefined
      ) {
        node?.setParamValue(path(param), res)
        DB.resetIn(["channels", i], res)
      }
      textLabel(gui, column, CHANNEL_LABELS[i])

    })

    if (
      (res = ring(
        gui,
        row2,
        'bpm',
        30,
        180,
        1,
        state.bpm,
        PI,
        0.5,
        "BPM",
        F2
      )) !== undefined
    ) {
      node?.setParamValue(path('bpm'), res)
      DB.resetIn(["bpm"], res)
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
    updateGUI(false)
    updateGUI(true)
    // return hdom-canvas component with embedded GUI
    return [
      _canvas,
      {
        width,
        height,
        style: { background: gui.theme.globalBg, cursor: gui.cursor },
        oncontextmenu: (e: Event) => e.preventDefault(),
        ...gui.attribs
      },
      // IMGUI implements IToHiccup interface so just supply as is
      gui
    ]
  }
}

// main stream combinator
// the trigger() input is merely used to kick off the system
// once the 1st frame renders, the canvas component will create and attach
// event streams to this stream sync, which are then used to trigger future
// updates on demand...
const main = sync({
  src: {
    state: fromAtom(DB)
  }
})

// subscription & transformation of app state stream. uses a RAF
// sidechain to buffer intra-frame state updates. then only passes the
// most recent one to `app()` and its resulting UI tree to the
// `updateDOM()` transducer
sidechainPartitionRAF(main).transform(map(app()), updateDOM())
