import { bootstrapApplication } from '@angular/platform-browser';
import { CapacitorUpdater } from '@capgo/capacitor-updater';
import { appConfig } from './app/app.config';
import { App } from './app/app';

// Notifica al plugin que el bundle JS cargó correctamente (evita rollback).
void CapacitorUpdater.notifyAppReady().catch(() => {});

bootstrapApplication(App, appConfig).catch((err) => console.error(err));
