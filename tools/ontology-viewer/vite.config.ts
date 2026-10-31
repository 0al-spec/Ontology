import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: { outDir: process.env.ONTOLOGY_VIEWER_DIST || 'dist', emptyOutDir: false },
});
