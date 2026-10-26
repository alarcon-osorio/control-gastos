import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.alarconosorio.gastos',
  appName: 'Gastos',
  webDir: 'dist/crud-usuarios/browser',
  server: {
    androidScheme: 'https',
  },
  ios: {
    contentInset: 'never',
    backgroundColor: '#0f172a',
  },
  plugins: {
    CapacitorUpdater: {
      autoUpdate: false,
      appReadyTimeout: 10000,
    },
  },
};

export default config;
