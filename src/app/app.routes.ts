import { Routes } from '@angular/router';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import('./pages/login/login').then((m) => m.Login),
  },
  {
    path: '',
    loadComponent: () => import('./layout/layout').then((m) => m.Layout),
    canActivate: [authGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./pages/dashboard/dashboard').then((m) => m.Dashboard),
      },
      {
        path: 'presupuesto',
        loadComponent: () =>
          import('./pages/dashboard/presupuesto-config').then((m) => m.PresupuestoConfigComponent),
      },
      {
        path: 'gastos',
        loadComponent: () =>
          import('./pages/gastos/gastos').then((m) => m.Gastos),
      },
      {
        path: 'gastos/nuevo',
        loadComponent: () =>
          import('./pages/gasto-form/gasto-form').then((m) => m.GastoForm),
      },
      {
        path: 'gastos/editar/:id',
        loadComponent: () =>
          import('./pages/gasto-form/gasto-form').then((m) => m.GastoForm),
      },
      {
        path: 'obligaciones',
        loadComponent: () =>
          import('./pages/obligaciones/obligaciones').then((m) => m.Obligaciones),
      },
      {
        path: 'parametros',
        loadComponent: () =>
          import('./pages/parametros/parametros').then((m) => m.Parametros),
      },
    ],
  },
  { path: '**', redirectTo: 'dashboard' },
];
