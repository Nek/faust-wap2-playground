export default function select(
  el: HTMLSelectElement,
  update: (value: string) => void
) {
  const handler = (ev: Event) => {
    update(el.value)
  }

  el.addEventListener("input", handler)

  return () => el.removeEventListener("input", handler)
}
