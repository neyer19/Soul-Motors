<template>
  <MetricsMenu :items="menuItems">
    <template #total>
      <div class="mm-stats">
        <div class="mm-stat"><span>Colaboradores</span><strong>{{ workers.length }}</strong></div>
        <div class="mm-stat"><span>Cargos distintos</span><strong class="mm-orange">{{ roleGroups.length }}</strong></div>
      </div>
      <div class="mm-toolbar">
        <div class="mm-field">
          <label>Ordenar trabajadores por</label>
          <select v-model="sortKey" class="mm-select">
            <option value="recent">Más recientes</option>
            <option value="oldest">Más antiguos</option>
            <option value="hours-desc">Más horas trabajadas</option>
            <option value="hours-asc">Menos horas trabajadas</option>
            <option value="name">Nombre (A–Z)</option>
            <option value="role">Cargo (A–Z)</option>
          </select>
        </div>
        <div class="mm-field">
          <label>Cargo</label>
          <select v-model="roleFilter" class="mm-select">
            <option value="">Todos los cargos</option>
            <option v-for="r in roleGroups" :key="r.role" :value="r.role">{{ r.role }}</option>
          </select>
        </div>
      </div>
      <div class="mm-list">
        <button v-for="w in sortedWorkers" :key="w.id" class="mm-row" @click="$emit('open-worker', w)">
          <span class="mm-avatar">{{ initials(w.name) }}</span>
          <div class="mm-row-main"><strong>{{ w.name }}</strong><small>{{ w.role }} · Ingreso {{ fmtDate(w.ingreso) }}</small></div>
          <div class="mm-row-end">{{ w.horas }} h<small>por semana</small></div>
        </button>
      </div>
      <p v-if="!sortedWorkers.length" class="mm-empty">No hay trabajadores con ese cargo.</p>
    </template>

    <template #cargos>
      <div class="mm-stats">
        <div class="mm-stat"><span>Cargos</span><strong>{{ roleGroups.length }}</strong></div>
        <div class="mm-stat"><span>Cargo con más personal</span><strong class="mm-orange" style="font-size:15px">{{ roleGroups[0] ? roleGroups[0].role : '—' }}</strong></div>
      </div>
      <h4 class="mm-section-title">Distribución del equipo</h4>
      <div class="mm-list">
        <div v-for="r in roleGroups" :key="r.role" class="mm-row">
          <div class="mm-row-main">
            <strong>{{ r.role }}</strong>
            <small>{{ r.names.join(', ') }}</small>
            <div class="mm-bar"><i :style="{ width: r.pct + '%', background: '#E67E22' }"></i></div>
          </div>
          <div class="mm-row-end">{{ r.count }} {{ r.count === 1 ? 'persona' : 'personas' }}<small>{{ r.pct }}% · prom. {{ r.avg }} h</small></div>
        </div>
      </div>
    </template>

    <template #horas>
      <div class="mm-stats">
        <div class="mm-stat"><span>Promedio</span><strong class="mm-orange">{{ avgHours }} h</strong></div>
        <div class="mm-stat"><span>Máximo</span><strong>{{ maxHours }} h</strong></div>
        <div class="mm-stat"><span>Mínimo</span><strong>{{ minHours }} h</strong></div>
        <div class="mm-stat"><span>Horas del equipo</span><strong>{{ totalHours }} h</strong></div>
      </div>
      <h4 class="mm-section-title">Horas semanales por trabajador</h4>
      <div class="mm-list">
        <div v-for="w in byHours" :key="w.id" class="mm-row">
          <span class="mm-avatar">{{ initials(w.name) }}</span>
          <div class="mm-row-main">
            <strong>{{ w.name }}</strong>
            <div class="mm-bar"><i :style="{ width: Math.min(100, (w.horas / scaleMax) * 100) + '%', background: w.horas > avgHours ? '#E67E22' : '#3498DB' }"></i></div>
          </div>
          <div class="mm-row-end">{{ w.horas }} h<small>{{ w.horas > avgHours ? 'Sobre el promedio' : w.horas < avgHours ? 'Bajo el promedio' : 'En el promedio' }}</small></div>
        </div>
      </div>
    </template>
  </MetricsMenu>
</template>

<script setup>
import { ref, computed } from 'vue'
import { Users, Briefcase, Clock } from 'lucide-vue-next'
import MetricsMenu from './MetricsMenu.vue'

const props = defineProps({ workers: { type: Array, default: () => [] } }) // { id, name, role, cedula, horas, telefono, ingreso }
defineEmits(['open-worker'])

const sortKey = ref('recent')
const roleFilter = ref('')

const initials = (n) => n.split(' ').filter(Boolean).slice(0, 2).map(w => w[0].toUpperCase()).join('')
const fmtDate = (iso) => (iso ? new Date(iso + 'T00:00:00').toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' }) : '—')

const sorters = {
  recent: (a, b) => (b.ingreso || '').localeCompare(a.ingreso || ''),
  oldest: (a, b) => (a.ingreso || '').localeCompare(b.ingreso || ''),
  'hours-desc': (a, b) => b.horas - a.horas,
  'hours-asc': (a, b) => a.horas - b.horas,
  name: (a, b) => a.name.localeCompare(b.name),
  role: (a, b) => a.role.localeCompare(b.role) || a.name.localeCompare(b.name)
}
const sortedWorkers = computed(() => {
  const list = roleFilter.value ? props.workers.filter(w => w.role === roleFilter.value) : props.workers
  return [...list].sort(sorters[sortKey.value])
})

const roleGroups = computed(() => {
  const map = {}
  props.workers.forEach(w => { (map[w.role] = map[w.role] || []).push(w) })
  const total = props.workers.length || 1
  return Object.entries(map)
    .map(([role, list]) => ({
      role, count: list.length, names: list.map(w => w.name),
      pct: Math.round((list.length / total) * 100),
      avg: Math.round(list.reduce((a, w) => a + Number(w.horas || 0), 0) / list.length)
    }))
    .sort((a, b) => b.count - a.count || a.role.localeCompare(b.role))
})

const hoursList = computed(() => props.workers.map(w => Number(w.horas || 0)))
const totalHours = computed(() => hoursList.value.reduce((a, b) => a + b, 0))
const avgHours = computed(() => (props.workers.length ? Math.round(totalHours.value / props.workers.length) : 0))
const maxHours = computed(() => (hoursList.value.length ? Math.max(...hoursList.value) : 0))
const minHours = computed(() => (hoursList.value.length ? Math.min(...hoursList.value) : 0))
const scaleMax = computed(() => Math.max(60, maxHours.value))
const byHours = computed(() => [...props.workers].sort((a, b) => b.horas - a.horas))

const menuItems = computed(() => [
  { key: 'total', label: 'Total de trabajadores', value: `${props.workers.length} colaboradores`, icon: Users, tone: 'orange' },
  { key: 'cargos', label: 'Personal por cargo', value: `${roleGroups.value.length} cargos`, icon: Briefcase, tone: 'blue' },
  { key: 'horas', label: 'Promedio de horas / semana', value: `${avgHours.value} horas`, icon: Clock, tone: 'yellow' }
])
</script>
