import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 8000
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: undefined,
      },
    },
  },
  publicDir: 'assets'
});