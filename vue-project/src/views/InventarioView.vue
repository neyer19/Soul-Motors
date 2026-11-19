<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    activeKey="inventario"
    title="Control de Inventario"
    subtitle="Monitoreo de repuestos, stock crítico y métricas de bodega"
    @navigate="$emit('change-view', $event)"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <InventoryPanel :products="products" />
  </AppShell>
</template>

<script setup>
import { ref } from 'vue'
import { LayoutDashboard, Package, Users } from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
import InventoryPanel from '../components/InventoryPanel.vue'
import { getProducts } from '../data/productos'

defineProps({ isDarkMode: Boolean })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'gerente', label: 'Gerencia', icon: LayoutDashboard },
  { key: 'inventario', label: 'Inventario', icon: Package },
  { key: 'trabajadores', label: 'Trabajadores', icon: Users }
]
const products = ref(getProducts())
</script>
