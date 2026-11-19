<template>
  <div class="pd-overlay" @click.self="$emit('close')">
    <div class="pd-card" role="dialog" aria-modal="true" :aria-label="product.name">
      <button class="pd-close" aria-label="Cerrar" @click="$emit('close')"><X :size="20" /></button>

      <div class="pd-media">
        <img :src="product.image" :alt="product.name" @error="onErr" />
      </div>

      <div class="pd-info">
        <span class="pd-crumb">Repuestos › {{ product.category }}</span>
        <h2>{{ product.name }}</h2>
        <p class="pd-code">Código {{ product.code }}</p>

        <div v-if="showPrice" class="pd-price">$ {{ formatCOP(product.price) }}</div>

        <div class="pd-stock">
          <span :class="['pd-badge', stockLevel(product.stock)]">{{ stockLabel(product.stock) }}</span>
          <strong>{{ product.stock }} de {{ product.maxStock }} unidades disponibles</strong>
        </div>
        <div class="pd-bar"><i :style="{ width: stockPct(product), background: stockColor(product.stock) }"></i></div>

        <p class="pd-desc">{{ product.description }}</p>

        <h4>Características</h4>
        <table class="pd-specs">
          <tbody>
            <tr v-for="row in rows" :key="row.label"><th>{{ row.label }}</th><td>{{ row.value }}</td></tr>
          </tbody>
        </table>

        <div v-if="$slots.actions" class="pd-actions"><slot name="actions" /></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted } from 'vue'
import { X } from 'lucide-vue-next'
import { stockLevel, stockLabel, stockColor, stockPct, formatCOP } from '../data/productos'

const props = defineProps({
  product: { type: Object, required: true },
  showPrice: { type: Boolean, default: true }
})
const emit = defineEmits(['close'])

const rows = computed(() => {
  const p = props.product
  const list = [
    { label: 'Categoría', value: p.category },
    { label: 'Compatibilidad', value: p.compat },
    ...(p.specs || []),
    { label: 'Ubicación en bodega', value: p.ubicacion },
    { label: 'Stock máximo', value: `${p.maxStock} unidades` }
  ]
  if (props.showPrice) {
    list.push({ label: 'Valor en bodega', value: `$ ${formatCOP(p.price * p.stock)}` })
    if (p.sold != null) list.push({ label: 'Unidades vendidas (mes)', value: String(p.sold) })
  }
  return list.filter(r => r.value)
})

const PLACEHOLDER = 'data:image/svg+xml;charset=UTF-8,%3Csvg xmlns="http://www.w3.org/2000/svg" width="120" height="120" viewBox="0 0 24 24" fill="none" stroke="%239DA5B4" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"%3E%3Cpath d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"%3E%3C/path%3E%3C/svg%3E'
const onErr = (e) => { e.target.src = PLACEHOLDER }
const onKey = (e) => { if (e.key === 'Escape') emit('close') }
onMounted(() => document.addEventListener('keydown', onKey))
onUnmounted(() => document.removeEventListener('keydown', onKey))
</script>

<style scoped>
.pd-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.65); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 130; padding: 16px; }
.pd-card { position: relative; background: var(--bg-card); color: var(--text-primary); border: 1px solid var(--border-color); border-radius: 20px; width: 1020px; max-width: 100%; max-height: 94vh; overflow-y: auto; display: grid; grid-template-columns: 1.05fr 1fr; animation: pd-in 0.2s ease; }
.pd-close { position: absolute; top: 14px; right: 14px; z-index: 2; background: var(--bg-card); border: 1px solid var(--border-color); color: var(--text-secondary); width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; }
.pd-close:hover { color: #E67E22; border-color: #E67E22; }
.pd-media { background: var(--input-bg); display: flex; align-items: center; justify-content: center; min-height: 420px; border-right: 1px solid var(--border-color); overflow: hidden; }
.pd-media img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.4s ease; }
.pd-media:hover img { transform: scale(1.06); }
.pd-info { padding: 32px 30px; display: flex; flex-direction: column; gap: 12px; }
.pd-crumb { font-size: 12px; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; font-weight: 700; }
.pd-info h2 { margin: 0; font-size: 26px; line-height: 1.2; padding-right: 36px; }
.pd-code { margin: 0; font-size: 13px; color: var(--text-secondary); }
.pd-price { font-size: 34px; font-weight: 800; color: #2ECC71; }
.pd-stock { display: flex; align-items: center; gap: 10px; font-size: 14px; flex-wrap: wrap; }
.pd-badge { font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; }
.pd-badge.danger { background: rgba(231, 76, 60, 0.15); color: #E74C3C; }
.pd-badge.warning { background: rgba(241, 196, 15, 0.15); color: #F1C40F; }
.pd-badge.success { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.pd-bar { height: 8px; border-radius: 999px; background: var(--border-color); overflow: hidden; }
.pd-bar i { display: block; height: 100%; border-radius: 999px; }
.pd-desc { margin: 4px 0 0; font-size: 14px; line-height: 1.55; color: var(--text-secondary); }
.pd-info h4 { margin: 8px 0 0; font-size: 15px; }
.pd-specs { width: 100%; border-collapse: collapse; font-size: 13px; }
.pd-specs th, .pd-specs td { padding: 9px 12px; text-align: left; border-bottom: 1px solid var(--border-color); }
.pd-specs th { width: 42%; color: var(--text-secondary); font-weight: 600; background: var(--input-bg); }
.pd-actions { display: flex; gap: 12px; margin-top: 10px; flex-wrap: wrap; }
@keyframes pd-in { from { transform: translateY(10px) scale(0.98); opacity: 0; } to { transform: none; opacity: 1; } }
@media (max-width: 800px) { .pd-card { grid-template-columns: 1fr; } .pd-media { min-height: 260px; border-right: none; border-bottom: 1px solid var(--border-color); } }
</style>
