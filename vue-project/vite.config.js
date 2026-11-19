import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    host: true, // Habilita el acceso externo (Local Network / Tunnels)
    port: 5173, // Puerto predeterminado de Vite
    allowedHosts: true // Permite conexiones desde cualquier túnel como localtunnel o ngrok
  }
})