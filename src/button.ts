export default function button(
  el: HTMLButtonElement,
  update: (value: number) => void
) {
  const handlerDown = (ev: Event) => {
    update(1)
  }

  const handlerUp = (ev: Event) => {
    update(0)
  }

  el.addEventListener("mousedown", handlerDown)
  el.addEventListener("mouseup", handlerUp)

  return () => {
    el.removeEventListener("mousedown", handlerDown)
    el.removeEventListener("mouseup", handlerUp)
  }
}
