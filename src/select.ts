export default function select(
  el: HTMLSelectElement,
  update: (value: number) => void,
) {
  const handler = (ev: Event) => {
    update(parseInt(el.value, 10))
  }

  el.addEventListener("input", handler)

  return () => el.removeEventListener("input", handler)
}
