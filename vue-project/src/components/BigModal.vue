<template>
  <div class="bm-overlay" @click.self="$emit('close')">
    <div :class="['bm-card', { wide }]" role="dialog" aria-modal="true" :aria-label="title">
      <header class="bm-head">
        <div class="bm-titles">
          <h3>{{ title }}</h3>
          <span v-if="subtitle">{{ subtitle }}</span>
        </div>
        <slot name="head-extra" />
        <button class="bm-close" aria-label="Cerrar" @click="$emit('close')"><X :size="20" /></button>
      </header>
      <div class="bm-body"><slot /></div>
      <footer v-if="$slots.footer" class="bm-foot"><slot name="footer" /></footer>
    </div>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted } from 'vue'
import { X } from 'lucide-vue-next'

defineProps({ title: String, subtitle: String, wide: Boolean })
const emit = defineEmits(['close'])
const onKey = (e) => { if (e.key === 'Escape') emit('close') }
onMounted(() => document.addEventListener('keydown', onKey))
onUnmounted(() => document.removeEventListener('keydown', onKey))
</script>

<style scoped>
.bm-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.6); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 130; padding: 16px; }
.bm-card { background: var(--bg-card); color: var(--text-primary); border: 1px solid var(--border-color); border-radius: 18px; width: 640px; max-width: 100%; max-height: 92vh; display: flex; flex-direction: column; overflow: hidden; animation: bm-in 0.2s ease; }
.bm-card.wide { width: 820px; }
.bm-head { display: flex; align-items: center; gap: 12px; padding: 20px 26px; border-bottom: 1px solid var(--border-color); }
.bm-titles { flex: 1; min-width: 0; }
.bm-titles h3 { margin: 0; font-size: 20px; }
.bm-titles span { font-size: 13px; color: var(--text-secondary); }
.bm-close { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; padding: 6px; border-radius: 8px; }
.bm-close:hover { color: var(--text-primary); background: var(--input-bg); }
.bm-body { padding: 24px 26px; overflow-y: auto; display: flex; flex-direction: column; gap: 16px; }
.bm-foot { padding: 16px 26px; border-top: 1px solid var(--border-color); display: flex; gap: 12px; justify-content: flex-end; flex-wrap: wrap; }
@keyframes bm-in { from { transform: translateY(10px) scale(0.98); opacity: 0; } to { transform: none; opacity: 1; } }
</style>
