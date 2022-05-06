import { defineConfig } from "vite"
import type { PluginOption } from "vite"

function DSPHotReload(): PluginOption {
  return {
    name: "dsp-hot-reload",
    handleHotUpdate({ file, server }) {
      if (file.endsWith(".wasm")) {
        console.log("DSP file updated")
        server.ws.send({
          type: "custom",
          event: "dsp-update"
        })
      }
    }
  }
}

export default defineConfig({
  plugins: [DSPHotReload()],
  server: {
    port: 8000
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: undefined
      }
    },
    minify: "esbuild",
    target: "esnext"
  },
  publicDir: "assets"
})
