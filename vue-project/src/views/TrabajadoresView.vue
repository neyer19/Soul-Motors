<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    activeKey="trabajadores"
    title="Gestión de Trabajadores"
    subtitle="Control de personal, técnicos y personal de taller"
    @navigate="$emit('change-view', $event)"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <section class="card display-section">
      <!-- Encabezado y Barra de Herramientas alineados correctamente -->
      <div class="card-header-flex">
        <div class="header-titles-group">
          <h3>Nómina y Equipo Activo</h3>
          <p>Listado de colaboradores registrados con opciones de consulta y modificación</p>
        </div>

        <div class="controls-right-group">
          <div class="search-box-wrapper">
            <Search :size="16" class="search-icon-input" />
            <input v-model="searchQuery" type="text" placeholder="Buscar trabajador..." class="search-input" />
          </div>
        </div>
      </div>

      <!-- Métricas secundarias opcionales si ya creaste el componente -->
      <div class="workers-metrics-wrap" v-if="hasWorkersMetrics">
        <WorkersMetrics :workers="workersData" @open-worker="openConsultModal" />
      </div>

      <p v-if="!filteredWorkers.length" class="empty-state">No hay trabajadores que coincidan con la búsqueda.</p>

      <!-- Tarjetas de Trabajadores -->
      <div class="workers-grid">
        <div v-for="worker in filteredWorkers" :key="worker.id" class="worker-card">
          <div class="worker-card-header">
            <div class="worker-avatar-box"><Users :size="20" /></div>
            <div class="worker-main-titles">
              <h4>{{ worker.name }}</h4>
              <span class="worker-role-badge">{{ worker.role }}</span>
            </div>

            <div class="dropdown-wrapper">
              <button class="gear-btn" aria-label="Opciones" @click.stop="toggleMenu(worker.id)"><Settings :size="18" /></button>
              <div v-if="activeMenuId === worker.id" class="dropdown-menu" @click.stop>
                <button class="dropdown-item" @click="openConsultModal(worker)"><Eye :size="14" /><span>Consultar Trabajador</span></button>
                <button class="dropdown-item" @click="openEditModal(worker)"><Edit3 :size="14" /><span>Modificar Trabajador</span></button>
              </div>
            </div>
          </div>

          <div class="worker-card-body">
            <div class="worker-info-row"><span>Cédula:</span><strong>{{ worker.cedula }}</strong></div>
            <div class="worker-info-row"><span>Horas Laborales:</span><strong>{{ worker.horas }} hrs / semana</strong></div>
            <div class="worker-info-row"><span>Teléfono:</span><strong>{{ worker.telefono }}</strong></div>
          </div>
        </div>
      </div>
    </section>

    <!-- MODAL DE CONSULTA -->
    <div v-if="showConsultModal" class="modal-overlay" @click.self="showConsultModal = false">
      <div class="modal-card">
        <div class="modal-header">
          <h3>Detalles del Trabajador</h3>
          <button class="close-btn" aria-label="Cerrar" @click="showConsultModal = false"><X :size="18" /></button>
        </div>
        <div v-if="selectedWorker" class="modal-body">
          <div class="detail-group"><span>Nombre Completo:</span><strong>{{ selectedWorker.name }}</strong></div>
          <div class="detail-group"><span>Cargo / Rol:</span><strong>{{ selectedWorker.role }}</strong></div>
          <div class="detail-group"><span>Número de Cédula:</span><strong>{{ selectedWorker.cedula }}</strong></div>
          <div class="detail-group"><span>Horas Laborales:</span><strong>{{ selectedWorker.horas }} horas semanales</strong></div>
          <div class="detail-group"><span>Teléfono de Contacto:</span><strong>{{ selectedWorker.telefono }}</strong></div>
          <div class="detail-group"><span>Fecha de Ingreso:</span><strong>{{ fmtDate(selectedWorker.ingreso) }}</strong></div>
          <div class="detail-group"><span>Estado Actual:</span><strong class="text-success">Activo en Taller</strong></div>
        </div>
      </div>
    </div>

    <!-- MODAL DE MODIFICACIÓN -->
    <div v-if="showEditModal" class="modal-overlay" @click.self="showEditModal = false">
      <div class="modal-card">
        <div class="modal-header">
          <h3>Modificar Datos del Trabajador</h3>
          <button class="close-btn" aria-label="Cerrar" @click="showEditModal = false"><X :size="18" /></button>
        </div>
        <div v-if="editForm" class="modal-body">
          <div class="form-group"><label>Nombre Completo</label><input v-model="editForm.name" type="text" class="form-input" /></div>
          <div class="form-group"><label>Cargo / Rol</label><input v-model="editForm.role" type="text" class="form-input" /></div>
          <div class="form-group"><label>Horas Laborales (Semanales)</label><input v-model.number="editForm.horas" type="number" class="form-input" /></div>
          <div class="form-group"><label>Teléfono</label><input v-model="editForm.telefono" type="text" class="form-input" /></div>
          <button class="btn-save" @click="saveChanges">Guardar Cambios</button>
        </div>
      </div>
    </div>
  </AppShell>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { LayoutDashboard, Package, Users, Search, Settings, Eye, Edit3, X } from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
// Nota: Si no usas WorkersMetrics como componente separado, puedes omitirlo o asegurarte de tenerlo.
import WorkersMetrics from '../components/WorkersMetrics.vue'

defineProps({ isDarkMode: Boolean })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'gerente', label: 'Gerencia', icon: LayoutDashboard },
  { key: 'inventario', label: 'Inventario', icon: Package },
  { key: 'trabajadores', label: 'Trabajadores', icon: Users }
]

const searchQuery = ref('')
const activeMenuId = ref(null)
const showConsultModal = ref(false)
const showEditModal = ref(false)
const selectedWorker = ref(null)
const editForm = ref(null)

// Control de existencia del componente de métricas para evitar errores si no está creado
const hasWorkersMetrics = ref(false) 

const closeMenus = () => { activeMenuId.value = null }
onMounted(() => document.addEventListener('click', closeMenus))
onUnmounted(() => document.removeEventListener('click', closeMenus))

const fmtDate = (iso) => (iso ? new Date(iso + 'T00:00:00').toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' }) : '—')

const workersData = ref([
  { id: 1, name: 'Carlos Mendoza', role: 'Mecánico Líder', cedula: '1023456789', horas: 48, telefono: '3104567890', ingreso: '2022-03-14' },
  { id: 2, name: 'Andrés Parra', role: 'Mecánico Especialista', cedula: '1098765432', horas: 48, telefono: '3209876541', ingreso: '2023-07-01' },
  { id: 3, name: 'Mateo Rojas', role: 'Ayudante de Taller', cedula: '1034567812', horas: 40, telefono: '3156781234', ingreso: '2024-09-16' },
  { id: 4, name: 'Sofía Gomez', role: 'Jefe de Bodega', cedula: '1012345678', horas: 48, telefono: '3123456789', ingreso: '2021-11-08' }
])

const filteredWorkers = computed(() => {
  if (!searchQuery.value) return workersData.value
  const q = searchQuery.value.toLowerCase()
  return workersData.value.filter(w => w.name.toLowerCase().includes(q) || w.role.toLowerCase().includes(q) || w.cedula.includes(q))
})

const toggleMenu = (id) => { activeMenuId.value = activeMenuId.value === id ? null : id }
const openConsultModal = (worker) => { selectedWorker.value = worker; showConsultModal.value = true; activeMenuId.value = null }
const openEditModal = (worker) => { editForm.value = { ...worker }; showEditModal.value = true; activeMenuId.value = null }
const saveChanges = () => {
  const index = workersData.value.findIndex(w => w.id === editForm.value.id)
  if (index !== -1) workersData.value[index] = { ...editForm.value }
  showEditModal.value = false
  alert('¡Datos del trabajador actualizados con éxito!')
}
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; }
.text-success { color: #2ECC71; }
.display-section { display: flex; flex-direction: column; gap: 20px; }
.card-header-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 16px; }
.header-titles-group h3 { font-size: 18px; font-weight: 600; margin: 0 0 4px 0; }
.header-titles-group p { font-size: 13px; color: var(--text-secondary); margin: 0; }
.controls-right-group { display: flex; align-items: center; gap: 12px; }
.search-box-wrapper { position: relative; display: flex; align-items: center; }
.search-icon-input { position: absolute; left: 12px; color: var(--text-secondary); }
.search-input { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 8px 14px 8px 36px; color: var(--text-primary); font-size: 13px; outline: none; width: 240px; height: 40px; box-sizing: border-box; }
.search-input:focus { border-color: #E67E22; }
.empty-state { font-size: 13px; color: var(--text-secondary); margin: 0; }

.workers-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
.worker-card { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 16px; display: flex; flex-direction: column; gap: 12px; position: relative; }
.worker-card-header { display: flex; align-items: center; gap: 12px; position: relative; }
.worker-avatar-box { background: rgba(230, 126, 34, 0.1); color: #E67E22; width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.worker-main-titles { flex: 1; }
.worker-main-titles h4 { font-size: 14px; font-weight: 700; margin: 0 0 4px; }
.worker-role-badge { font-size: 10px; color: #E67E22; font-weight: 600; background: rgba(230, 126, 34, 0.1); padding: 2px 6px; border-radius: 4px; }
.gear-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; padding: 4px; border-radius: 6px; display: flex; align-items: center; justify-content: center; }
.gear-btn:hover { color: #E67E22; background: rgba(230, 126, 34, 0.1); }
.dropdown-wrapper { position: relative; }
.dropdown-menu { position: absolute; right: 0; top: 28px; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.2); z-index: 10; width: 190px; display: flex; flex-direction: column; padding: 4px; }
.dropdown-item { background: transparent; border: none; color: var(--text-primary); padding: 8px 12px; font-size: 12px; display: flex; align-items: center; gap: 8px; cursor: pointer; text-align: left; border-radius: 6px; }
.dropdown-item:hover { background: rgba(230, 126, 34, 0.15); color: #E67E22; }
.worker-card-body { border-top: 1px solid var(--border-color); padding-top: 10px; display: flex; flex-direction: column; gap: 6px; }
.worker-info-row { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-secondary); }
.worker-info-row strong { color: var(--text-primary); }

.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal-card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; width: 400px; max-width: 100%; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.modal-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
.modal-header h3 { font-size: 16px; margin: 0; font-weight: 600; }
.close-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; }
.modal-body { display: flex; flex-direction: column; gap: 12px; }
.detail-group { display: flex; justify-content: space-between; font-size: 13px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; color: var(--text-secondary); }
.detail-group strong { color: var(--text-primary); }
.form-group { display: flex; flex-direction: column; gap: 4px; }
.form-group label { font-size: 11px; font-weight: 700; color: var(--text-secondary); }
.form-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 8px 12px; color: var(--text-primary); font-size: 13px; outline: none; }
.form-input:focus { border-color: #E67E22; }
.btn-save { background: #E67E22; color: #FFF; border: none; border-radius: 8px; padding: 10px; font-weight: 600; cursor: pointer; margin-top: 8px; }
.btn-save:hover { background: #D35400; }
</style>