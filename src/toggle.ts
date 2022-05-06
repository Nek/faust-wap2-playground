export default function toggle(id: string, update: (id: string, value: number) => void) {

  const el: HTMLInputElement = document.getElementById(id) as HTMLInputElement
  
  const handler = (ev: Event) => {
    update(id, el.checked ? 1 : 0)
  }

  el.addEventListener("input", handler)

  return () => el.removeEventListener("input", handler)
}
