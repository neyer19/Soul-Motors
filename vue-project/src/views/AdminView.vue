<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    :activeKey="activeSection"
    title="Panel Administrativo - Control Total"
    subtitle="Supervisión de finanzas, inventario y gestión completa de personal"
    @navigate="activeSection = $event"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <!-- 1. FINANZAS (sección fija) -->
    <template v-if="activeSection === 'finanzas'">
      <section class="card analytics-section">
        <div class="analytics-header">
          <div class="analytics-left">
            <MetricsMenu :items="financeMenu">
              <template #balance>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Balance general</span><strong class="mm-green">$ {{ formatCOP(balanceTotal) }}</strong></div>
                  <div class="mm-stat"><span>Ingresos ({{ activeTimeframe.toLowerCase() }})</span><strong class="mm-orange">$ {{ formatCOP(chartTotals.income) }}</strong></div>
                  <div class="mm-stat"><span>Egresos ({{ activeTimeframe.toLowerCase() }})</span><strong class="mm-red">$ {{ formatCOP(chartTotals.expense) }}</strong></div>
                  <div class="mm-stat"><span>Neto ({{ activeTimeframe.toLowerCase() }})</span><strong class="mm-green">$ {{ formatCOP(chartTotals.income - chartTotals.expense) }}</strong></div>
                </div>
                <div class="mm-seg">
                  <button v-for="t in timeframes" :key="t" :class="{ active: activeTimeframe === t }" @click="activeTimeframe = t">{{ t }}</button>
                </div>
                <h4 class="mm-section-title">Últimos movimientos</h4>
                <div class="mm-list">
                  <div v-for="m in financeTransactions.slice(0, 6)" :key="m.id" class="mm-row">
                    <div class="mm-row-main"><strong>{{ m.title }}</strong><small>{{ pretty(m.category) }} · {{ m.date }}</small></div>
                    <div :class="['mm-row-end', m.type === 'income' ? 'mm-green' : 'mm-red']">{{ m.type === 'income' ? '+' : '-' }} $ {{ formatCOP(m.amount) }}</div>
                  </div>
                </div>
              </template>

              <template #gastos>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Total gastos y repuestos</span><strong class="mm-red">$ {{ formatCOP(gastosTotal) }}</strong></div>
                  <div class="mm-stat"><span>Categorías</span><strong>{{ gastosBreakdown.length }}</strong></div>
                </div>
                <h4 class="mm-section-title">Gastos por categoría</h4>
                <div class="mm-list">
                  <div v-for="g in gastosBreakdown" :key="g.cat" class="mm-row">
                    <div class="mm-row-main">
                      <strong>{{ pretty(g.cat) }}</strong>
                      <div class="mm-bar"><i :style="{ width: g.pct + '%', background: '#E74C3C' }"></i></div>
                    </div>
                    <div class="mm-row-end">$ {{ formatCOP(g.amount) }}<small>{{ g.pct }}%</small></div>
                  </div>
                </div>
                <h4 class="mm-section-title">Egresos recientes</h4>
                <div class="mm-list">
                  <div v-for="m in recentExpenses" :key="m.id" class="mm-row">
                    <div class="mm-row-main"><strong>{{ m.title }}</strong><small>{{ pretty(m.category) }} · {{ m.date }}</small></div>
                    <div class="mm-row-end mm-red">- $ {{ formatCOP(m.amount) }}</div>
                  </div>
                </div>
              </template>

              <template #cobrar>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Total por cobrar</span><strong class="mm-yellow">$ {{ formatCOP(CUENTAS_POR_COBRAR) }}</strong></div>
                  <div class="mm-stat"><span>Vencido</span><strong class="mm-red">$ {{ formatCOP(overdueTotal) }}</strong></div>
                </div>
                <div class="mm-toolbar">
                  <div class="mm-field">
                    <label>Estado de la cuenta</label>
                    <select v-model="receivableFilter" class="mm-select">
                      <option value="all">Todas</option>
                      <option value="Vencida">Vencidas</option>
                      <option value="Por vencer">Por vencer (7 días)</option>
                      <option value="Vigente">Vigentes</option>
                    </select>
                  </div>
                </div>
                <div class="mm-list">
                  <div v-for="r in filteredReceivables" :key="r.id" class="mm-row">
                    <div class="mm-row-main"><strong>{{ r.cliente }}</strong><small>{{ r.concepto }} · {{ dueText(r.dias) }}</small></div>
                    <div class="mm-row-end">$ {{ formatCOP(r.monto) }}<span :class="['mm-tag', receivableTone(r.dias)]">{{ receivableState(r.dias) }}</span></div>
                  </div>
                </div>
                <p v-if="!filteredReceivables.length" class="mm-empty">No hay cuentas con ese estado.</p>
              </template>
            </MetricsMenu>

            <div class="analytics-title">
              <h3>Rendimiento Financiero y Tendencias</h3>
              <p>Ingresos y egresos del periodo seleccionado</p>
            </div>
          </div>

          <div class="header-right">
            <div class="timeframe">
              <button v-for="t in timeframes" :key="t" :class="['time-tab', { active: activeTimeframe === t && !customMode }]" @click="selectTimeframe(t)">{{ t }}</button>
            </div>
        <div class="date-filter-wrap" @click.stop>
          <button :class="['btn-filter', { active: customMode || filterOpen }]" @click="toggleFilter">
            <CalendarRange :size="15" /><span>Filtrar fechas</span>
          </button>

          <div v-if="filterOpen" class="filter-pop">
            <template v-if="filterStep === 'menu'">
              <p class="pop-title">Filtrar la gráfica por fechas</p>
              <button class="pop-option" @click="chooseMode('rango')">
                <CalendarRange :size="18" />
                <span><strong>Filtrar por fechas</strong><small>Elige una fecha inicial y una final</small></span>
              </button>
              <button class="pop-option" @click="chooseMode('comparar')">
                <ArrowLeftRight :size="18" />
                <span><strong>Comparar dos fechas</strong><small>Pon dos días uno encima del otro</small></span>
              </button>
            </template>

            <template v-else>
              <button class="pop-back" @click="filterStep = 'menu'">← Volver</button>
              <p class="pop-title">{{ filterStep === 'rango' ? 'Filtrar por fechas' : 'Comparar dos fechas' }}</p>
              <div v-for="slot in dateSlots" :key="slot.key" class="dd">
                <label class="dd-label">{{ slot.label }}</label>
                <button type="button" :class="['dd-field', { open: pickerOpen === slot.key }]" @click="togglePicker(slot.key)">
                  <CalendarRange :size="15" />
                  <span :class="{ placeholder: !dates[slot.key] }">{{ dates[slot.key] ? fmtLong(dates[slot.key]) : 'Seleccionar fecha' }}</span>
                  <ChevronDown :size="15" class="chev" />
                </button>

                <div v-if="pickerOpen === slot.key" class="dd-panel">
                  <div class="dd-crumbs">
                    <button v-if="pickStep !== 'year'" type="button" class="dd-back" aria-label="Volver" @click="pickStep = pickStep === 'day' ? 'month' : 'year'"><ChevronLeft :size="14" /></button>
                    <button type="button" :class="['dd-crumb', { act: pickStep === 'year' }]" @click="pickStep = 'year'">{{ pYear !== null ? pYear : 'Año' }}</button>
                    <template v-if="pYear !== null && pickStep !== 'year'">
                      <span class="dd-sep">›</span>
                      <button type="button" :class="['dd-crumb', { act: pickStep === 'month' }]" @click="pickStep = 'month'">{{ pMonth !== null ? MONTHS_FULL[pMonth] : 'Mes' }}</button>
                    </template>
                    <template v-if="pickStep === 'day'"><span class="dd-sep">›</span><span class="dd-crumb act">Día</span></template>
                  </div>

                  <!-- 1) Año (se desplaza) -->
                  <div v-if="pickStep === 'year'" class="dd-years">
                    <button v-for="y in yearList" :key="y" type="button" :class="['dd-year', { sel: y === pYear }]" @click="pickYear(y)">{{ y }}</button>
                  </div>
                  <!-- 2) Los 12 meses -->
                  <div v-else-if="pickStep === 'month'" class="dd-months">
                    <button v-for="(m, i) in MONTHS_FULL" :key="m" type="button" :disabled="monthDisabled(i)" :class="['dd-cell', { sel: i === pMonth }]" @click="pickMonth(i)">{{ m.slice(0, 3) }}</button>
                  </div>
                  <!-- 3) Los días del mes -->
                  <div v-else class="dd-days">
                    <button v-for="d in daysInPickedMonth" :key="d" type="button" :disabled="dayDisabled(d)" :class="['dd-cell', { sel: isPickedDay(slot.key, d) }]" @click="pickDay(slot.key, d)">{{ d }}</button>
                  </div>
                </div>
              </div>
              <p v-if="filterError" class="pop-error">{{ filterError }}</p>
              <div class="pop-actions">
                <button class="pop-cancel" @click="filterOpen = false">Cancelar</button>
                <button class="pop-apply" @click="applyFilter">Aplicar</button>
              </div>
            </template>
          </div>
        </div>
          </div>
        </div>

        <!-- Controles del gráfico: superponer la 2ª gráfica -->
        <div class="chart-toolbar">
          <button :class="['series-toggle', { on: showSecond }]" @click="showSecond = !showSecond">
            <Layers :size="14" />
            <span>{{ showSecond ? 'Quitar ' + seriesNames[1] : 'Superponer ' + seriesNames[1] }}</span>
          </button>
        </div>

      <!-- Resumen del filtro activo -->
      <div v-if="customMode && customSummary" class="custom-banner">
        <div class="banner-main">
          <strong>{{ customSummary.title }}</strong>
          <div v-if="customMode.type === 'comparar'" class="mm-seg-mini">
            <button :class="{ active: compareMetric === 'ingresos' }" @click="compareMetric = 'ingresos'">Ingresos</button>
            <button :class="{ active: compareMetric === 'egresos' }" @click="compareMetric = 'egresos'">Egresos</button>
          </div>
        </div>
        <div class="banner-stats">
          <span v-for="st in customSummary.stats" :key="st.label" class="banner-stat">{{ st.label }}: <b :style="{ color: st.color }">{{ st.value }}</b></span>
        </div>
        <button class="banner-clear" @click="clearCustom"><X :size="14" /> Quitar filtro</button>
      </div>

        <div class="chart-legend">
          <span class="legend-item"><i class="legend-dot dot-income"></i>{{ seriesNames[0] }}: <strong class="text-success">$ {{ formatCOP(legendTotals.first) }}</strong></span>
          <span v-if="showSecond" class="legend-item"><i :class="['legend-dot', isCompare ? 'dot-cmp' : 'dot-expense']"></i>{{ seriesNames[1] }}: <strong :class="isCompare ? 'text-cmp' : 'text-danger'">$ {{ formatCOP(legendTotals.second) }}</strong></span>
        </div>

        <div class="chart-container">
          <svg class="chart-svg" viewBox="0 0 900 300" preserveAspectRatio="none" role="img" :aria-label="`Gráfico de ingresos y egresos por ${activeTimeframe}`">
            <defs>
              <linearGradient id="gradFin" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#E67E22" stop-opacity="0.35" />
                <stop offset="100%" stop-color="#E67E22" stop-opacity="0" />
              </linearGradient>
              <linearGradient id="gradExp" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#E74C3C" stop-opacity="0.25" />
                <stop offset="100%" stop-color="#E74C3C" stop-opacity="0" />
              </linearGradient>
              <linearGradient id="gradCmp" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stop-color="#3498DB" stop-opacity="0.25" />
                <stop offset="100%" stop-color="#3498DB" stop-opacity="0" />
              </linearGradient>
            </defs>
            <line class="grid-line" x1="0" y1="60" x2="900" y2="60" />
            <line class="grid-line" x1="0" y1="140" x2="900" y2="140" />
            <line class="grid-line" x1="0" y1="220" x2="900" y2="220" />
            <path :d="drawn.incomeArea" fill="url(#gradFin)" />
            <path :d="drawn.incomeLine" class="line-income" />
            <g v-if="showSecond" class="second-series">
              <path :d="drawn.expenseArea" :fill="isCompare ? 'url(#gradCmp)' : 'url(#gradExp)'" />
              <path :d="drawn.expenseLine" :class="['line-expense', { cmp: isCompare }]" />
            </g>
          </svg>
          <div :class="['chart-axis', { dense: !!customMode }]"><span v-for="(label, i) in drawn.labels" :key="i">{{ label }}</span></div>
        </div>
      </section>

      <section class="card display-section">
        <div class="card-header-flex">
          <div class="header-titles-group">
            <h3>Registro de Movimientos Financieros</h3>
            <p>Historial detallado de entradas y salidas de caja</p>
          </div>
          <button class="btn-hire-direct" @click="openMovementModal"><PlusCircle :size="16" /><span>Nuevo Movimiento</span></button>
        </div>
        <div class="transactions-list">
          <div v-for="item in financeTransactions" :key="item.id" class="transaction-row">
            <div class="tx-info-group">
              <span class="tx-category">{{ item.category }}</span>
              <h4 class="tx-title">{{ item.title }}</h4>
              <span class="tx-date">{{ item.date }}</span>
            </div>
            <span :class="['tx-amount', item.type === 'income' ? 'text-success' : 'text-danger']">
              {{ item.type === 'income' ? '+ $ ' : '- $ ' }}{{ formatCOP(item.amount) }}
            </span>
          </div>
        </div>
      </section>
    </template>

    <!-- 2. INVENTARIO -->
    <InventoryPanel v-else-if="activeSection === 'inventario'" :products="inventoryData" />

    <!-- 3. TRABAJADORES -->
    <section v-else-if="activeSection === 'trabajadores'" class="card display-section">
      <div class="card-header-flex">
        <div class="analytics-left">
          <WorkersMetrics :workers="workersData" @open-worker="openConsultModal" />
          <div class="header-titles-group">
            <h3>Nómina y Equipo Activo</h3>
            <p>Administración de contratos, modificaciones y desvinculaciones</p>
          </div>
        </div>
        <div class="controls-right-group">
          <button class="btn-hire-direct btn-green" @click="openHireModal"><UserPlus :size="16" /><span>Contratar</span></button>
          <button class="btn-hire-direct btn-red" :disabled="!workersData.length" @click="openFireModal()"><UserMinus :size="16" /><span>Despedir</span></button>
          <div class="search-box-wrapper">
            <Search :size="16" class="search-icon-input" />
            <input v-model="searchQuery" type="text" placeholder="Buscar trabajador..." class="search-input" />
          </div>
        </div>
      </div>

      <p v-if="!filteredWorkers.length" class="empty-state">No hay trabajadores que coincidan con la búsqueda.</p>

      <div class="workers-grid">
        <div v-for="worker in filteredWorkers" :key="worker.id" class="worker-card">
          <div class="worker-card-header">
            <div class="worker-avatar-box"><Users :size="20" /></div>
            <div class="worker-main-titles">
              <h4>{{ worker.name }}</h4>
              <span class="worker-role-badge">{{ worker.role }}</span>
            </div>
            <div class="dropdown-wrapper">
              <button class="gear-btn" aria-label="Opciones del trabajador" @click.stop="toggleMenu(worker.id)"><Settings :size="18" /></button>
              <div v-if="activeMenuId === worker.id" class="dropdown-menu" @click.stop>
                <button class="dropdown-item" @click="openConsultModal(worker)"><Eye :size="14" /><span>Consultar Trabajador</span></button>
                <button class="dropdown-item" @click="openEditModal(worker)"><Edit3 :size="14" /><span>Modificar Trabajador</span></button>
                <button class="dropdown-item item-hire" @click="openHireModal"><UserPlus :size="14" /><span>Contratar Trabajador</span></button>
                <button class="dropdown-item item-danger" @click="openFireModal(worker)"><UserMinus :size="14" /><span>Despedir Trabajador</span></button>
              </div>
            </div>
          </div>
          <div class="worker-card-body">
            <div class="worker-info-row"><span>Cédula:</span><strong>{{ worker.cedula }}</strong></div>
            <div class="worker-info-row"><span>Horas Laborales:</span><strong>{{ worker.horas }} hrs / sem</strong></div>
            <div class="worker-info-row"><span>Teléfono:</span><strong>{{ worker.telefono || '—' }}</strong></div>
          </div>
        </div>
      </div>
    </section>

    <!-- MODALES -->
    <div v-if="showConsultModal" class="modal-overlay" @click.self="showConsultModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Consultar Trabajador</h3><button class="close-btn" aria-label="Cerrar" @click="showConsultModal = false"><X :size="18" /></button></div>
        <div v-if="selectedWorker" class="modal-body">
          <div class="detail-group"><span>Nombre:</span><strong>{{ selectedWorker.name }}</strong></div>
          <div class="detail-group"><span>Cargo:</span><strong>{{ selectedWorker.role }}</strong></div>
          <div class="detail-group"><span>Cédula:</span><strong>{{ selectedWorker.cedula }}</strong></div>
          <div class="detail-group"><span>Horas:</span><strong>{{ selectedWorker.horas }} hrs / sem</strong></div>
          <div class="detail-group"><span>Teléfono:</span><strong>{{ selectedWorker.telefono || '—' }}</strong></div>
          <div class="detail-group"><span>Fecha de ingreso:</span><strong>{{ fmtDate(selectedWorker.ingreso) }}</strong></div>
        </div>
      </div>
    </div>

    <div v-if="showEditModal" class="modal-overlay" @click.self="showEditModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Modificar Trabajador</h3><button class="close-btn" aria-label="Cerrar" @click="showEditModal = false"><X :size="18" /></button></div>
        <div v-if="editForm" class="modal-body">
          <div class="form-group"><label>Nombre</label><input v-model="editForm.name" type="text" class="form-input" /></div>
          <div class="form-group"><label>Cargo</label><input v-model="editForm.role" type="text" class="form-input" /></div>
          <div class="form-group"><label>Horas Semanales</label><input v-model.number="editForm.horas" type="number" min="1" class="form-input" /></div>
          <div class="form-group"><label>Teléfono</label><input v-model="editForm.telefono" type="text" class="form-input" /></div>
          <button class="btn-save" @click="saveChanges">Guardar cambios</button>
        </div>
      </div>
    </div>

    <div v-if="showHireModal" class="modal-overlay" @click.self="showHireModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Contratar Nuevo Trabajador</h3><button class="close-btn" aria-label="Cerrar" @click="showHireModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group"><label>Nombre Completo</label><input v-model="hireForm.name" type="text" placeholder="Ej: Juan Pérez" class="form-input" /></div>
          <div class="form-group"><label>Cargo</label>
            <select v-model="hireForm.role" class="form-input">
              <option>Mecánico Líder</option><option>Mecánico Especialista</option><option>Ayudante de Taller</option><option>Jefe de Bodega</option>
            </select>
          </div>
          <div class="form-group"><label>Cédula</label><input v-model="hireForm.cedula" type="text" class="form-input" /></div>
          <div class="form-group"><label>Horas Semanales</label><input v-model.number="hireForm.horas" type="number" min="1" class="form-input" /></div>
          <div class="form-group"><label>Teléfono</label><input v-model="hireForm.telefono" type="text" class="form-input" /></div>
          <p v-if="hireError" class="form-error">{{ hireError }}</p>
          <button class="btn-save btn-hire" @click="processHire">Confirmar contratación</button>
        </div>
      </div>
    </div>

    <div v-if="showFireModal" class="modal-overlay" @click.self="showFireModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3 class="text-danger">Desvincular Trabajador</h3><button class="close-btn" aria-label="Cerrar" @click="showFireModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group">
            <label>Trabajador a desvincular</label>
            <select v-model="fireWorkerId" class="form-input"><option v-for="w in workersData" :key="w.id" :value="w.id">{{ w.name }} — {{ w.role }}</option></select>
          </div>
          <p v-if="fireWorker" class="warning-text">¿Confirma la desvinculación de <strong>{{ fireWorker.name }}</strong> (CC: {{ fireWorker.cedula }})? Esta acción lo quitará del equipo activo.</p>
          <button class="btn-save btn-fire" :disabled="!fireWorker" @click="processFire">Confirmar despido</button>
        </div>
      </div>
    </div>

    <div v-if="showMovementModal" class="modal-overlay" @click.self="showMovementModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Registrar Nuevo Movimiento</h3><button class="close-btn" aria-label="Cerrar" @click="showMovementModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group"><label>Concepto</label><input v-model="newMovement.title" type="text" placeholder="Ej: Venta de repuestos" class="form-input" /></div>
          <div class="form-group"><label>Categoría</label><input v-model="newMovement.category" type="text" placeholder="Ej: VENTAS" class="form-input" /></div>
          <div class="form-group"><label>Tipo</label>
            <select v-model="newMovement.type" class="form-input"><option value="income">Ingreso (Ganancia)</option><option value="expense">Egreso (Gasto)</option></select>
          </div>
          <div class="form-group"><label>Monto ($)</label><input v-model.number="newMovement.amount" type="number" min="1" class="form-input" /></div>
          <p v-if="movementError" class="form-error">{{ movementError }}</p>
          <button class="btn-save" @click="addMovement">Registrar en caja</button>
        </div>
      </div>
    </div>

    <div v-if="toastMessage" class="toast" role="status">{{ toastMessage }}</div>
  </AppShell>
</template>

<script setup>
import { ref, reactive, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import {
  Users, Search, DollarSign, TrendingDown, Settings, Eye, Edit3, UserPlus, UserMinus, X,
  CreditCard, PlusCircle, Package, CalendarRange, ArrowLeftRight, Layers, ChevronDown, ChevronLeft
} from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
import MetricsMenu from '../components/MetricsMenu.vue'
import InventoryPanel from '../components/InventoryPanel.vue'
import WorkersMetrics from '../components/WorkersMetrics.vue'
import { getProducts, formatCOP } from '../data/productos'

defineProps({ isDarkMode: Boolean })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'finanzas', label: 'Finanzas', icon: DollarSign },
  { key: 'inventario', label: 'Inventario', icon: Package },
  { key: 'trabajadores', label: 'Trabajadores', icon: Users }
]
const activeSection = ref('finanzas') // Finanzas es la sección fija e inicial del Administrador

const searchQuery = ref('')
const activeMenuId = ref(null)
const closeMenus = () => { activeMenuId.value = null }
onMounted(() => document.addEventListener('click', closeMenus))
onUnmounted(() => { document.removeEventListener('click', closeMenus); clearTimeout(toastTimer) })

const toastMessage = ref('')
let toastTimer = null
const showToast = (msg) => {
  toastMessage.value = msg
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toastMessage.value = '' }, 2800)
}

const pretty = (s) => { const t = String(s).toLowerCase(); return t.charAt(0).toUpperCase() + t.slice(1) }
const fmtDate = (iso) => (iso ? new Date(iso + 'T00:00:00').toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' }) : '—')

/* ---------- INVENTARIO ---------- */
const inventoryData = ref(getProducts())

/* ---------- FINANZAS: movimientos y menú de indicadores ---------- */
const BALANCE_BASE = 28450000
const CUENTAS_POR_COBRAR = 5100000
const gastosBase = [
  { cat: 'REPUESTOS', amount: 6100000 },
  { cat: 'NÓMINA', amount: 4200000 },
  { cat: 'SERVICIOS PÚBLICOS', amount: 1200000 },
  { cat: 'OTROS', amount: 800000 }
]

const financeTransactions = ref([
  { id: 1, title: 'Venta Kit de Arrastre Pulsar NS200', category: 'VENTAS', date: 'Hoy, 16:45', amount: 350000, type: 'income', isNew: false },
  { id: 2, title: 'Pago Proveedor Lubricantes 10W40', category: 'REPUESTOS', date: 'Hoy, 14:20', amount: 1200000, type: 'expense', isNew: false },
  { id: 3, title: 'Servicio Mantenimiento General FZ', category: 'SERVICIOS TALLER', date: 'Ayer, 11:10', amount: 180000, type: 'income', isNew: false }
])
const sumNew = (type) => financeTransactions.value.filter(t => t.isNew && t.type === type).reduce((a, t) => a + t.amount, 0)
const balanceTotal = computed(() => BALANCE_BASE + sumNew('income') - sumNew('expense'))

const gastosBreakdown = computed(() => {
  const map = {}
  gastosBase.forEach(g => { map[g.cat] = (map[g.cat] || 0) + g.amount })
  financeTransactions.value.filter(t => t.isNew && t.type === 'expense').forEach(t => {
    const k = t.category.toUpperCase()
    map[k] = (map[k] || 0) + t.amount
  })
  const total = Object.values(map).reduce((a, b) => a + b, 0) || 1
  return Object.entries(map).map(([cat, amount]) => ({ cat, amount, pct: Math.round((amount / total) * 100) })).sort((a, b) => b.amount - a.amount)
})
const gastosTotal = computed(() => gastosBreakdown.value.reduce((a, g) => a + g.amount, 0))
const recentExpenses = computed(() => financeTransactions.value.filter(t => t.type === 'expense').slice(0, 5))

// Cuentas por cobrar (datos de ejemplo). dias = días para el vencimiento (negativo = vencida)
const receivables = ref([
  { id: 1, cliente: 'Carlos Mendoza', concepto: 'Reparación de motor', monto: 1250000, dias: -6 },
  { id: 2, cliente: 'Andrea Gómez', concepto: 'Kit de arrastre y mano de obra', monto: 980000, dias: 4 },
  { id: 3, cliente: 'Flotilla Express', concepto: 'Mantenimiento preventivo de flotilla', monto: 2100000, dias: 18 },
  { id: 4, cliente: 'Diana Marcela', concepto: 'Cambio de frenos', monto: 770000, dias: 25 }
])
const receivableFilter = ref('all')
const receivableState = (d) => (d < 0 ? 'Vencida' : d <= 7 ? 'Por vencer' : 'Vigente')
const receivableTone = (d) => (d < 0 ? 'danger' : d <= 7 ? 'warning' : 'success')
const dueText = (d) => (d < 0 ? `venció hace ${Math.abs(d)} días` : d === 0 ? 'vence hoy' : `vence en ${d} días`)
const filteredReceivables = computed(() =>
  receivables.value.filter(r => receivableFilter.value === 'all' || receivableState(r.dias) === receivableFilter.value).sort((a, b) => a.dias - b.dias)
)
const overdueTotal = computed(() => receivables.value.filter(r => r.dias < 0).reduce((a, r) => a + r.monto, 0))

const financeMenu = computed(() => [
  { key: 'balance', label: 'Balance general', value: `$ ${formatCOP(balanceTotal.value)}`, icon: DollarSign, tone: 'green' },
  { key: 'gastos', label: 'Gastos y repuestos', value: `$ ${formatCOP(gastosTotal.value)}`, icon: TrendingDown, tone: 'red' },
  { key: 'cobrar', label: 'Cuentas por cobrar', value: `$ ${formatCOP(CUENTAS_POR_COBRAR)}`, icon: CreditCard, tone: 'yellow' }
])

const showMovementModal = ref(false)
const movementError = ref('')
const newMovement = ref({ title: '', category: 'VENTAS', type: 'income', amount: null })
const openMovementModal = () => {
  newMovement.value = { title: '', category: 'VENTAS', type: 'income', amount: null }
  movementError.value = ''
  showMovementModal.value = true
}
const addMovement = () => {
  const m = newMovement.value
  if (!m.title.trim()) { movementError.value = 'Escribe el concepto del movimiento.'; return }
  if (!m.amount || m.amount <= 0) { movementError.value = 'El monto debe ser mayor a cero.'; return }
  const now = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  financeTransactions.value.unshift({
    id: Date.now(), title: m.title.trim(), category: (m.category || 'GENERAL').trim().toUpperCase(),
    type: m.type, amount: m.amount, date: `Hoy, ${now}`, isNew: true
  })
  showMovementModal.value = false
  showToast('Movimiento registrado en caja.')
}

/* ---------- FINANZAS: gráfico por periodo (datos simulados) ---------- */
const timeframes = ['Semana', 'Mes', 'Trimestre', 'Año']
const activeTimeframe = ref('Mes')
const chartData = {
  Semana: { labels: ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'], income: [1800000, 2400000, 1500000, 3100000, 2800000, 3600000, 900000], expense: [600000, 900000, 700000, 1200000, 800000, 1100000, 300000] },
  Mes: { labels: ['SEMANA 1', 'SEMANA 2', 'SEMANA 3', 'SEMANA 4'], income: [9200000, 11800000, 10400000, 14400000], expense: [3100000, 4200000, 2900000, 3800000] },
  Trimestre: { labels: ['MES 1', 'MES 2', 'MES 3'], income: [38500000, 42100000, 45800000], expense: [12800000, 14100000, 12400000] },
  Año: { labels: ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'], income: [31000000, 28500000, 35200000, 33800000, 39100000, 41500000, 38700000, 43200000, 40100000, 45800000, 44200000, 49600000], expense: [11200000, 10400000, 12900000, 12100000, 13800000, 14600000, 13200000, 15100000, 13900000, 12400000, 14800000, 16200000] }
}
const currentChart = computed(() => chartData[activeTimeframe.value])
const chartTotals = computed(() => ({
  income: currentChart.value.income.reduce((a, b) => a + b, 0),
  expense: currentChart.value.expense.reduce((a, b) => a + b, 0)
}))

const CHART_W = 900
const CHART_H = 300
const CHART_TOP = 24
const CHART_BOTTOM = 24
const chartMax = computed(() => Math.max(...currentChart.value.income, ...currentChart.value.expense) * 1.1)
const toPoints = (values) => {
  const n = values.length
  const usable = CHART_H - CHART_TOP - CHART_BOTTOM
  return values.map((v, i) => ({ x: n === 1 ? CHART_W / 2 : (i * CHART_W) / (n - 1), y: CHART_H - CHART_BOTTOM - (v / chartMax.value) * usable }))
}
const smoothPath = (pts) => {
  if (!pts.length) return ''
  let d = `M ${pts[0].x.toFixed(1)} ${pts[0].y.toFixed(1)}`
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2
    d += ` C ${(p1.x + (p2.x - p0.x) / 6).toFixed(1)} ${(p1.y + (p2.y - p0.y) / 6).toFixed(1)}, ${(p2.x - (p3.x - p1.x) / 6).toFixed(1)} ${(p2.y - (p3.y - p1.y) / 6).toFixed(1)}, ${p2.x.toFixed(1)} ${p2.y.toFixed(1)}`
  }
  return d
}
const incomeLinePath = computed(() => smoothPath(toPoints(currentChart.value.income)))
const expenseLinePath = computed(() => smoothPath(toPoints(currentChart.value.expense)))
const incomeAreaPath = computed(() => {
  const pts = toPoints(currentChart.value.income)
  return pts.length ? `${smoothPath(pts)} L ${pts[pts.length - 1].x.toFixed(1)} ${CHART_H} L ${pts[0].x.toFixed(1)} ${CHART_H} Z` : ''
})

/* =====================================================================
   FILTRO DE FECHAS DE LA GRÁFICA (rango / comparar dos fechas)
   ===================================================================== */
const showSecond = ref(false)          // la 2ª gráfica (Egresos / Fecha B) arranca oculta
const filterOpen = ref(false)
const filterStep = ref('menu')         // 'menu' | 'rango' | 'comparar'
const dates = reactive({ a: '', b: '' })
const pickerOpen = ref(null)        // 'a' | 'b' | null
const pickStep = ref('year')        // 'year' | 'month' | 'day'
const pYear = ref(null)
const pMonth = ref(null)
const filterError = ref('')
const customMode = ref(null)           // null = periodos normales | { type, a, b }
const compareMetric = ref('ingresos')

const pad2 = (n) => String(n).padStart(2, '0')
const toISO = (d) => `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`
const parseISO = (iso) => new Date(`${iso}T00:00:00`)
const maxDate = toISO(new Date())
const MONTH_SHORT = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
const fmtLong = (iso) => { const d = parseISO(iso); return `${d.getDate()} ${MONTH_SHORT[d.getMonth()]} ${d.getFullYear()}` }
const fmtShort = (iso) => { const d = parseISO(iso); return `${d.getDate()} ${MONTH_SHORT[d.getMonth()]}` }

/* ---------- Selector de fecha: Año → 12 meses → días ---------- */
const MONTHS_FULL = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
const dateSlots = computed(() => [
  { key: 'a', label: filterStep.value === 'rango' ? 'Desde' : 'Fecha A' },
  { key: 'b', label: filterStep.value === 'rango' ? 'Hasta' : 'Fecha B' }
])
const maxY = Number(maxDate.slice(0, 4)), maxM = Number(maxDate.slice(5, 7)) - 1, maxD = Number(maxDate.slice(8, 10))
const yearList = computed(() => { const l = []; for (let y = maxY; y >= 2020; y--) l.push(y); return l })
const daysInPickedMonth = computed(() => (pYear.value === null || pMonth.value === null ? 0 : new Date(pYear.value, pMonth.value + 1, 0).getDate()))
const monthDisabled = (i) => pYear.value === maxY && i > maxM
const dayDisabled = (d) => pYear.value === maxY && pMonth.value === maxM && d > maxD
const isPickedDay = (key, d) => dates[key] === `${pYear.value}-${pad2((pMonth.value ?? 0) + 1)}-${pad2(d)}`

const togglePicker = async (key) => {
  if (pickerOpen.value === key) { pickerOpen.value = null; return }
  pickerOpen.value = key
  const cur = dates[key]
  pYear.value = cur ? Number(cur.slice(0, 4)) : null
  pMonth.value = cur ? Number(cur.slice(5, 7)) - 1 : null
  pickStep.value = 'year'
  await nextTick()
  const el = document.querySelector('.dd-year.sel') || document.querySelector('.dd-year')
  if (el) el.scrollIntoView({ block: 'center' })
}
const pickYear = (y) => { pYear.value = y; pMonth.value = null; pickStep.value = 'month' }
const pickMonth = (m) => { pMonth.value = m; pickStep.value = 'day' }
const pickDay = (key, d) => { dates[key] = `${pYear.value}-${pad2(pMonth.value + 1)}-${pad2(d)}`; pickerOpen.value = null }

const closeFilter = () => { filterOpen.value = false }
onMounted(() => document.addEventListener('click', closeFilter))
onUnmounted(() => document.removeEventListener('click', closeFilter))

const toggleFilter = () => { filterOpen.value = !filterOpen.value; if (filterOpen.value) { filterStep.value = 'menu'; filterError.value = '' } }
const chooseMode = (mode) => { filterStep.value = mode; dates.a = ''; dates.b = ''; pickerOpen.value = null; filterError.value = '' }

const applyFilter = () => {
  if (!dates.a || !dates.b) { filterError.value = 'Selecciona las dos fechas (año, mes y día).'; return }
  if (filterStep.value === 'rango') {
    if (dates.a > dates.b) { filterError.value = 'La fecha inicial debe ser anterior a la final.'; return }
  } else if (dates.a === dates.b) {
    filterError.value = 'Elige dos fechas distintas para compararlas.'; return
  }
  customMode.value = { type: filterStep.value, a: dates.a, b: dates.b }
  if (filterStep.value === 'comparar') { showSecond.value = true; compareMetric.value = 'ingresos' }
  filterOpen.value = false
}
const clearCustom = () => { customMode.value = null }
const selectTimeframe = (t) => { customMode.value = null; activeTimeframe.value = t }
watch(activeTimeframe, () => { customMode.value = null })

// Datos de ejemplo determinísticos (la misma fecha siempre da el mismo valor)
const hash01 = (str) => {
  let h = 2166136261
  for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) }
  return (h >>> 0) / 4294967295
}
const WEEK_FACTOR = [0.55, 0.9, 1, 1.05, 1.1, 1.35, 1.2]
const dayIncome = (iso) => Math.round((1300000 * WEEK_FACTOR[parseISO(iso).getDay()] * (0.75 + hash01('i' + iso) * 0.5)) / 1000) * 1000
const dayExpense = (iso) => Math.round((420000 * (0.6 + hash01('e' + iso) * 0.8)) / 1000) * 1000
const HOURS = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00']
const hourly = (iso, kind) => {
  const total = kind === 'ingresos' ? dayIncome(iso) : dayExpense(iso)
  const w = HOURS.map((_, i) => (0.4 + hash01(kind + iso + i)) * (1 - Math.abs(i - 5) / 9))
  const sum = w.reduce((a, b) => a + b, 0)
  return w.map((x) => Math.round((total * x) / sum / 1000) * 1000)
}
const daysBetween = (a, b) => {
  const out = []
  const d = parseISO(a)
  const end = parseISO(b)
  while (d <= end) { out.push(toISO(d)); d.setDate(d.getDate() + 1) }
  return out
}
const sum = (arr) => arr.reduce((x, y) => x + y, 0)

// Serie numérica del filtro activo: { labels, first, second }
const customSeries = computed(() => {
  const c = customMode.value
  if (!c) return null
  if (c.type === 'comparar') {
    return { labels: HOURS, first: hourly(c.a, compareMetric.value), second: hourly(c.b, compareMetric.value) }
  }
  if (c.a === c.b) {
    return { labels: HOURS, first: hourly(c.a, 'ingresos'), second: hourly(c.a, 'egresos') }
  }
  const days = daysBetween(c.a, c.b)
  const buckets = []
  if (days.length <= 31) {
    days.forEach((iso) => buckets.push({ label: `${parseISO(iso).getDate()}/${parseISO(iso).getMonth() + 1}`, days: [iso] }))
  } else if (days.length <= 180) {
    for (let i = 0; i < days.length; i += 7) {
      const part = days.slice(i, i + 7)
      buckets.push({ label: `${parseISO(part[0]).getDate()}/${parseISO(part[0]).getMonth() + 1}`, days: part })
    }
  } else {
    const map = new Map()
    days.forEach((iso) => {
      const key = iso.slice(0, 7)
      if (!map.has(key)) map.set(key, { label: `${MONTH_SHORT[parseISO(iso).getMonth()]} ${String(parseISO(iso).getFullYear()).slice(2)}`, days: [] })
      map.get(key).days.push(iso)
    })
    map.forEach((b) => buckets.push(b))
  }
  const step = Math.ceil(buckets.length / 10)
  return {
    labels: buckets.map((b, i) => (i % step === 0 ? b.label : '')),
    first: buckets.map((b) => sum(b.days.map(dayIncome))),
    second: buckets.map((b) => sum(b.days.map(dayExpense)))
  }
})

const expenseAreaPath = computed(() => {
  const pts = toPoints(currentChart.value.expense)
  return pts.length ? `${smoothPath(pts)} L ${pts[pts.length - 1].x.toFixed(1)} ${CHART_H} L ${pts[0].x.toFixed(1)} ${CHART_H} Z` : ''
})

// Rutas del SVG (viewBox 900x300) a partir de dos series numéricas
const buildPaths = (first, second) => {
  const n = first.length
  const max = Math.max(...first, ...second, 1) * 1.1
  const pts = (vals) => vals.map((v, i) => ({ x: ((i + 0.5) * CHART_W) / n, y: CHART_H - CHART_BOTTOM - (v / max) * (CHART_H - CHART_TOP - CHART_BOTTOM) }))
  const area = (p) => `${smoothPath(p)} L ${p[p.length - 1].x.toFixed(1)} ${CHART_H} L ${p[0].x.toFixed(1)} ${CHART_H} Z`
  const a = pts(first), b = pts(second)
  return { incomeLine: smoothPath(a), incomeArea: area(a), expenseLine: smoothPath(b), expenseArea: area(b) }
}

// Lo que dibuja el gráfico: periodo normal o filtro de fechas
const drawn = computed(() => {
  const cs = customSeries.value
  if (!cs) return { labels: currentChart.value.labels, incomeLine: incomeLinePath.value, incomeArea: incomeAreaPath.value, expenseLine: expenseLinePath.value, expenseArea: expenseAreaPath.value }
  return { labels: cs.labels, ...buildPaths(cs.first, cs.second) }
})
const isCompare = computed(() => !!customMode.value && customMode.value.type === 'comparar')
const legendTotals = computed(() => {
  const cs = customSeries.value
  if (!cs) return { first: chartTotals.value.income, second: chartTotals.value.expense }
  return { first: sum(cs.first), second: sum(cs.second) }
})
const seriesNames = computed(() => {
  const c = customMode.value
  if (c && c.type === 'comparar') return [fmtShort(c.a), fmtShort(c.b)]
  return ['Ingresos', 'Egresos']
})

const customSummary = computed(() => {
  const c = customMode.value
  const cs = customSeries.value
  if (!c || !cs) return null
  const money = (n) => `$ ${formatCOP(n)}`
  if (c.type === 'comparar') {
    const ta = sum(cs.first), tb = sum(cs.second)
    const diff = ta ? Math.round(((tb - ta) / ta) * 1000) / 10 : 0
    return {
      title: `Comparando ${fmtLong(c.a)} con ${fmtLong(c.b)}`,
      stats: [
        { label: fmtShort(c.a), value: money(ta), color: '#E67E22' },
        { label: fmtShort(c.b), value: money(tb), color: '#3498DB' },
        { label: 'Diferencia', value: `${diff > 0 ? '+' : ''}${diff}%`, color: diff >= 0 ? '#2ECC71' : '#E74C3C' }
      ]
    }
  }
  const days = daysBetween(c.a, c.b)
  const ing = sum(days.map(dayIncome)), egr = sum(days.map(dayExpense))
  return {
    title: c.a === c.b ? `Día ${fmtLong(c.a)}` : `Del ${fmtLong(c.a)} al ${fmtLong(c.b)} (${days.length} días)`,
    stats: [
      { label: 'Ingresos', value: money(ing), color: '#2ECC71' },
      { label: 'Egresos', value: money(egr), color: '#E74C3C' },
      { label: 'Balance', value: money(ing - egr), color: '#F1C40F' }
    ]
  }
})

/* ---------- TRABAJADORES ---------- */
const todayISO = () => new Date().toISOString().slice(0, 10)
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

const showConsultModal = ref(false)
const selectedWorker = ref(null)
const openConsultModal = (w) => { selectedWorker.value = w; showConsultModal.value = true; activeMenuId.value = null }

const showEditModal = ref(false)
const editForm = ref(null)
const openEditModal = (w) => { editForm.value = { ...w }; showEditModal.value = true; activeMenuId.value = null }
const saveChanges = () => {
  const i = workersData.value.findIndex(w => w.id === editForm.value.id)
  if (i !== -1) workersData.value[i] = { ...editForm.value }
  showEditModal.value = false
  showToast('Trabajador modificado.')
}

const showHireModal = ref(false)
const hireError = ref('')
const defaultHire = () => ({ name: '', role: 'Mecánico Especialista', cedula: '', horas: 48, telefono: '' })
const hireForm = ref(defaultHire())
const openHireModal = () => { hireForm.value = defaultHire(); hireError.value = ''; showHireModal.value = true; activeMenuId.value = null }
const processHire = () => {
  const f = hireForm.value
  if (!f.name.trim() || !String(f.cedula).trim()) { hireError.value = 'Ingresa el nombre y la cédula.'; return }
  if (workersData.value.some(w => w.cedula === String(f.cedula).trim())) { hireError.value = 'Ya existe un trabajador con esa cédula.'; return }
  workersData.value.push({ id: Date.now(), name: f.name.trim(), role: f.role, cedula: String(f.cedula).trim(), horas: f.horas || 48, telefono: f.telefono, ingreso: todayISO() })
  showHireModal.value = false
  showToast('Contratación registrada.')
}

const showFireModal = ref(false)
const fireWorkerId = ref(null)
const fireWorker = computed(() => workersData.value.find(w => w.id === fireWorkerId.value) || null)
const openFireModal = (w = null) => {
  fireWorkerId.value = w ? w.id : (workersData.value[0] ? workersData.value[0].id : null)
  showFireModal.value = true
  activeMenuId.value = null
}
const processFire = () => {
  if (!fireWorker.value) return
  const name = fireWorker.value.name
  workersData.value = workersData.value.filter(w => w.id !== fireWorkerId.value)
  showFireModal.value = false
  showToast(`${name} fue desvinculado.`)
}
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; }
.text-success { color: #2ECC71; }
.text-danger { color: #E74C3C; }
.analytics-section { display: flex; flex-direction: column; gap: 18px; }
.analytics-header, .card-header-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px; }
.analytics-left { display: flex; align-items: center; gap: 14px; }
.analytics-title h3, .header-titles-group h3 { font-size: 17px; font-weight: 600; margin: 0 0 4px; }
.analytics-title p, .header-titles-group p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.timeframe { display: flex; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 4px; gap: 4px; }
.time-tab { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; transition: all 0.2s; }
.time-tab:hover { color: #E67E22; }
.time-tab.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.chart-legend { display: flex; flex-wrap: wrap; gap: 20px; font-size: 12px; color: var(--text-secondary); }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; }
.dot-income { background: #E67E22; }
.dot-expense { background: #E74C3C; }
.chart-container { display: flex; flex-direction: column; gap: 10px; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 22px; }
.chart-svg { width: 100%; height: 400px; }
.grid-line { stroke: var(--border-color); stroke-dasharray: 4; stroke-width: 1; vector-effect: non-scaling-stroke; }
.line-income { fill: none; stroke: #E67E22; stroke-width: 3; stroke-linecap: round; vector-effect: non-scaling-stroke; }
.line-expense { fill: none; stroke: #E74C3C; stroke-width: 2.5; stroke-linecap: round; stroke-dasharray: 6 4; vector-effect: non-scaling-stroke; }
.chart-axis { display: flex; justify-content: space-between; font-size: 11px; font-weight: 700; color: var(--text-secondary); }

/* Controles del gráfico y filtro de fechas */
.chart-toolbar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
.series-controls { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.series-chip { display: flex; align-items: center; gap: 8px; font-size: 13px; font-weight: 700; color: var(--text-primary); background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 999px; padding: 7px 14px; }
.series-chip i { width: 10px; height: 10px; border-radius: 50%; background: #E67E22; display: inline-block; }
.series-toggle { display: flex; align-items: center; gap: 8px; background: transparent; border: 1px dashed #3498DB; color: #3498DB; border-radius: 999px; padding: 7px 14px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.series-toggle:hover { background: rgba(52, 152, 219, 0.12); }
.series-toggle.on { border-style: solid; background: rgba(52, 152, 219, 0.15); }
.date-filter-wrap { position: relative; }
.btn-filter { display: flex; align-items: center; gap: 8px; background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 10px; padding: 9px 16px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn-filter:hover, .btn-filter.active { border-color: #E67E22; color: #E67E22; }
.filter-pop { position: absolute; right: 0; top: calc(100% + 8px); z-index: 60; width: 320px; max-width: 92vw; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 14px; padding: 16px; box-shadow: 0 14px 34px rgba(0, 0, 0, 0.35); display: flex; flex-direction: column; gap: 12px; }
.pop-title { margin: 0; font-size: 14px; font-weight: 700; }
.pop-option { display: flex; align-items: center; gap: 12px; text-align: left; background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 12px; padding: 12px 14px; cursor: pointer; transition: all 0.2s; }
.pop-option:hover { border-color: #E67E22; }
.pop-option svg { color: #E67E22; flex-shrink: 0; }
.pop-option span { display: flex; flex-direction: column; gap: 2px; }
.pop-option strong { font-size: 13px; }
.pop-option small { font-size: 11px; color: var(--text-secondary); }
.pop-back { align-self: flex-start; background: transparent; border: none; color: var(--text-secondary); font-size: 12px; cursor: pointer; padding: 0; }
.pop-back:hover { color: #E67E22; }
.pop-error { margin: 0; font-size: 12px; color: #E74C3C; }
.pop-actions { display: flex; justify-content: flex-end; gap: 8px; }
.pop-cancel { background: transparent; border: 1px solid var(--border-color); color: var(--text-secondary); border-radius: 8px; padding: 8px 14px; font-size: 12px; font-weight: 600; cursor: pointer; }
.pop-apply { background: #E67E22; border: none; color: #FFFFFF; border-radius: 8px; padding: 8px 18px; font-size: 12px; font-weight: 700; cursor: pointer; }
.pop-apply:hover { background: #D35400; }

.custom-banner { display: flex; align-items: center; gap: 16px; flex-wrap: wrap; background: rgba(230, 126, 34, 0.1); border: 1px solid rgba(230, 126, 34, 0.4); border-radius: 12px; padding: 12px 16px; }
.banner-main { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.banner-main strong { font-size: 14px; }
.mm-seg-mini { display: flex; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 3px; gap: 3px; }
.mm-seg-mini button { background: transparent; border: none; color: var(--text-secondary); padding: 4px 10px; border-radius: 6px; font-size: 11px; cursor: pointer; }
.mm-seg-mini button.active { background: #E67E22; color: #FFFFFF; font-weight: 600; }
.banner-stats { display: flex; gap: 16px; flex-wrap: wrap; flex: 1; font-size: 13px; color: var(--text-secondary); }
.banner-stat b { font-size: 14px; }
.banner-clear { display: flex; align-items: center; gap: 4px; background: transparent; border: 1px solid #E74C3C; color: #E74C3C; border-radius: 8px; padding: 6px 12px; font-size: 12px; font-weight: 600; cursor: pointer; }
.banner-clear:hover { background: rgba(231, 76, 60, 0.1); }

/* La 2ª gráfica entra "encima" de la primera */
.second-series { transform-box: view-box; transform-origin: 50% 100%; animation: overlayIn 0.9s cubic-bezier(.2,.8,.2,1); }
@keyframes overlayIn { from { opacity: 0; transform: scaleY(0.15); } to { opacity: 1; transform: scaleY(1); } }
.header-right { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.dd { display: flex; flex-direction: column; gap: 6px; }
.dd-label { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.4px; }
.dd-field { display: flex; align-items: center; gap: 8px; background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 10px; padding: 10px 12px; font-size: 13px; cursor: pointer; width: 100%; text-align: left; }
.dd-field:hover, .dd-field.open { border-color: #E67E22; }
.dd-field span { flex: 1; }
.dd-field .placeholder { color: var(--text-secondary); }
.dd-field .chev { color: var(--text-secondary); transition: transform 0.2s; }
.dd-field.open .chev { transform: rotate(180deg); }
.dd-panel { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 12px; padding: 10px; display: flex; flex-direction: column; gap: 10px; }
.dd-crumbs { display: flex; align-items: center; gap: 4px; font-size: 12px; flex-wrap: wrap; }
.dd-back { background: transparent; border: 1px solid var(--border-color); color: var(--text-secondary); width: 24px; height: 24px; border-radius: 6px; cursor: pointer; display: flex; align-items: center; justify-content: center; margin-right: 4px; }
.dd-back:hover { color: #E67E22; border-color: #E67E22; }
.dd-crumb { background: transparent; border: none; color: var(--text-secondary); font-size: 12px; font-weight: 600; cursor: pointer; padding: 2px 4px; border-radius: 4px; }
.dd-crumb.act { color: #E67E22; }
.dd-sep { color: var(--text-secondary); }
.dd-years { max-height: 170px; overflow-y: auto; display: flex; flex-direction: column; gap: 4px; padding-right: 4px; }
.dd-year { background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 8px; padding: 9px 12px; font-size: 14px; font-weight: 600; cursor: pointer; text-align: center; flex-shrink: 0; }
.dd-year:hover { border-color: #E67E22; color: #E67E22; }
.dd-year.sel { background: #E67E22; border-color: #E67E22; color: #FFFFFF; }
.dd-months { display: grid; grid-template-columns: repeat(3, 1fr); gap: 6px; }
.dd-days { display: grid; grid-template-columns: repeat(7, 1fr); gap: 5px; }
.dd-cell { background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 8px; padding: 8px 0; font-size: 13px; font-weight: 600; cursor: pointer; }
.dd-cell:hover:not(:disabled) { border-color: #E67E22; color: #E67E22; }
.dd-cell.sel { background: #E67E22; border-color: #E67E22; color: #FFFFFF; }
.dd-cell:disabled { opacity: 0.3; cursor: not-allowed; }
.chart-axis.dense { padding: 0; }
.chart-axis.dense span { flex: 1; text-align: center; min-width: 0; font-size: 10px; }
.dot-cmp { background: #3498DB; }
.text-cmp { color: #3498DB; }
.line-expense.cmp { stroke: #3498DB; }
/* La 2ª gráfica entra "encima" de la primera */

.display-section { display: flex; flex-direction: column; gap: 20px; }
.controls-right-group { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.btn-hire-direct { background: #E67E22; color: #FFF; border: none; padding: 8px 14px; border-radius: 10px; font-size: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; height: 38px; transition: background-color 0.2s, opacity 0.2s; }
.btn-hire-direct:hover { background: #D35400; }
.btn-hire-direct.btn-green { background: #2ECC71; }
.btn-hire-direct.btn-green:hover { background: #27AE60; }
.btn-hire-direct.btn-red { background: #E74C3C; }
.btn-hire-direct.btn-red:hover { background: #C0392B; }
.btn-hire-direct:disabled { opacity: 0.5; cursor: not-allowed; }
.search-box-wrapper { position: relative; display: flex; align-items: center; }
.search-icon-input { position: absolute; left: 12px; color: var(--text-secondary); }
.search-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 8px 14px 8px 36px; color: var(--text-primary); font-size: 12px; outline: none; width: 200px; height: 38px; box-sizing: border-box; }
.search-input:focus { border-color: #E67E22; }
.empty-state { font-size: 13px; color: var(--text-secondary); margin: 0; }

.workers-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
.worker-card { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 16px; display: flex; flex-direction: column; gap: 12px; position: relative; }
.worker-card-header { display: flex; align-items: center; gap: 12px; position: relative; }
.worker-avatar-box { background: rgba(230, 126, 34, 0.1); color: #E67E22; width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.worker-main-titles { flex: 1; }
.worker-main-titles h4 { font-size: 14px; font-weight: 700; margin: 0 0 4px; }
.worker-role-badge { font-size: 10px; color: #E67E22; font-weight: 600; background: rgba(230, 126, 34, 0.1); padding: 2px 6px; border-radius: 4px; }
.gear-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; padding: 4px; border-radius: 6px; display: flex; }
.gear-btn:hover { color: #E67E22; background: rgba(230, 126, 34, 0.1); }
.dropdown-wrapper { position: relative; }
.dropdown-menu { position: absolute; right: 0; top: 28px; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 10px; box-shadow: 0 4px 12px rgba(0,0,0,0.3); z-index: 20; width: 200px; display: flex; flex-direction: column; padding: 4px; }
.dropdown-item { background: transparent; border: none; color: var(--text-primary); padding: 8px 12px; font-size: 12px; display: flex; align-items: center; gap: 8px; cursor: pointer; text-align: left; border-radius: 6px; }
.dropdown-item:hover { background: rgba(230, 126, 34, 0.15); color: #E67E22; }
.dropdown-item.item-hire { color: #2ECC71; }
.dropdown-item.item-hire:hover { background: rgba(46, 204, 113, 0.15); }
.dropdown-item.item-danger { color: #E74C3C; }
.dropdown-item.item-danger:hover { background: rgba(231, 76, 60, 0.15); }
.worker-card-body { border-top: 1px solid var(--border-color); padding-top: 10px; display: flex; flex-direction: column; gap: 6px; }
.worker-info-row { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-secondary); }
.worker-info-row strong { color: var(--text-primary); }

.transactions-list { display: flex; flex-direction: column; gap: 10px; }
.transaction-row { display: flex; justify-content: space-between; align-items: center; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px 18px; gap: 12px; }
.tx-info-group { display: flex; flex-direction: column; gap: 2px; }
.tx-category { font-size: 10px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; }
.tx-title { font-size: 14px; font-weight: 600; margin: 0; }
.tx-date { font-size: 11px; color: var(--text-secondary); }
.tx-amount { font-size: 15px; font-weight: 700; white-space: nowrap; }

.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal-card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; width: 420px; max-width: 100%; max-height: 90vh; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.modal-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
.modal-header h3 { font-size: 16px; margin: 0; font-weight: 600; }
.close-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; }
.close-btn:hover { color: var(--text-primary); }
.modal-body { display: flex; flex-direction: column; gap: 12px; }
.detail-group { display: flex; justify-content: space-between; font-size: 13px; border-bottom: 1px solid var(--border-color); padding-bottom: 8px; color: var(--text-secondary); }
.detail-group strong { color: var(--text-primary); }
.form-group { display: flex; flex-direction: column; gap: 4px; }
.form-group label { font-size: 11px; font-weight: 700; color: var(--text-secondary); }
.form-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 8px 12px; color: var(--text-primary); font-size: 13px; outline: none; }
.form-input:focus { border-color: #E67E22; }
.form-error { font-size: 12px; color: #E74C3C; margin: 0; }
.btn-save { background: #E67E22; color: #FFF; border: none; border-radius: 8px; padding: 10px; font-weight: 600; cursor: pointer; margin-top: 8px; transition: background-color 0.2s, opacity 0.2s; }
.btn-save:hover:not(:disabled) { background: #D35400; }
.btn-save:disabled { opacity: 0.5; cursor: not-allowed; }
.btn-save.btn-hire { background: #2ECC71; }
.btn-save.btn-fire { background: #E74C3C; }
.warning-text { font-size: 13px; color: var(--text-secondary); margin: 0; line-height: 1.4; }
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--bg-card); color: var(--text-primary); border: 1px solid #E67E22; border-left-width: 4px; border-radius: 10px; padding: 12px 16px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 24px rgba(0,0,0,0.3); z-index: 200; }
</style>
