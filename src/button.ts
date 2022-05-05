export default function button(
  el: HTMLButtonElement,
  update: (value: number) => void,
) {
  el.addEventListener("mousedown", (ev: Event) => {
    update(1)
  })
  el.addEventListener("mouseup", (ev: Event) => {
    update(0)
  })
}
