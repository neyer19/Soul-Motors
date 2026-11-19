import { createRouter, createWebHistory } from 'vue-router'

import LoginView from '../views/LoginView.vue'
import AdminView from '../views/AdminView.vue'
import GerenteView from '../views/GerenteView.vue'
import InventarioView from '../views/InventarioView.vue'
import MecanicoView from '../views/MecanicoView.vue'
import TrabajadoresView from '../views/TrabajadoresView.vue'
import VendedorView from '../views/VendedorView.vue'

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: LoginView },
  { path: '/admin', component: AdminView },
  { path: '/finanzas', redirect: '/admin' }, // Finanzas es la sección inicial del Administrador
  { path: '/gerente', component: GerenteView },
  { path: '/inventario', component: InventarioView },
  { path: '/mecanico', component: MecanicoView },
  { path: '/trabajadores', component: TrabajadoresView },
  { path: '/vendedor', component: VendedorView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router