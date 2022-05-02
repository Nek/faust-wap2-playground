export default function oscilloscope(
  analyser: AnalyserNode,
  canvas: HTMLCanvasElement
) {
  let ctx = canvas.getContext("2d")!
  let timeDomain = new Uint8Array(analyser.fftSize)

  const draw = (
    ctx: CanvasRenderingContext2D,
    x0 = 0,
    y0 = 0,
    width = ctx.canvas.width - x0,
    height = ctx.canvas.height - y0
  ) => {
    analyser.getByteTimeDomainData(timeDomain)
    const step = width / timeDomain.length

    if (ctx) {
      ctx.beginPath()
      // drawing loop (skipping every second record)
      for (let i = 0; i < timeDomain.length; i += 2) {
        const percent = timeDomain[i] / 256
        const x = x0 + i * step
        const y = y0 + height * percent
        ctx.lineTo(x, y)
      }

      ctx.stroke()
    }
  }

  const loop = () => {
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
    draw(ctx, 0, 0, ctx.canvas.width, ctx.canvas.height)
    requestAnimationFrame(loop)
  }
  loop()
}
