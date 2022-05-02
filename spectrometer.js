export default function spectrometer(analyser, canvas, options = {}) {
  const {
    INCREMENT_PER_FRAME = 1,
    COLOR_GAIN = 19,
    BASE_COLOR_HUE = 120
  } = options

  const ctx = canvas.getContext("2d")

  const bufferLength = analyser.frequencyBinCount
  const floatFrequencyData = new Float32Array(bufferLength)

  const canvasHeight = canvas.height
  const canvasWidth = canvas.width
  const canvasHeightUnit = canvasHeight / bufferLength

  const loop = () => {
    analyser.getFloatFrequencyData(floatFrequencyData)

    for (let i = 0; i < bufferLength; i++) {
      const output = Math.pow(1.8, floatFrequencyData[i] / COLOR_GAIN)
      const colorShift = +BASE_COLOR_HUE + i / 3

      ctx.fillStyle = `hsl(${360 * -output + colorShift}deg, 100%, ${
        output * 100
      }%)`
      ctx.fillRect(
        canvasWidth - INCREMENT_PER_FRAME,
        -i * canvasHeightUnit + canvasHeight,
        INCREMENT_PER_FRAME,
        canvasHeightUnit
      )
    }

    ctx.save()
    ctx.translate(-INCREMENT_PER_FRAME, 0)
    ctx.drawImage(canvas, 0, 0)
    ctx.restore()

    requestAnimationFrame(loop)
  }
  loop()
}
