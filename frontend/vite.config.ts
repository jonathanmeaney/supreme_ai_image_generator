import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: "/",
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://app:3000',
        changeOrigin: true,
        secure: false,
      },
    }
  },
  build: {
    outDir: '../public',
    emptyOutDir: false,
    assetsDir: 'assets'
  },
})
