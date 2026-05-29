import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api/auth-service': {
        target: 'http://127.0.0.1:8001',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/auth-service/, ''),
      },
      '/api/patient-service': {
        target: 'http://127.0.0.1:8002',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/patient-service/, ''),
      },
      '/api/appointment-service': {
        target: 'http://127.0.0.1:8003',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/appointment-service/, ''),
      },
      '/api/records-service': {
        target: 'http://127.0.0.1:8004',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/records-service/, ''),
      },
      '/api/pharmacy-service': {
        target: 'http://127.0.0.1:8005',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/pharmacy-service/, ''),
      },
      '/api/billing-service': {
        target: 'http://127.0.0.1:8006',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/billing-service/, ''),
      },
      '/api/notification-service': {
        target: 'http://127.0.0.1:8007',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/notification-service/, ''),
      },
    },
  },
})
