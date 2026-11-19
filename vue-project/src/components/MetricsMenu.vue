<template>
  <div class="metrics-menu">
    <button :class="['menu-btn', { open }]" aria-label="Indicadores" title="Indicadores" aria-haspopup="true" :aria-expanded="open" @click.stop="open = !open">
      <Menu :size="18" />
    </button>

    <transition name="mm-pop">
      <div v-if="open" class="menu-dropdown" @click.stop>
        <p class="menu-title">Indicadores</p>
        <button v-for="it in items" :key="it.key" class="menu-item" @click="select(it.key)">
          <span :class="['menu-ico', 'tone-' + (it.tone || 'orange')]"><component :is="it.icon" :size="18" /></span>
          <span class="menu-text">
            <strong>{{ it.label }}</strong>
            <small v-if="it.value">{{ it.value }}</small>
          </span>
          <ChevronRight :size="16" class="menu-chev" />
        </button>
      </div>
    </transition>

    <div v-if="current" class="drawer-overlay" @click.self="active = null">
      <aside class="drawer" role="dialog" aria-modal="true" :aria-label="current.label">
        <header class="drawer-head">
          <span :class="['menu-ico', 'tone-' + (current.tone || 'orange')]"><component :is="current.icon" :size="20" /></span>
          <div class="drawer-titles">
            <h3>{{ current.label }}</h3>
            <p v-if="current.value">{{ current.value }}</p>
          </div>
          <button class="drawer-close" aria-label="Cerrar" @click="active = null"><X :size="18" /></button>
        </header>
        <div class="drawer-body">
          <slot :name="active" />
        </div>
      </aside>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { Menu, ChevronRight, X } from 'lucide-vue-next'

const props = defineProps({
  items: { type: Array, default: () => [] } // [{ key, label, value, icon, tone: orange|green|red|yellow|blue }]
})

const open = ref(false)
const active = ref(null)
const current = computed(() => props.items.find(i => i.key === active.value) || null)
const select = (key) => { active.value = key; open.value = false }

const closeDropdown = () => { open.value = false }
const onKey = (e) => { if (e.key === 'Escape') { open.value = false; active.value = null } }
onMounted(() => { document.addEventListener('click', closeDropdown); document.addEventListener('keydown', onKey) })
onUnmounted(() => { document.removeEventListener('click', closeDropdown); document.removeEventListener('keydown', onKey) })
</script>

<style scoped>
.metrics-menu { position: relative; display: inline-flex; }
.menu-btn { background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); width: 40px; height: 40px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; flex-shrink: 0; }
.menu-btn:hover, .menu-btn.open { border-color: #E67E22; color: #E67E22; background: rgba(230, 126, 34, 0.1); }
.menu-dropdown { position: absolute; top: 48px; left: 0; z-index: 60; width: 300px; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 14px; box-shadow: 0 12px 32px rgba(0, 0, 0, 0.35); padding: 8px; display: flex; flex-direction: column; gap: 4px; }
.menu-title { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin: 6px 8px 4px; }
.menu-item { background: transparent; border: none; color: var(--text-primary); display: flex; align-items: center; gap: 12px; padding: 10px; border-radius: 10px; cursor: pointer; text-align: left; font: inherit; transition: background-color 0.2s; }
.menu-item:hover { background: rgba(230, 126, 34, 0.12); }
.menu-ico { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.tone-orange { background: rgba(230, 126, 34, 0.14); color: #E67E22; }
.tone-green { background: rgba(46, 204, 113, 0.14); color: #2ECC71; }
.tone-red { background: rgba(231, 76, 60, 0.14); color: #E74C3C; }
.tone-yellow { background: rgba(241, 196, 15, 0.14); color: #F1C40F; }
.tone-blue { background: rgba(52, 152, 219, 0.14); color: #3498DB; }
.menu-text { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.menu-text strong { font-size: 14px; }
.menu-text small { font-size: 12px; color: var(--text-secondary); }
.menu-chev { color: var(--text-secondary); }
.drawer-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.55); backdrop-filter: blur(3px); z-index: 120; display: flex; justify-content: flex-end; }
.drawer { width: min(780px, 100%); height: 100%; background: var(--bg-card); border-left: 1px solid var(--border-color); display: flex; flex-direction: column; animation: mm-slide 0.25s ease; }
.drawer-head { display: flex; align-items: center; gap: 14px; padding: 20px 24px; border-bottom: 1px solid var(--border-color); }
.drawer-titles { flex: 1; min-width: 0; }
.drawer-titles h3 { margin: 0; font-size: 18px; }
.drawer-titles p { margin: 2px 0 0; font-size: 12px; color: var(--text-secondary); }
.drawer-close { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; padding: 6px; border-radius: 8px; }
.drawer-close:hover { color: var(--text-primary); background: var(--input-bg); }
.drawer-body { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 18px; }
.mm-pop-enter-active, .mm-pop-leave-active { transition: opacity 0.15s, transform 0.15s; }
.mm-pop-enter-from, .mm-pop-leave-to { opacity: 0; transform: translateY(-6px); }
@keyframes mm-slide { from { transform: translateX(40px); opacity: 0; } to { transform: none; opacity: 1; } }
</style>

<!-- Utilidades compartidas para el contenido de los paneles (prefijo mm-) -->
<style>
.mm-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; }
.mm-stat { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px; }
.mm-stat span { display: block; font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.4px; }
.mm-stat strong { display: block; font-size: 22px; margin-top: 4px; }
.mm-green { color: #2ECC71; } .mm-red { color: #E74C3C; } .mm-yellow { color: #F1C40F; } .mm-orange { color: #E67E22; } .mm-blue { color: #3498DB; }
.mm-toolbar { display: flex; flex-wrap: wrap; gap: 12px; align-items: flex-end; }
.mm-field { display: flex; flex-direction: column; gap: 4px; min-width: 160px; flex: 1; }
.mm-field > label { font-size: 11px; font-weight: 700; color: var(--text-secondary); }
.mm-select { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 9px 12px; color: var(--text-primary); font-size: 13px; outline: none; font-family: inherit; }
.mm-select:focus { border-color: #E67E22; }
.mm-seg { display: flex; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 3px; gap: 3px; }
.mm-seg button { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 7px; font-size: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; }
.mm-seg button:hover { color: #E67E22; }
.mm-seg button.active { background: #E67E22; color: #FFFFFF; }
.mm-section-title { font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin: 0; }
.mm-list { display: flex; flex-direction: column; gap: 10px; }
.mm-row { display: flex; align-items: center; gap: 14px; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 12px 14px; position: relative; overflow: hidden; text-align: left; color: var(--text-primary); width: 100%; font: inherit; box-sizing: border-box; }
button.mm-row { cursor: pointer; transition: border-color 0.2s; }
button.mm-row:hover { border-color: #E67E22; }
.mm-row-main { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.mm-row-main strong { font-size: 14px; }
.mm-row-main small { font-size: 12px; color: var(--text-secondary); }
.mm-row-end { font-weight: 700; font-size: 14px; white-space: nowrap; text-align: right; display: flex; flex-direction: column; gap: 2px; align-items: flex-end; }
.mm-row-end small { font-size: 11px; font-weight: 600; color: var(--text-secondary); }
.mm-bar { height: 8px; border-radius: 999px; background: var(--border-color); overflow: hidden; }
.mm-bar i { display: block; height: 100%; border-radius: 999px; transition: width 0.4s ease; }
.mm-avatar { width: 40px; height: 40px; border-radius: 10px; background: rgba(230, 126, 34, 0.15); color: #E67E22; font-weight: 700; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.mm-tag { font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 6px; white-space: nowrap; }
.mm-tag.danger { background: rgba(231, 76, 60, 0.15); color: #E74C3C; }
.mm-tag.warning { background: rgba(241, 196, 15, 0.15); color: #F1C40F; }
.mm-tag.success { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.mm-tag.info { background: rgba(52, 152, 219, 0.15); color: #3498DB; }
.mm-empty { font-size: 13px; color: var(--text-secondary); text-align: center; padding: 24px 0; margin: 0; }
.mm-mini-bar { position: absolute; left: 0; right: 0; bottom: 0; height: 4px; background: var(--border-color); }
.mm-mini-bar i { display: block; height: 100%; }
</style>
