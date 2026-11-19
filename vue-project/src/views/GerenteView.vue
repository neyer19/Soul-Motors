<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    activeKey="gerente"
    title="Panel Gerencial - Dirección General"
    subtitle="Análisis de Pérdidas, Ganancias y Rendimiento del Taller"
    @navigate="$emit('change-view', $event)"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <!-- Encabezado exclusivo para la versión PDF / Impresión -->
    <div class="print-header-only">
      <h2>SOUL MOTORS - INFORME GERENCIAL Y FINANCIERO</h2>
      <p>Fecha de Generación: {{ currentDateFormatted }} | Filtro: {{ activeTimeframe }}</p>
      <hr />
    </div>

    <!-- DASHBOARD DE GRÁFICOS INTERACTIVO -->
    <section class="card analytics-dashboard-section">
      <div class="analytics-header">
        <div class="analytics-left">
          <div class="hide-on-print">
            <MetricsMenu :items="menuItems">
              <template #ingresos>
                <div class="mm-seg">
                  <button v-for="t in timeframes" :key="t" :class="{ active: activeTimeframe === t }" @click="activeTimeframe = t">{{ t }}</button>
                </div>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Ingresos</span><strong class="mm-green">$ {{ fmt(currentMetrics.ingresos) }}</strong></div>
                  <div class="mm-stat"><span>Servicios atendidos</span><strong>{{ currentMetrics.servicios }}</strong></div>
                </div>
                <h4 class="mm-section-title">Ingresos por origen</h4>
                <div class="mm-list">
                  <div v-for="r in splitRows(incomeSplit, currentMetrics.ingresos)" :key="r.name" class="mm-row">
                    <div class="mm-row-main"><strong>{{ r.name }}</strong><div class="mm-bar"><i :style="{ width: r.pct + '%', background: '#2ECC71' }"></i></div></div>
                    <div class="mm-row-end">$ {{ fmt(r.amount) }}<small>{{ r.pct }}%</small></div>
                  </div>
                </div>
                <h4 class="mm-section-title">Últimas ganancias</h4>
                <div class="mm-list">
                  <div v-for="t in recentByType('income')" :key="t.id" class="mm-row">
                    <div class="mm-row-main"><strong>{{ t.title }}</strong><small>{{ t.category }} · {{ t.date }}</small></div>
                    <div class="mm-row-end mm-green">+ $ {{ fmt(t.amount) }}</div>
                  </div>
                </div>
              </template>

              <template #egresos>
                <div class="mm-seg">
                  <button v-for="t in timeframes" :key="t" :class="{ active: activeTimeframe === t }" @click="activeTimeframe = t">{{ t }}</button>
                </div>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Pérdidas</span><strong class="mm-red">$ {{ fmt(currentMetrics.egresos) }}</strong></div>
                  <div class="mm-stat"><span>% de los ingresos</span><strong>{{ Math.round((currentMetrics.egresos / currentMetrics.ingresos) * 100) }}%</strong></div>
                </div>
                <h4 class="mm-section-title">Pérdidas por origen</h4>
                <div class="mm-list">
                  <div v-for="r in splitRows(expenseSplit, currentMetrics.egresos)" :key="r.name" class="mm-row">
                    <div class="mm-row-main"><strong>{{ r.name }}</strong><div class="mm-bar"><i :style="{ width: r.pct + '%', background: '#E74C3C' }"></i></div></div>
                    <div class="mm-row-end">$ {{ fmt(r.amount) }}<small>{{ r.pct }}%</small></div>
                  </div>
                </div>
                <h4 class="mm-section-title">Últimos gastos</h4>
                <div class="mm-list">
                  <div v-for="t in recentByType('expense')" :key="t.id" class="mm-row">
                    <div class="mm-row-main"><strong>{{ t.title }}</strong><small>{{ t.category }} · {{ t.date }}</small></div>
                    <div class="mm-row-end mm-red">- $ {{ fmt(t.amount) }}</div>
                  </div>
                </div>
              </template>

              <template #balance>
                <div class="mm-seg">
                  <button v-for="t in timeframes" :key="t" :class="{ active: activeTimeframe === t }" @click="activeTimeframe = t">{{ t }}</button>
                </div>
                <div class="mm-stats">
                  <div class="mm-stat"><span>Balance neto</span><strong class="mm-yellow">$ {{ fmt(currentMetrics.balance) }}</strong></div>
                  <div class="mm-stat"><span>Margen neto</span><strong class="mm-green">{{ margin }}%</strong></div>
                </div>
                <h4 class="mm-section-title">Ingresos frente a pérdidas</h4>
                <div class="mm-list">
                  <div class="mm-row">
                    <div class="mm-row-main"><strong>Ingresos</strong><div class="mm-bar"><i style="width:100%;background:#2ECC71"></i></div></div>
                    <div class="mm-row-end mm-green">$ {{ fmt(currentMetrics.ingresos) }}</div>
                  </div>
                  <div class="mm-row">
                    <div class="mm-row-main"><strong>Pérdidas</strong><div class="mm-bar"><i :style="{ width: Math.round((currentMetrics.egresos / currentMetrics.ingresos) * 100) + '%', background: '#E74C3C' }"></i></div></div>
                    <div class="mm-row-end mm-red">$ {{ fmt(currentMetrics.egresos) }}</div>
                  </div>
                  <div class="mm-row">
                    <div class="mm-row-main"><strong>Balance</strong><div class="mm-bar"><i :style="{ width: margin + '%', background: '#F1C40F' }"></i></div></div>
                    <div class="mm-row-end mm-yellow">$ {{ fmt(currentMetrics.balance) }}</div>
                  </div>
                </div>
              </template>
            </MetricsMenu>
          </div>

          <div class="analytics-title-group">
            <h3>Rendimiento y Tendencias del Negocio</h3>
            <p>Monitoreo continuo de experiencias de servicio, volumen de reparación y efectividad</p>
          </div>
        </div>

        <div class="header-right hide-on-print">
        <div class="analytics-timeframe-selector">
          <button
            v-for="timeframe in timeframes"
            :key="timeframe"
            :class="['time-tab', activeTimeframe === timeframe && !customMode ? 'active' : '']"
            @click="selectTimeframe(timeframe)"
          >
            {{ timeframe }}
          </button>
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

      <!-- Indicadores Principales -->
      <div class="analytics-summary-bar">
        <div class="summary-metric">
          <span class="metric-label">Experiencia General</span>
          <div class="metric-big-val"><strong>{{ currentMetrics.exp }}</strong><span class="badge-growth positive"><ArrowUpRight :size="14" /> +2.4%</span></div>
        </div>
        <div class="summary-divider"></div>
        <div class="summary-metric">
          <span class="metric-label">Servicios Atendidos</span>
          <div class="metric-big-val"><strong>{{ currentMetrics.servicios }}</strong><span class="badge-growth positive"><ArrowUpRight :size="14" /> +5.1%</span></div>
        </div>
        <div class="summary-divider"></div>
        <div class="summary-metric">
          <span class="metric-label">Motos en Seguimiento</span>
          <div class="metric-big-val"><strong>{{ currentMetrics.motos }}</strong><span class="badge-growth positive"><ArrowUpRight :size="14" /> +12%</span></div>
        </div>
      </div>

      <!-- Controles del gráfico: superponer la 2ª gráfica + filtro de fechas -->
      <div class="chart-toolbar hide-on-print">
        <div class="series-controls">
          <span class="series-chip s-first"><i></i>{{ seriesNames[0] }}</span>
          <button :class="['series-toggle', { on: showSecond }]" @click="showSecond = !showSecond">
            <Layers :size="14" />
            <span>{{ showSecond ? 'Quitar ' + seriesNames[1] : 'Superponer ' + seriesNames[1] }}</span>
          </button>
        </div>

      </div>

      <!-- Resumen del filtro activo -->
      <div v-if="customMode && customSummary" class="custom-banner">
        <div class="banner-main">
          <strong>{{ customSummary.title }}</strong>
          <div v-if="customMode.type === 'comparar'" class="mm-seg-mini hide-on-print">
            <button :class="{ active: compareMetric === 'ingresos' }" @click="compareMetric = 'ingresos'">Ingresos</button>
            <button :class="{ active: compareMetric === 'egresos' }" @click="compareMetric = 'egresos'">Pérdidas</button>
          </div>
        </div>
        <div class="banner-stats">
          <span v-for="st in customSummary.stats" :key="st.label" class="banner-stat">{{ st.label }}: <b :style="{ color: st.color }">{{ st.value }}</b></span>
        </div>
        <button class="banner-clear hide-on-print" @click="clearCustom"><X :size="14" /> Quitar filtro</button>
      </div>

      <!-- Gráfico SVG (más grande): primero una sola gráfica; la otra se superpone al activarla -->
      <div class="chart-container">
        <svg class="chart-svg" viewBox="0 0 900 220" preserveAspectRatio="none">
          <defs>
            <linearGradient id="gradIngresos" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#E67E22" stop-opacity="0.35" />
              <stop offset="100%" stop-color="#E67E22" stop-opacity="0.0" />
            </linearGradient>
            <linearGradient id="gradEgresos" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#3498DB" stop-opacity="0.25" />
              <stop offset="100%" stop-color="#3498DB" stop-opacity="0.0" />
            </linearGradient>
          </defs>
          <line class="grid-line" x1="0" y1="40" x2="900" y2="40" />
          <line class="grid-line" x1="0" y1="100" x2="900" y2="100" />
          <line class="grid-line" x1="0" y1="160" x2="900" y2="160" />
          <path :d="currentChartData.pathIngresosArea" fill="url(#gradIngresos)" />
          <path :d="currentChartData.pathIngresosLine" class="line-ingresos" />
          <g v-if="showSecond" class="second-series">
            <path :d="currentChartData.pathEgresosArea" fill="url(#gradEgresos)" />
            <path :d="currentChartData.pathEgresosLine" class="line-egresos" />
          </g>
        </svg>
        <div :class="['chart-months-axis', { dense: !!customMode }]"><span v-for="(label, i) in currentChartData.labels" :key="i">{{ label }}</span></div>
      </div>

      <!-- Tarjetas secundarias -->
      <div class="mini-kpi-grid">
        <div class="mini-kpi-card">
          <span class="mini-kpi-title">Efectividad Percibida</span>
          <div class="mini-kpi-body"><strong>{{ currentMetrics.efectividad }}</strong><span class="text-success"><ArrowUpRight :size="12" /> +10%</span></div>
          <div class="sparkline"></div>
        </div>
        <div class="mini-kpi-card">
          <span class="mini-kpi-title">Satisfacción del Cliente</span>
          <div class="mini-kpi-body"><strong>{{ currentMetrics.satisfaccion }}</strong><span class="text-success"><ArrowUpRight :size="12" /> +27%</span></div>
          <div class="sparkline"></div>
        </div>
        <div class="mini-kpi-card">
          <span class="mini-kpi-title">Efectividad de Repuestos</span>
          <div class="mini-kpi-body"><strong>98</strong><span class="text-success"><ArrowUpRight :size="12" /> +17%</span></div>
          <div class="sparkline"></div>
        </div>
        <div class="mini-kpi-card">
          <span class="mini-kpi-title">Rentabilidad Taller</span>
          <div class="mini-kpi-body"><strong>34</strong><span class="text-success"><ArrowUpRight :size="12" /> +2.4%</span></div>
          <div class="sparkline"></div>
        </div>
      </div>
    </section>

    <!-- FLUJO DE CAJA Y DESGLOSE FINANCIERO -->
    <section class="card display-section">
      <div class="card-header-flex">
        <div class="header-titles-group">
          <h3>Flujo de Caja y Desglose Financiero</h3>
          <p>Supervisión detallada de transacciones (Filtro activo: <strong>{{ timeFilter.toUpperCase() }}</strong>)</p>
        </div>

        <div class="controls-right-group hide-on-print">
          <div class="time-filter-pills">
            <button :class="['filter-pill', timeFilter === 'dia' ? 'active' : '']" @click="timeFilter = 'dia'">Día</button>
            <button :class="['filter-pill', timeFilter === 'semana' ? 'active' : '']" @click="timeFilter = 'semana'">Semana</button>
            <button :class="['filter-pill', timeFilter === 'mes' ? 'active' : '']" @click="timeFilter = 'mes'">Mes</button>
          </div>

          <div class="search-box-wrapper">
            <Search :size="16" class="search-icon-input" />
            <input v-model="searchQuery" type="text" placeholder="Buscar movimiento..." class="search-input" />
          </div>

          <div class="view-toggle-switch">
            <button :class="['toggle-view-btn', viewMode === 'list' ? 'active' : '']" @click="viewMode = 'list'"><List :size="15" /><span>Lista</span></button>
            <button :class="['toggle-view-btn', viewMode === 'cards' ? 'active' : '']" @click="viewMode = 'cards'"><LayoutGrid :size="15" /><span>Tarjetas</span></button>
          </div>

          <button class="btn-pdf-export" @click="generatePDF"><FileText :size="16" /><span>Reporte PDF</span></button>
        </div>
      </div>

      <!-- Vista Lista -->
      <div v-if="viewMode === 'list'" class="transactions-list">
        <div v-for="item in filteredTransactions" :key="item.id" class="transaction-row">
          <div class="tx-info-group">
            <span class="tx-category">{{ item.category }}</span>
            <h4 class="tx-title">{{ item.title }}</h4>
            <span class="tx-date">{{ item.date }}</span>
          </div>
          <div class="tx-amount-group">
            <span :class="['tx-badge', item.type === 'income' ? 'badge-income' : 'badge-expense']">{{ item.type === 'income' ? 'Ganancia' : 'Pérdida / Gasto' }}</span>
            <span :class="['tx-amount', item.type === 'income' ? 'text-success' : 'text-danger']">{{ item.type === 'income' ? '+ ' : '- ' }} $ {{ item.amount.toLocaleString() }}</span>
            <span class="tx-ref">Ref: {{ item.ref }}</span>
          </div>
        </div>
      </div>

      <!-- Vista Tarjetas -->
      <div v-else class="transactions-cards-grid">
        <div v-for="item in filteredTransactions" :key="item.id" class="card tx-card">
          <div class="tx-card-header">
            <span class="tx-category">{{ item.category }}</span>
            <span :class="['tx-badge', item.type === 'income' ? 'badge-income' : 'badge-expense']">{{ item.type === 'income' ? 'Ganancia' : 'Pérdida / Gasto' }}</span>
          </div>
          <div class="tx-card-body">
            <h4>{{ item.title }}</h4>
            <p class="tx-date">Fecha: {{ item.date }}</p>
          </div>
          <div class="tx-card-footer">
            <span :class="['tx-amount', item.type === 'income' ? 'text-success' : 'text-danger']">{{ item.type === 'income' ? '+ ' : '- ' }} $ {{ item.amount.toLocaleString() }}</span>
            <span class="tx-ref">Ref: {{ item.ref }}</span>
          </div>
        </div>
      </div>
    </section>
  </AppShell>
</template>

<script setup>
import { ref, reactive, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { LayoutDashboard, Package, Users, Search, List, LayoutGrid, FileText, DollarSign, TrendingUp, TrendingDown, ArrowUpRight, CalendarRange, ArrowLeftRight, Layers, X, ChevronDown, ChevronLeft } from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
import MetricsMenu from '../components/MetricsMenu.vue'

defineProps({ isDarkMode: Boolean })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'gerente', label: 'Gerencia', icon: LayoutDashboard },
  { key: 'inventario', label: 'Inventario', icon: Package },
  { key: 'trabajadores', label: 'Trabajadores', icon: Users }
]

const searchQuery = ref('')
const viewMode = ref('cards')
const timeFilter = ref('mes')
const timeframes = ['Semana', 'Mes', 'Trimestre', 'Año']
const activeTimeframe = ref('Mes')

const currentDateFormatted = computed(() => new Date().toLocaleDateString('es-CO', { year: 'numeric', month: 'long', day: 'numeric' }))
const fmt = (n) => Number(n).toLocaleString('es-CO')

const periodData = {
  Semana: { ingresos: 12400000, egresos: 3100000, exp: '96%', servicios: '4,120', motos: '85,400', efectividad: '88', satisfaccion: '82' },
  Mes: { ingresos: 45800000, egresos: 12400000, exp: '94%', servicios: '51,205', motos: '1,056,104', efectividad: '45', satisfaccion: '75' },
  Trimestre: { ingresos: 138500000, egresos: 41200000, exp: '92%', servicios: '154,800', motos: '3,120,000', efectividad: '62', satisfaccion: '78' },
  Año: { ingresos: 540000000, egresos: 165000000, exp: '95%', servicios: '620,000', motos: '12,500,000', efectividad: '79', satisfaccion: '89' }
}
const currentMetrics = computed(() => {
  const p = periodData[activeTimeframe.value]
  return { ...p, balance: p.ingresos - p.egresos }
})
const margin = computed(() => Math.round((currentMetrics.value.balance / currentMetrics.value.ingresos) * 100))

// Desgloses de ejemplo (porcentajes) aplicados al total del periodo
const incomeSplit = [{ name: 'Servicios de taller', pct: 58 }, { name: 'Venta de repuestos', pct: 32 }, { name: 'Otros ingresos', pct: 10 }]
const expenseSplit = [{ name: 'Nómina', pct: 38 }, { name: 'Compra de repuestos', pct: 34 }, { name: 'Gastos operativos', pct: 18 }, { name: 'Otros egresos', pct: 10 }]
const splitRows = (split, total) => split.map(s => ({ ...s, amount: Math.round((total * s.pct) / 100) }))

const menuItems = computed(() => [
  { key: 'ingresos', label: 'Ingresos', value: `$ ${fmt(currentMetrics.value.ingresos)}`, icon: DollarSign, tone: 'green' },
  { key: 'egresos', label: 'Pérdidas', value: `$ ${fmt(currentMetrics.value.egresos)}`, icon: TrendingDown, tone: 'red' },
  { key: 'balance', label: 'Balance neto', value: `$ ${fmt(currentMetrics.value.balance)}`, icon: TrendingUp, tone: 'yellow' }
])

const presetChartData = computed(() => {
  switch (activeTimeframe.value) {
    case 'Semana':
      return { labels: ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB'], pathIngresosArea: 'M 0 140 Q 150 50, 300 100 T 600 60 T 900 90 L 900 220 L 0 220 Z', pathIngresosLine: 'M 0 140 Q 150 50, 300 100 T 600 60 T 900 90', pathEgresosArea: 'M 0 170 Q 150 110, 300 140 T 600 100 T 900 130 L 900 220 L 0 220 Z', pathEgresosLine: 'M 0 170 Q 150 110, 300 140 T 600 100 T 900 130' }
    case 'Trimestre':
      return { labels: ['MES 1', 'MES 2', 'MES 3'], pathIngresosArea: 'M 0 180 Q 250 40, 500 110 T 900 70 L 900 220 L 0 220 Z', pathIngresosLine: 'M 0 180 Q 250 40, 500 110 T 900 70', pathEgresosArea: 'M 0 190 Q 250 90, 500 140 T 900 110 L 900 220 L 0 220 Z', pathEgresosLine: 'M 0 190 Q 250 90, 500 140 T 900 110' }
    case 'Año':
      return { labels: ['Q1', 'Q2', 'Q3', 'Q4'], pathIngresosArea: 'M 0 120 Q 220 90, 450 40 T 900 100 L 900 220 L 0 220 Z', pathIngresosLine: 'M 0 120 Q 220 90, 450 40 T 900 100', pathEgresosArea: 'M 0 160 Q 220 120, 450 80 T 900 140 L 900 220 L 0 220 Z', pathEgresosLine: 'M 0 160 Q 220 120, 450 80 T 900 140' }
    default:
      return { labels: ['FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO'], pathIngresosArea: 'M 0 160 Q 150 70, 300 130 T 600 80 T 900 110 L 900 220 L 0 220 Z', pathIngresosLine: 'M 0 160 Q 150 70, 300 130 T 600 80 T 900 110', pathEgresosArea: 'M 0 180 Q 150 130, 300 160 T 600 120 T 900 150 L 900 220 L 0 220 Z', pathEgresosLine: 'M 0 180 Q 150 130, 300 160 T 600 120 T 900 150' }
  }
})

const transactions = ref([
  { id: 1, title: 'Reparación Motor Pulsar NS200', category: 'SERVICIOS TALLER', date: 'Hoy', amount: 850000, type: 'income', ref: '#101', filter: 'dia' },
  { id: 2, title: 'Compra Repuestos Proveedor Central', category: 'INVENTARIO', date: 'Hoy', amount: 420000, type: 'expense', ref: '#102', filter: 'dia' },
  { id: 3, title: 'Venta Kit de Arrastre FZ', category: 'VENTAS', date: 'Hoy', amount: 350000, type: 'income', ref: '#103', filter: 'dia' },
  { id: 4, title: 'Mantenimiento preventivo flotilla', category: 'SERVICIOS TALLER', date: 'Hace 3 días', amount: 1200000, type: 'income', ref: '#104', filter: 'semana' },
  { id: 5, title: 'Pago de Servicios Públicos Taller', category: 'GASTOS OPERATIVOS', date: 'Hace 4 días', amount: 690000, type: 'expense', ref: '#105', filter: 'semana' },
  { id: 6, title: 'Nómina Quincenal Mecánicos', category: 'PERSONAL', date: 'Hace 15 días', amount: 9500000, type: 'expense', ref: '#106', filter: 'mes' }
])
const recentByType = (type) => transactions.value.filter(t => t.type === type).slice(0, 4)

const filteredTransactions = computed(() => {
  let result = transactions.value
  if (timeFilter.value === 'dia') result = result.filter(i => i.filter === 'dia')
  else if (timeFilter.value === 'semana') result = result.filter(i => i.filter === 'dia' || i.filter === 'semana')
  if (searchQuery.value) {
    const q = searchQuery.value.toLowerCase()
    result = result.filter(i => i.title.toLowerCase().includes(q) || i.category.toLowerCase().includes(q) || i.ref.toLowerCase().includes(q))
  }
  return result
})

const generatePDF = () => { window.print() }

/* =====================================================================
   FILTRO DE FECHAS DE LA GRÁFICA (rango / comparar dos fechas)
   ===================================================================== */
const showSecond = ref(false)          // la 2ª gráfica (Pérdidas / Fecha B) arranca oculta
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

// Convierte una serie en las rutas del SVG (curvas suaves)
const buildPaths = (first, second) => {
  const n = first.length
  const max = Math.max(...first, ...second, 1) * 1.1
  const pts = (vals) => vals.map((v, i) => ({ x: ((i + 0.5) * 900) / n, y: 205 - (v / max) * 175 }))
  const smooth = (p) => {
    let d = `M ${p[0].x.toFixed(1)} ${p[0].y.toFixed(1)}`
    for (let i = 0; i < p.length - 1; i++) {
      const p0 = p[i - 1] || p[i], p1 = p[i], p2 = p[i + 1], p3 = p[i + 2] || p2
      d += ` C ${(p1.x + (p2.x - p0.x) / 6).toFixed(1)} ${(p1.y + (p2.y - p0.y) / 6).toFixed(1)}, ${(p2.x - (p3.x - p1.x) / 6).toFixed(1)} ${(p2.y - (p3.y - p1.y) / 6).toFixed(1)}, ${p2.x.toFixed(1)} ${p2.y.toFixed(1)}`
    }
    return d
  }
  const area = (p) => `${smooth(p)} L ${p[p.length - 1].x.toFixed(1)} 220 L ${p[0].x.toFixed(1)} 220 Z`
  const a = pts(first), b = pts(second)
  return { pathIngresosLine: smooth(a), pathIngresosArea: area(a), pathEgresosLine: smooth(b), pathEgresosArea: area(b) }
}

// Lo que realmente dibuja el gráfico: periodos normales o el filtro de fechas
const currentChartData = computed(() => {
  const cs = customSeries.value
  if (!cs) return presetChartData.value
  return { labels: cs.labels, ...buildPaths(cs.first, cs.second) }
})

const seriesNames = computed(() => {
  const c = customMode.value
  if (c && c.type === 'comparar') return [fmtShort(c.a), fmtShort(c.b)]
  return ['Ingresos', 'Pérdidas']
})

const customSummary = computed(() => {
  const c = customMode.value
  const cs = customSeries.value
  if (!c || !cs) return null
  const money = (n) => `$ ${fmt(n)}`
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
      { label: 'Pérdidas', value: money(egr), color: '#E74C3C' },
      { label: 'Balance', value: money(ing - egr), color: '#F1C40F' }
    ]
  }
})
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; }
.text-success { color: #2ECC71; }
.text-danger { color: #E74C3C; }
.print-header-only { display: none; }

.analytics-dashboard-section { display: flex; flex-direction: column; gap: 20px; }
.analytics-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
.analytics-left { display: flex; align-items: center; gap: 14px; }
.analytics-title-group h3 { font-size: 17px; font-weight: 600; margin: 0 0 4px 0; }
.analytics-title-group p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.analytics-timeframe-selector { display: flex; background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 4px; gap: 4px; }
.time-tab { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; transition: all 0.2s; }
.time-tab:hover { color: #E67E22; }
.time-tab.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.analytics-summary-bar { display: flex; align-items: center; gap: 24px; background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 16px 24px; flex-wrap: wrap; }
.summary-metric { display: flex; flex-direction: column; gap: 4px; }
.metric-label { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; }
.metric-big-val { display: flex; align-items: center; gap: 10px; font-size: 20px; font-weight: 800; }
.badge-growth { display: flex; align-items: center; gap: 2px; font-size: 11px; font-weight: 700; padding: 2px 6px; border-radius: 6px; }
.badge-growth.positive { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.summary-divider { width: 1px; height: 32px; background-color: var(--border-color); }
.chart-container { display: flex; flex-direction: column; gap: 10px; background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 22px; }
.chart-svg { width: 100%; height: 420px; }
.grid-line { stroke: var(--border-color); stroke-dasharray: 4; stroke-width: 1; vector-effect: non-scaling-stroke; }
.line-ingresos { fill: none; stroke: #E67E22; stroke-width: 3; stroke-linecap: round; vector-effect: non-scaling-stroke; }
.line-egresos { fill: none; stroke: #3498DB; stroke-width: 2.5; stroke-linecap: round; stroke-dasharray: 2 2; vector-effect: non-scaling-stroke; }
.chart-months-axis { display: flex; justify-content: space-between; font-size: 11px; font-weight: 700; color: var(--text-secondary); padding: 0 10px; }
.mini-kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; }
.mini-kpi-card { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px; display: flex; flex-direction: column; gap: 8px; }
.mini-kpi-title { font-size: 11px; color: var(--text-secondary); font-weight: 600; }
.mini-kpi-body { display: flex; justify-content: space-between; align-items: center; font-size: 16px; font-weight: 700; }
.mini-kpi-body span { display: flex; align-items: center; gap: 2px; font-size: 11px; }
.sparkline { height: 4px; border-radius: 2px; background: linear-gradient(90deg, transparent, #2ECC71); }

.display-section { display: flex; flex-direction: column; gap: 20px; }
.card-header-flex { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; }
.header-titles-group h3 { font-size: 16px; font-weight: 600; margin: 0 0 4px 0; }
.header-titles-group p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.controls-right-group { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.time-filter-pills { display: flex; background-color: var(--input-bg); border: 1px solid var(--border-color); padding: 4px; border-radius: 10px; gap: 4px; }
.filter-pill { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; }
.filter-pill.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.search-box-wrapper { position: relative; display: flex; align-items: center; }
.search-icon-input { position: absolute; left: 12px; color: var(--text-secondary); }
.search-input { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 8px 14px 8px 36px; color: var(--text-primary); font-size: 12px; outline: none; width: 160px; }
.view-toggle-switch { display: flex; background-color: var(--input-bg); border: 1px solid var(--border-color); padding: 4px; border-radius: 10px; gap: 4px; }
.toggle-view-btn { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; display: flex; align-items: center; gap: 6px; }
.toggle-view-btn.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.btn-pdf-export { background-color: #E67E22; color: #FFFFFF; border: none; border-radius: 10px; padding: 8px 14px; font-size: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: background-color 0.2s; }
.btn-pdf-export:hover { background-color: #d35400; }

.transactions-list { display: flex; flex-direction: column; gap: 10px; }
.transaction-row { display: flex; justify-content: space-between; align-items: center; background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px 18px; }
.tx-info-group { display: flex; flex-direction: column; gap: 2px; }
.tx-category { font-size: 10px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; }
.tx-title { font-size: 14px; font-weight: 600; margin: 0; }
.tx-date { font-size: 11px; color: var(--text-secondary); }
.tx-amount-group { display: flex; align-items: center; gap: 16px; }
.tx-badge { font-size: 10px; font-weight: 700; padding: 4px 8px; border-radius: 6px; }
.badge-income { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.badge-expense { background: rgba(231, 76, 60, 0.15); color: #E74C3C; }
.tx-amount { font-size: 15px; font-weight: 700; }
.tx-ref { font-size: 11px; color: var(--text-secondary); }
.transactions-cards-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 16px; }
.tx-card { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 14px; padding: 16px; display: flex; flex-direction: column; gap: 12px; }
.tx-card-header { display: flex; justify-content: space-between; align-items: center; }
.tx-card-body h4 { font-size: 14px; font-weight: 600; margin: 0 0 4px 0; }
.tx-card-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-color); padding-top: 10px; }

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
.chart-months-axis.dense { padding: 0; }
.chart-months-axis.dense span { flex: 1; text-align: center; min-width: 0; font-size: 10px; }

/* REGLAS CSS PARA GENERACIÓN DE PDF / IMPRESIÓN */
@media print {
  .hide-on-print { display: none !important; }
  .print-header-only { display: block !important; text-align: center; margin-bottom: 20px; }
  .print-header-only h2 { margin: 0; color: #E67E22; }
  .card { border: 1px solid #CCC !important; background: #FFF !important; color: #000 !important; box-shadow: none !important; page-break-inside: avoid; }
  .metric-big-val strong { color: #000 !important; }
}
</style>
