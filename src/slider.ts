type SliderOptions = {
  min: number
  max: number
  init: number
  step: number
}

export default function slider(
  el: HTMLInputElement,
  update: (value: number) => void,
  options?: SliderOptions
) {
  const { min = 0, max = 120, init = 60, step = 1 } = options || {}
  el.min = min.toString(10)
  el.max = max.toString(10)
  el.value = init.toString(10)
  el.step = step.toString(10)

  const handler = (ev: Event) => {
    update(el.valueAsNumber)
  }

  el.addEventListener("change", handler)

  return () => el.removeEventListener("change", handler)
}
