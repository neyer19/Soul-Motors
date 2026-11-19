<template>
  <div :class="['dashboard-layout', isDarkMode ? 'dark-theme' : 'light-theme']">
    <aside :class="['sidebar', { collapsed }]">
      <div class="sidebar-top">
        <div class="sidebar-logo">
          <BrandLogo :isDarkMode="isDarkMode" :height="collapsed ? 40 : 88" />
        </div>
        <nav class="sidebar-nav">
          <button
            v-for="item in navItems"
            :key="item.key"
            :class="['nav-item', { active: item.key === activeKey }]"
            :title="item.label"
            @click="$emit('navigate', item.key)"
          >
            <component :is="item.icon" :size="18" class="nav-icon" />
            <span v-if="!collapsed" class="nav-text">{{ item.label }}</span>
          </button>
        </nav>
      </div>

      <div class="sidebar-footer">
        <button class="btn-signout" title="Salir" @click="$emit('logout')">
          <LogOut :size="16" />
          <span v-if="!collapsed">Salir</span>
        </button>
      </div>
    </aside>

    <main class="main-content">
      <header class="top-header">
        <div class="header-left-group">
          <button class="btn-toggle-sidebar" @click="toggle" aria-label="Alternar menú lateral">
            <Menu :size="18" />
          </button>
          <div class="header-title">
            <h1>{{ title }}</h1>
            <p>{{ subtitle }}</p>
          </div>
        </div>

        <div class="header-actions-right">
          <slot name="header-extra" />
          <div class="top-widget-bar">
            <div class="time-box">
              <Clock :size="16" />
              <span class="current-time">{{ currentTime }}</span>
            </div>
          </div>
          <button class="theme-toggle-btn" @click="$emit('toggle-theme')">
            <Sun v-if="isDarkMode" :size="16" />
            <Moon v-else :size="16" />
            <span>{{ isDarkMode ? 'Claro' : 'Oscuro' }}</span>
          </button>
        </div>
      </header>

      <slot />
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { Menu, Clock, LogOut, Sun, Moon } from 'lucide-vue-next'
import BrandLogo from './BrandLogo.vue'

defineProps({
  isDarkMode: Boolean,
  navItems: { type: Array, default: () => [] }, // [{ key, label, icon }]
  activeKey: { type: String, default: '' },
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' }
})
defineEmits(['navigate', 'toggle-theme', 'logout'])

const collapsed = ref(localStorage.getItem('soul_sidebar_collapsed') === 'true')
const toggle = () => {
  collapsed.value = !collapsed.value
  localStorage.setItem('soul_sidebar_collapsed', collapsed.value)
}

const currentTime = ref('')
let timer = null
const tick = () => { currentTime.value = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }
onMounted(() => { tick(); timer = setInterval(tick, 1000) })
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.dashboard-layout { display: flex; min-height: 100vh; background-color: var(--bg-main); color: var(--text-primary); font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; transition: background-color 0.3s ease; }
.sidebar { width: 240px; flex-shrink: 0; background-color: var(--bg-sidebar); border-right: 1px solid var(--border-color); display: flex; flex-direction: column; justify-content: space-between; padding-bottom: 20px; transition: width 0.3s ease; }
.sidebar.collapsed { width: 76px; }
.sidebar-logo { padding: 22px 12px; display: flex; justify-content: center; align-items: center; border-bottom: 1px solid var(--border-color); }
.sidebar-nav { padding: 16px 10px; display: flex; flex-direction: column; gap: 8px; }
.nav-item { background: transparent; border: none; display: flex; align-items: center; gap: 12px; padding: 12px 14px; color: var(--text-secondary); border-radius: 12px; font-size: 14px; cursor: pointer; transition: all 0.2s; width: 100%; text-align: left; white-space: nowrap; overflow: hidden; }
.nav-item:hover, .nav-item.active { background-color: rgba(230, 126, 34, 0.15); color: #E67E22; }
.sidebar-footer { padding: 0 12px; }
.btn-signout { width: 100%; background-color: rgba(231, 76, 60, 0.1); color: #E74C3C; border: 1px solid #E74C3C; padding: 10px; border-radius: 12px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 8px; white-space: nowrap; overflow: hidden; transition: background-color 0.2s; }
.btn-signout:hover { background-color: rgba(231, 76, 60, 0.2); }
.main-content { flex: 1; min-width: 0; padding: 30px; display: flex; flex-direction: column; gap: 24px; overflow-y: auto; }
.top-header { display: flex; justify-content: space-between; align-items: center; background-color: var(--bg-card); padding: 16px 24px; border-radius: 16px; border: 1px solid var(--border-color); gap: 16px; }
.header-left-group { display: flex; align-items: center; gap: 16px; }
.btn-toggle-sidebar { background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); width: 38px; height: 38px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: border-color 0.2s, color 0.2s; }
.btn-toggle-sidebar:hover { border-color: #E67E22; color: #E67E22; }
.header-title h1 { font-size: 18px; font-weight: 600; margin: 0; }
.header-title p { font-size: 12px; color: var(--text-secondary); margin: 2px 0 0 0; }
.header-actions-right { display: flex; align-items: center; gap: 15px; }
.top-widget-bar { display: flex; align-items: center; background-color: var(--input-bg); border: 1px solid var(--border-color); padding: 6px 16px; border-radius: 12px; }
.time-box { display: flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 700; color: #E67E22; }
.theme-toggle-btn { background-color: rgba(230, 126, 34, 0.1); color: #E67E22; border: 1px solid #E67E22; padding: 8px 14px; border-radius: 12px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; white-space: nowrap; transition: background-color 0.2s; }
.theme-toggle-btn:hover { background-color: rgba(230, 126, 34, 0.2); }
@media print {
  .sidebar, .btn-toggle-sidebar, .theme-toggle-btn { display: none !important; }
  .dashboard-layout { background: #FFFFFF !important; color: #000000 !important; }
  .main-content { padding: 0 !important; width: 100% !important; overflow: visible !important; }
  .top-header { border: none !important; background: transparent !important; }
}
:focus-visible { outline: 2px solid #E67E22; outline-offset: 2px; }
@media (max-width: 768px) { .top-header { flex-wrap: wrap; } .main-content { padding: 16px; } }
</style>
