<template>
  <div v-if="view === 'list'" :class="['pc-list', { compact }]">
    <div
      v-for="p in items"
      :key="p.code"
      class="pc-row"
      tabindex="0"
      role="button"
      :aria-label="'Ver detalle de ' + p.name"
      @click="$emit('open', p)"
      @keydown.enter="$emit('open', p)"
    >
      <div class="pc-thumb"><img :src="p.image" :alt="p.name" loading="lazy" @error="onErr" /></div>
      <div class="pc-info">
        <span class="pc-cat">{{ p.category }}</span>
        <h3>{{ p.name }}</h3>
        <p>{{ p.code }}<template v-if="showPrice"> | <strong>$ {{ formatCOP(p.price) }}</strong></template></p>
      </div>
      <div class="pc-end">
        <span class="pc-stock">Stock: <b>{{ p.stock }}</b> de {{ p.maxStock }}</span>
        <span :class="['pc-badge', stockLevel(p.stock)]">{{ stockLabel(p.stock) }}</span>
        <button v-if="actionLabel" class="pc-action" :disabled="p.stock === 0" @click.stop="$emit('action', p)">
          <component :is="actionIcon" v-if="actionIcon" :size="14" />
          <span>{{ p.stock === 0 ? 'Sin stock' : actionLabel }}</span>
        </button>
      </div>
      <div class="pc-bar"><i :style="{ width: stockPct(p), background: stockColor(p.stock) }"></i></div>
    </div>
  </div>

  <div v-else :class="['pc-grid', { compact }]">
    <div
      v-for="p in items"
      :key="p.code"
      class="pc-card"
      tabindex="0"
      role="button"
      :aria-label="'Ver detalle de ' + p.name"
      @click="$emit('open', p)"
      @keydown.enter="$emit('open', p)"
    >
      <div class="pc-card-img">
        <img :src="p.image" :alt="p.name" loading="lazy" @error="onErr" />
        <span :class="['pc-flag', stockLevel(p.stock)]">{{ stockLabel(p.stock) }}</span>
      </div>
      <div class="pc-card-body">
        <span class="pc-cat">{{ p.category }}</span>
        <h3>{{ p.name }}</h3>
        <p class="pc-code">{{ p.code }}</p>
      </div>
      <div class="pc-card-foot">
        <span v-if="showPrice" class="pc-price">$ {{ formatCOP(p.price) }}</span>
        <span class="pc-stock">Stock: <b>{{ p.stock }}</b> de {{ p.maxStock }}</span>
      </div>
      <div v-if="actionLabel" class="pc-card-action">
        <button class="pc-action full" :disabled="p.stock === 0" @click.stop="$emit('action', p)">
          <component :is="actionIcon" v-if="actionIcon" :size="14" />
          <span>{{ p.stock === 0 ? 'Sin stock' : actionLabel }}</span>
        </button>
      </div>
      <div class="pc-bar"><i :style="{ width: stockPct(p), background: stockColor(p.stock) }"></i></div>
    </div>
  </div>
</template>

<script setup>
import { stockLevel, stockLabel, stockColor, stockPct, formatCOP } from '../data/productos'

defineProps({
  items: { type: Array, default: () => [] },
  view: { type: String, default: 'cards' },
  showPrice: { type: Boolean, default: true },
  actionLabel: { type: String, default: '' },
  actionIcon: { type: [Object, Function], default: null },
  compact: { type: Boolean, default: false }
})
defineEmits(['open', 'action'])

const PLACEHOLDER = 'data:image/svg+xml;charset=UTF-8,%3Csvg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="%239DA5B4" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"%3E%3Cpath d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"%3E%3C/path%3E%3C/svg%3E'
const onErr = (e) => { e.target.src = PLACEHOLDER }
</script>

<style scoped>
.pc-list { display: flex; flex-direction: column; gap: 14px; }
.pc-row { position: relative; display: flex; align-items: center; gap: 22px; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 16px; padding: 18px 24px 22px; overflow: hidden; cursor: pointer; transition: transform 0.2s, border-color 0.2s; }
.pc-row:hover { transform: translateX(4px); border-color: #E67E22; }
.pc-thumb { width: 118px; height: 118px; border-radius: 12px; overflow: hidden; background: var(--bg-card); border: 1px solid var(--border-color); flex-shrink: 0; }
.pc-thumb img { width: 100%; height: 100%; object-fit: cover; }
.pc-info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.pc-cat { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; }
.pc-info h3 { margin: 0; font-size: 20px; font-weight: 700; }
.pc-info p { margin: 0; font-size: 14px; color: var(--text-secondary); }
.pc-end { display: flex; flex-direction: column; align-items: flex-end; gap: 8px; flex-shrink: 0; }
.pc-stock { font-size: 15px; color: var(--text-secondary); }
.pc-stock b { color: var(--text-primary); font-size: 17px; }
.pc-badge, .pc-flag { font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; }
.pc-badge.danger { background: rgba(231, 76, 60, 0.15); color: #E74C3C; }
.pc-badge.warning { background: rgba(241, 196, 15, 0.15); color: #F1C40F; }
.pc-badge.success { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.pc-bar { position: absolute; left: 0; right: 0; bottom: 0; height: 6px; background: var(--border-color); }
.pc-bar i { display: block; height: 100%; transition: width 0.3s ease; }
.pc-action { background: rgba(230, 126, 34, 0.15); color: #E67E22; border: 1px solid #E67E22; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.2s; }
.pc-action:hover:not(:disabled) { background: #E67E22; color: #FFFFFF; }
.pc-action:disabled { opacity: 0.5; cursor: not-allowed; }
.pc-action.full { width: 100%; }

.pc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 22px; }
.pc-card { position: relative; display: flex; flex-direction: column; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 20px; overflow: hidden; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; }
.pc-card:hover { transform: translateY(-4px); box-shadow: 0 12px 26px rgba(0, 0, 0, 0.2); border-color: #E67E22; }
.pc-card-img { position: relative; height: 240px; background: var(--bg-card); overflow: hidden; border-bottom: 1px solid var(--border-color); }
.pc-card-img img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.35s ease; }
.pc-card:hover .pc-card-img img { transform: scale(1.05); }
.pc-flag { position: absolute; top: 12px; right: 12px; backdrop-filter: blur(4px); }
.pc-flag.danger { background: rgba(231, 76, 60, 0.92); color: #FFFFFF; }
.pc-flag.warning { background: rgba(241, 196, 15, 0.92); color: #1E1F22; }
.pc-flag.success { background: rgba(46, 204, 113, 0.92); color: #FFFFFF; }
.pc-card-body { padding: 18px 20px 6px; display: flex; flex-direction: column; gap: 5px; }
.pc-card-body h3 { margin: 0; font-size: 18px; font-weight: 700; line-height: 1.25; display: -webkit-box; -webkit-line-clamp: 2; line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.pc-code { margin: 0; font-size: 13px; color: var(--text-secondary); }
.pc-card-foot { display: flex; justify-content: space-between; align-items: center; padding: 10px 20px 20px; gap: 8px; }
.pc-price { font-size: 20px; font-weight: 800; color: #2ECC71; }
.pc-card-action { padding: 0 20px 22px; margin-top: -6px; }

.pc-list.compact .pc-row { padding: 10px 14px 14px; gap: 14px; border-radius: 12px; }
.pc-list.compact .pc-thumb { width: 64px; height: 64px; }
.pc-list.compact .pc-info h3 { font-size: 15px; }
.pc-list.compact .pc-info p { font-size: 12px; }
.pc-list.compact .pc-stock { font-size: 13px; }
.pc-list.compact .pc-stock b { font-size: 14px; }
.pc-list.compact .pc-bar { height: 4px; }
.pc-grid.compact { grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
.pc-grid.compact .pc-card-img { height: 120px; }
.pc-grid.compact .pc-card-body h3 { font-size: 14px; }
.pc-grid.compact .pc-price { font-size: 15px; }
@media (max-width: 768px) { .pc-row { flex-wrap: wrap; } .pc-end { width: 100%; flex-direction: row; align-items: center; justify-content: space-between; } }
</style>
