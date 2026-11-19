<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    :activeKey="activeTab"
    title="Panel de Taller y Mecánica"
    subtitle="Tus órdenes, repuestos solicitados y trabajos realizados"
    @navigate="activeTab = $event"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <template #header-extra>
      <div class="role-chip"><Wrench :size="14" /><span>{{ currentMechanic.name }}</span></div>
    </template>

    <section class="card main-card">
      <!-- Encabezado común a las 3 secciones -->
      <div class="main-header">
        <div class="header-left">
          <MetricsMenu :items="menuItems">
            <template #ordenes>
              <div class="mm-toolbar">
                <div class="mm-field">
                  <label>Filtrar órdenes</label>
                  <select v-model="orderFilter" class="mm-select">
                    <option value="all">Todas mis órdenes</option>
                    <option value="DIAGNÓSTICO">En diagnóstico</option>
                    <option value="PENDIENTE">Pendientes</option>
                    <option value="EN_PROCESO">En proceso</option>
                    <option value="FINALIZADA">Terminadas (finalizadas)</option>
                    <option value="ENTREGADA">Entregadas</option>
                  </select>
                </div>
              </div>
              <div class="mm-stats">
                <div class="mm-stat"><span>Mostrando</span><strong>{{ panelOrders.length }}</strong></div>
                <div class="mm-stat"><span>En proceso</span><strong class="mm-blue">{{ countByEstado('EN_PROCESO') }}</strong></div>
                <div class="mm-stat"><span>Terminadas</span><strong class="mm-green">{{ countByEstado('FINALIZADA') + countByEstado('ENTREGADA') }}</strong></div>
              </div>
              <div class="mm-list">
                <button v-for="o in panelOrders" :key="o.id" class="mm-row" @click="openDetail(o.id)">
                  <div class="mm-row-main"><strong>{{ o.moto }} · {{ o.placa }}</strong><small>{{ o.code }} · {{ o.servicio }}</small></div>
                  <div class="mm-row-end"><span :class="['estado-badge', estadoClass(o.estado)]">{{ estadoLabel(o.estado) }}</span><small>{{ formatDuration(elapsedSec(o)) }}</small></div>
                </button>
              </div>
              <p v-if="!panelOrders.length" class="mm-empty">No hay órdenes con ese estado.</p>
            </template>

            <template #tiempo>
              <div class="mm-stats">
                <div class="mm-stat"><span>Tiempo total trabajado</span><strong class="mm-orange">{{ formatDuration(totalWorkedSec) }}</strong></div>
                <div class="mm-stat"><span>Promedio por trabajo terminado</span><strong>{{ formatDuration(avgFinishedSec) }}</strong></div>
              </div>
              <h4 class="mm-section-title">Tiempo real por orden</h4>
              <div class="mm-list">
                <button v-for="o in timeRanking" :key="o.id" class="mm-row" @click="openDetail(o.id)">
                  <div class="mm-row-main">
                    <strong>{{ o.moto }} · {{ o.placa }}</strong>
                    <small>{{ o.code }} · {{ estadoLabel(o.estado) }}</small>
                    <div class="mm-bar"><i :style="{ width: rankPct(o) + '%', background: '#E67E22' }"></i></div>
                  </div>
                  <div class="mm-row-end">{{ formatDuration(elapsedSec(o)) }}</div>
                </button>
              </div>
            </template>

            <template #repuestos>
              <div class="mm-toolbar">
                <div class="mm-field">
                  <label>Urgencia</label>
                  <select v-model="urgFilter" class="mm-select">
                    <option value="all">Todas las urgencias</option>
                    <option value="Alta">Urgentes</option>
                    <option value="Media">Urgencia media</option>
                    <option value="Baja">Urgencia baja</option>
                  </select>
                </div>
                <div class="mm-field">
                  <label>Estado de la solicitud</label>
                  <select v-model="partStateFilter" class="mm-select">
                    <option value="Solicitada">Por aprobar</option>
                    <option value="Aprobada">Aprobadas</option>
                    <option value="Rechazada">Rechazadas</option>
                    <option value="all">Todas</option>
                  </select>
                </div>
              </div>
              <div class="mm-stats">
                <div class="mm-stat"><span>Por aprobar</span><strong class="mm-yellow">{{ pendingPartsCount }}</strong></div>
                <div class="mm-stat"><span>Urgentes</span><strong class="mm-red">{{ urgentPendingCount }}</strong></div>
              </div>
              <div class="mm-list">
                <button v-for="r in panelParts" :key="r.order.id + '-' + r.id" class="mm-row" @click="openDetail(r.order.id)">
                  <div class="mm-row-main"><strong>{{ r.qty }}× {{ r.name }}</strong><small>{{ r.order.code }} · {{ r.order.moto }} ({{ r.order.placa }})</small></div>
                  <div class="mm-row-end">
                    <span :class="['mm-tag', urgTone(r.urgencia)]">{{ urgLabel(r.urgencia) }}</span>
                    <span :class="['mm-tag', partTone(r.estado)]">{{ r.estado === 'Solicitada' ? 'Por aprobar' : r.estado }}</span>
                  </div>
                </button>
              </div>
              <p v-if="!panelParts.length" class="mm-empty">No hay solicitudes con ese filtro.</p>
            </template>
          </MetricsMenu>

          <div class="header-titles">
            <h3>{{ tabInfo.title }}</h3>
            <p>{{ tabInfo.sub }}</p>
          </div>
        </div>

        <div class="controls">
          <div class="search-box">
            <Search :size="16" class="search-ico" />
            <input v-model="search[activeTab]" type="text" :placeholder="tabInfo.placeholder" class="search-input" />
          </div>
          <div v-if="activeTab !== 'ordenes'" class="view-toggle">
            <button :class="['toggle-btn', { active: views[activeTab] === 'list' }]" @click="views[activeTab] = 'list'"><List :size="15" /><span>Lista</span></button>
            <button :class="['toggle-btn', { active: views[activeTab] === 'cards' }]" @click="views[activeTab] = 'cards'"><LayoutGrid :size="15" /><span>Tarjetas</span></button>
          </div>
          <button v-if="activeTab === 'ordenes'" class="btn-primary" @click="openRepairModal"><PlusCircle :size="16" /><span>Añadir reparación</span></button>
        </div>
      </div>

      <!-- 1. MIS ÓRDENES -->
      <template v-if="activeTab === 'ordenes'">
        <p v-if="!filteredOrders.length" class="empty">{{ openOrders.length ? 'No hay órdenes que coincidan con la búsqueda.' : 'No tienes órdenes activas. Usa "Añadir reparación" para registrar una.' }}</p>
        <div class="orders-grid">
          <div v-for="o in filteredOrders" :key="o.id" class="order-card" tabindex="0" @click="openDetail(o.id)" @keydown.enter="openDetail(o.id)">
            <div class="order-top">
              <span class="order-code">{{ o.code }}</span>
              <div class="order-tags">
                <span :class="['priority-pill', priorityClass(o.prioridad)]">{{ o.prioridad }}</span>
                <span :class="['estado-badge', estadoClass(o.estado)]">{{ estadoLabel(o.estado) }}</span>
              </div>
            </div>
            <div class="order-main">
              <span class="order-moto">{{ o.moto }} · {{ o.placa }}</span>
              <h4>{{ o.servicio }}</h4>
              <p class="order-sub">Cliente: {{ o.cliente || '—' }} · {{ formatKm(o.km) }}</p>
            </div>
            <div class="time-block">
              <div class="time-row"><span class="time-label"><Timer :size="14" /> Tiempo real</span><strong>{{ formatDuration(elapsedSec(o)) }}</strong></div>
              <div class="time-track"><div class="time-fill" :style="{ width: timePercent(o) + '%', background: timeColor(o) }"></div></div>
            </div>
            <div class="order-footer">
              <span class="checklist-progress"><CheckSquare :size="14" /> Checklist {{ checklistDoneCount(o) }}/{{ checklistItems.length }}</span>
              <div class="order-actions">
                <button class="btn-icon" :disabled="isClosed(o)" :aria-label="o.startedAt ? 'Pausar cronómetro' : 'Iniciar cronómetro'" @click.stop="toggleTimer(o)">
                  <Pause v-if="o.startedAt" :size="14" /><Play v-else :size="14" />
                </button>
                <button class="btn-action" @click.stop="openManage(o.id)">Gestionar</button>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- 2. REPUESTOS (sin precios) -->
      <template v-else-if="activeTab === 'repuestos'">
        <p v-if="!filteredParts.length" class="empty">No hay repuestos que coincidan con la búsqueda.</p>
        <ProductCollection :items="filteredParts" :view="views.repuestos" :showPrice="false" actionLabel="Solicitar" :actionIcon="PackagePlus" @open="selectedProduct = $event" @action="openRequestModal(null, $event.code)" />
        <p v-if="!requestableOrders.length" class="hint-text">Para solicitar repuestos necesitas una orden activa. Crea una con "Añadir reparación".</p>
      </template>

      <!-- 3. HISTORIAL POR PLACA -->
      <template v-else-if="activeTab === 'historial'">
        <p v-if="!filteredHistory.length" class="empty">{{ historyOrders.length ? 'No hay trabajos con esa placa.' : 'Aún no tienes trabajos finalizados.' }}</p>
        <div v-if="views.historial === 'list'" class="big-list">
          <div v-for="h in filteredHistory" :key="h.id" class="big-row" tabindex="0" @click="openDetail(h.id)" @keydown.enter="openDetail(h.id)">
            <div class="plate-box">{{ h.placa }}</div>
            <div class="big-main"><h4>{{ h.moto }}</h4><span class="big-sub">{{ h.servicio }} · {{ h.fecha }}</span></div>
            <div class="big-end"><span :class="['estado-badge', estadoClass(h.estado)]">{{ estadoLabel(h.estado) }}</span><span class="big-sub">{{ formatDuration(h.realSec) }}</span></div>
          </div>
        </div>
        <div v-else class="big-grid">
          <div v-for="h in filteredHistory" :key="h.id" class="big-card" tabindex="0" @click="openDetail(h.id)" @keydown.enter="openDetail(h.id)">
            <span class="plate-box">{{ h.placa }}</span>
            <span class="order-moto">{{ h.moto }}</span>
            <h4>{{ h.servicio }}</h4>
            <span class="big-sub">{{ h.fecha }} · Tiempo: {{ formatDuration(h.realSec) }}</span>
            <p v-if="h.notas" class="big-notes">{{ h.notas }}</p>
            <div class="big-card-foot"><span :class="['estado-badge', estadoClass(h.estado)]">{{ estadoLabel(h.estado) }}</span><strong class="order-code-or">{{ h.code }}</strong></div>
          </div>
        </div>
      </template>
    </section>

    <!-- DETALLE DE REPUESTO (conserva Solicitar) -->
    <ProductDetailModal v-if="selectedProduct" :product="selectedProduct" :showPrice="false" @close="selectedProduct = null">
      <template #actions>
        <button class="btn-primary big" :disabled="selectedProduct.stock === 0 || !requestableOrders.length" @click="requestFromDetail(selectedProduct.code)"><PackagePlus :size="16" /><span>{{ selectedProduct.stock === 0 ? 'Sin stock' : 'Solicitar' }}</span></button>
      </template>
    </ProductDetailModal>

    <!-- DETALLE DE ORDEN (grande) -->
    <BigModal v-if="detailOrder" :title="detailOrder.code + ' · ' + detailOrder.moto" :subtitle="'Placa ' + detailOrder.placa + ' · ' + detailOrder.servicio" wide @close="detailOrderId = null">
      <div class="status-row">
        <span :class="['estado-badge', estadoClass(detailOrder.estado)]">{{ estadoLabel(detailOrder.estado) }}</span>
        <span :class="['priority-pill', priorityClass(detailOrder.prioridad)]">Prioridad {{ detailOrder.prioridad }}</span>
      </div>
      <div class="detail-grid">
        <div><span>Moto</span><strong>{{ detailOrder.moto }}</strong></div>
        <div><span>Placa</span><strong>{{ detailOrder.placa }}</strong></div>
        <div><span>Cliente</span><strong>{{ detailOrder.cliente || '—' }}</strong></div>
        <div><span>Kilometraje</span><strong>{{ formatKm(detailOrder.km) }}</strong></div>
        <div><span>Ingreso</span><strong>{{ detailOrder.fecha }}</strong></div>
        <div><span>Tiempo real</span><strong>{{ formatDuration(elapsedSec(detailOrder)) }}</strong></div>
      </div>
      <div class="time-block">
        <div class="time-row"><span class="time-label"><Timer :size="14" /> Tiempo real · {{ Math.round(timePercent(detailOrder)) }}% de la jornada (8 h)</span></div>
        <div class="time-track"><div class="time-fill" :style="{ width: timePercent(detailOrder) + '%', background: timeColor(detailOrder) }"></div></div>
      </div>
      <h4 class="mm-section-title">Checklist técnico ({{ checklistDoneCount(detailOrder) }}/{{ checklistItems.length }})</h4>
      <div class="check-readonly">
        <span v-for="item in checklistItems" :key="item.key" :class="['check-pill', { done: detailOrder.checklist[item.key] }]"><Check v-if="detailOrder.checklist[item.key]" :size="13" /><X v-else :size="13" /> {{ item.label }}</span>
      </div>
      <h4 class="mm-section-title">Repuestos solicitados</h4>
      <div class="mm-list">
        <div v-for="pz in detailOrder.piezas" :key="pz.id" class="mm-row">
          <div class="mm-row-main"><strong>{{ pz.qty }}× {{ pz.name }}</strong><small>Urgencia: {{ urgLabel(pz.urgencia) }}</small></div>
          <div class="mm-row-end"><span :class="['mm-tag', partTone(pz.estado)]">{{ pz.estado === 'Solicitada' ? 'Por aprobar' : pz.estado }}</span></div>
        </div>
      </div>
      <p v-if="!detailOrder.piezas.length" class="mm-empty">Sin repuestos solicitados.</p>
      <h4 class="mm-section-title">Notas técnicas</h4>
      <p class="notes-text">{{ detailOrder.notas || 'Sin notas registradas.' }}</p>
      <template #footer>
        <button v-if="detailOrder.estado !== 'ENTREGADA'" class="btn-primary" @click="openManage(detailOrder.id)"><Wrench :size="16" /><span>Gestionar</span></button>
      </template>
    </BigModal>

    <!-- GESTIONAR ORDEN -->
    <BigModal v-if="manageOrder" :title="manageOrder.code + ' · ' + manageOrder.moto" :subtitle="'Placa ' + manageOrder.placa + ' · ' + formatKm(manageOrder.km)" wide @close="manageOrderId = null">
      <div class="status-row">
        <span :class="['estado-badge', estadoClass(manageOrder.estado)]">{{ estadoLabel(manageOrder.estado) }}</span>
        <span :class="['priority-pill', priorityClass(manageOrder.prioridad)]">Prioridad {{ manageOrder.prioridad }}</span>
      </div>
      <p class="modal-service">{{ manageOrder.servicio }}</p>

      <div class="section-box">
        <div class="section-title"><Timer :size="14" /> Tiempo real</div>
        <div class="timer-row">
          <strong class="timer-big">{{ formatDuration(elapsedSec(manageOrder)) }}</strong>
          <span class="timer-est">{{ Math.round(timePercent(manageOrder)) }}% de la jornada (8 h)</span>
          <button class="btn-timer" :disabled="isClosed(manageOrder)" @click="toggleTimer(manageOrder)">
            <Pause v-if="manageOrder.startedAt" :size="14" /><Play v-else :size="14" /><span>{{ manageOrder.startedAt ? 'Pausar' : 'Iniciar' }}</span>
          </button>
        </div>
        <div class="time-track"><div class="time-fill" :style="{ width: timePercent(manageOrder) + '%', background: timeColor(manageOrder) }"></div></div>
      </div>

      <div class="section-box">
        <div class="section-title"><ShieldCheck :size="14" /> Checklist técnico de calidad ({{ checklistDoneCount(manageOrder) }}/{{ checklistItems.length }})</div>
        <label v-for="item in checklistItems" :key="item.key" :class="['check-item', { done: manageOrder.checklist[item.key] }]">
          <input v-model="manageOrder.checklist[item.key]" type="checkbox" :disabled="isClosed(manageOrder)" />
          <span>{{ item.label }}</span>
        </label>
      </div>

      <div class="section-box">
        <div class="section-title section-title-row">
          <span><PackageSearch :size="14" /> Repuestos solicitados</span>
          <button class="btn-mini" :disabled="isClosed(manageOrder)" @click="openRequestModal(manageOrder.id)"><Plus :size="12" /> Solicitar</button>
        </div>
        <p v-if="!manageOrder.piezas.length" class="cart-empty">Aún no has solicitado repuestos para esta orden.</p>
        <div v-for="pz in manageOrder.piezas" :key="pz.id" class="part-line">
          <span>{{ pz.qty }}× {{ pz.name }}</span>
          <span :class="['mm-tag', partTone(pz.estado)]">{{ pz.estado === 'Solicitada' ? 'Por aprobar' : pz.estado }}</span>
        </div>
      </div>

      <div class="form-group">
        <label>Notas técnicas</label>
        <textarea v-model="manageOrder.notas" class="form-input form-textarea" rows="3" placeholder="Hallazgos, medidas, trabajo realizado..."></textarea>
      </div>
      <p v-if="orderError" class="form-error">{{ orderError }}</p>
      <template #footer>
        <span class="hint-text">{{ nextEstado(manageOrder) ? 'Siguiente paso: ' + estadoLabel(nextEstado(manageOrder)) : 'La entrega al cliente la registra Caja o el Administrador.' }}</span>
        <button class="btn-primary" :disabled="!nextEstado(manageOrder)" @click="advanceOrder(manageOrder)">{{ advanceLabel(manageOrder) }}</button>
      </template>
    </BigModal>

    <!-- AÑADIR REPARACIÓN -->
    <div v-if="showRepairModal" class="modal-overlay" @click.self="showRepairModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Añadir reparación</h3><button class="close-btn" aria-label="Cerrar" @click="showRepairModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-row">
            <div class="form-group grow"><label>Placa</label><input v-model="repairForm.placa" type="text" placeholder="Ej: ABC-123" class="form-input" /></div>
            <div class="form-group grow"><label>Moto</label><input v-model="repairForm.moto" type="text" placeholder="Ej: Yamaha FZ 25" class="form-input" /></div>
          </div>
          <div class="form-group"><label>Cliente (opcional)</label><input v-model="repairForm.cliente" type="text" placeholder="Nombre del cliente" class="form-input" /></div>
          <div class="form-group"><label>Servicio o falla reportada</label><input v-model="repairForm.servicio" type="text" placeholder="Ej: Ruido metálico en el motor" class="form-input" /></div>
          <div class="form-row">
            <div class="form-group grow"><label>Prioridad</label><select v-model="repairForm.prioridad" class="form-input"><option>Alta</option><option>Media</option><option>Baja</option></select></div>
            <div class="form-group grow"><label>Kilometraje</label><input v-model.number="repairForm.km" type="number" min="0" placeholder="Ej: 12500" class="form-input" /></div>
          </div>
          <div class="form-group">
            <label>Tiempo real</label>
            <div class="real-time-field"><Timer :size="14" /><span>0 min · se mide con el cronómetro</span></div>
          </div>
          <label class="check-item"><input v-model="repairForm.startTimer" type="checkbox" /><span>Iniciar el cronómetro al registrar</span></label>
          <p v-if="repairError" class="form-error">{{ repairError }}</p>
          <button class="btn-save" @click="saveRepair">Registrar reparación</button>
          <p class="hint-text">La orden queda a tu nombre en estado Diagnóstico.</p>
        </div>
      </div>
    </div>

    <!-- SOLICITAR REPUESTO -->
    <div v-if="showRequestModal" class="modal-overlay modal-top" @click.self="showRequestModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Solicitar repuesto</h3><button class="close-btn" aria-label="Cerrar" @click="showRequestModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group">
            <label>Orden de trabajo</label>
            <select v-model="requestForm.orderId" class="form-input">
              <option value="" disabled>Selecciona una orden</option>
              <option v-for="o in requestableOrders" :key="o.id" :value="o.id">{{ o.code }} — {{ o.moto }} ({{ o.placa }})</option>
            </select>
          </div>
          <div class="form-row">
            <div class="form-group grow">
              <label>Repuesto</label>
              <select v-model="requestForm.partCode" class="form-input">
                <option value="" disabled>Selecciona un repuesto</option>
                <option v-for="p in partsCatalog" :key="p.code" :value="p.code" :disabled="p.stock === 0">{{ p.name }} ({{ p.stock }} u.)</option>
              </select>
            </div>
            <div class="form-group qty-group"><label>Cant.</label><input v-model.number="requestForm.qty" type="number" min="1" class="form-input" /></div>
          </div>
          <div class="form-group">
            <label>Urgencia</label>
            <select v-model="requestForm.urgencia" class="form-input"><option value="Alta">Urgente (la moto está detenida)</option><option value="Media">Media</option><option value="Baja">Baja</option></select>
          </div>
          <p v-if="requestError" class="form-error">{{ requestError }}</p>
          <button class="btn-save" @click="sendRequest">Enviar solicitud</button>
          <p class="hint-text">El Administrador aprueba o rechaza la solicitud. Tú no ves precios.</p>
        </div>
      </div>
    </div>

    <div v-if="toastMessage" class="toast" role="status">{{ toastMessage }}</div>
  </AppShell>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import {
  ClipboardList, Package, History, Wrench, Timer, PackageSearch, PackagePlus, Search, List, LayoutGrid,
  PlusCircle, Plus, X, Play, Pause, CheckSquare, ShieldCheck, Check, Clock
} from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
import MetricsMenu from '../components/MetricsMenu.vue'
import ProductCollection from '../components/ProductCollection.vue'
import ProductDetailModal from '../components/ProductDetailModal.vue'
import BigModal from '../components/BigModal.vue'
import { getProducts } from '../data/productos'

const props = defineProps({ isDarkMode: Boolean, userEmail: { type: String, default: '' } })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'ordenes', label: 'Mis órdenes', icon: ClipboardList },
  { key: 'repuestos', label: 'Repuestos', icon: Package },
  { key: 'historial', label: 'Historial por placa', icon: History }
]
const activeTab = ref('ordenes')
const tabs = {
  ordenes: { title: 'Mis Órdenes de Trabajo', sub: 'Ordenadas por prioridad: solo ves las reparaciones asignadas a ti', placeholder: 'Buscar placa, moto o servicio...' },
  repuestos: { title: 'Consulta Rápida de Repuestos', sub: 'Existencias en bodega. Las solicitudes las aprueba el Administrador', placeholder: 'Buscar repuesto...' },
  historial: { title: 'Historial de Mantenimiento por Placa', sub: 'Trabajos que realizaste: consulta diagnósticos y servicios previos', placeholder: 'Buscar por placa...' }
}
const tabInfo = computed(() => tabs[activeTab.value])
const search = reactive({ ordenes: '', repuestos: '', historial: '' })
const views = reactive({ repuestos: 'cards', historial: 'cards' })

/* ---------- Aviso y reloj de trabajo ---------- */
const toastMessage = ref('')
let toastTimer = null
const showToast = (msg) => { toastMessage.value = msg; clearTimeout(toastTimer); toastTimer = setTimeout(() => { toastMessage.value = '' }, 2800) }
const now = ref(Date.now())
let timer = null
onMounted(() => { timer = setInterval(() => { now.value = Date.now() }, 1000) })
onUnmounted(() => { clearInterval(timer); clearTimeout(toastTimer) })

/* ---------- Mecánico en sesión (simulado por correo) ---------- */
const mechanics = [
  { id: 1, name: 'Carlos Mendoza', keys: ['carlos', 'mendoza'] },
  { id: 2, name: 'Andrés Parra', keys: ['andres', 'parra'] },
  { id: 3, name: 'Mateo Rojas', keys: ['mateo', 'rojas'] }
]
const normalize = (s) => s.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
const currentMechanic = computed(() => {
  const local = normalize((props.userEmail || '').split('@')[0])
  return mechanics.find(m => m.keys.some(k => local.includes(k))) || mechanics[0]
})

/* ---------- Repuestos (sin precios) ---------- */
const partsCatalog = ref(getProducts())
const selectedProduct = ref(null)
const filteredParts = computed(() => {
  const q = search.repuestos.trim().toLowerCase()
  const list = q ? partsCatalog.value.filter(p => p.name.toLowerCase().includes(q) || p.code.toLowerCase().includes(q) || p.category.toLowerCase().includes(q)) : partsCatalog.value
  return [...list].sort((a, b) => a.name.localeCompare(b.name))
})

/* ---------- Órdenes ---------- */
const checklistItems = [
  { key: 'torque', label: 'Torque y tornillería crítica' },
  { key: 'frenos', label: 'Frenos y transmisión (tensión y holgura)' },
  { key: 'electrico', label: 'Sistema eléctrico y luces' },
  { key: 'estanqueidad', label: 'Estanqueidad: sin fugas en empaques intervenidos' },
  { key: 'ruta', label: 'Prueba de ruta aprobada' }
]
const emptyChecklist = () => ({ torque: false, frenos: false, electrico: false, estanqueidad: false, ruta: false })
const allChecked = () => ({ torque: true, frenos: true, electrico: true, estanqueidad: true, ruta: true })

const orders = ref([
  { id: 1, code: '#OT-104', mechanicId: 1, moto: 'Yamaha FZ 25', placa: 'FZ2-250', cliente: 'Carlos Mendoza', servicio: 'Cambio de bujía y ajuste de motor', prioridad: 'Alta', km: 12450, estado: 'EN_PROCESO', realSec: 2400, startedAt: null, checklist: { torque: true, frenos: false, electrico: true, estanqueidad: false, ruta: false }, notas: '', fecha: 'Hoy',
    piezas: [{ id: 1, code: '#REP-104', name: 'Bujía Iridium CR9EIX', qty: 1, estado: 'Aprobada', urgencia: 'Media' }, { id: 2, code: '#REP-101', name: 'Aceite Sintético 10W40 4T (1L)', qty: 1, estado: 'Solicitada', urgencia: 'Baja' }, { id: 3, code: '#REP-105', name: 'Filtro de Aceite Yamaha FZ 25', qty: 1, estado: 'Solicitada', urgencia: 'Media' }] },
  { id: 5, code: '#OT-110', mechanicId: 1, moto: 'Pulsar NS 200', placa: 'NS2-200', cliente: 'Andrea Gómez', servicio: 'Revisión de ruido metálico en el motor', prioridad: 'Media', km: 21300, estado: 'DIAGNÓSTICO', realSec: 0, startedAt: null, checklist: emptyChecklist(), notas: '', fecha: 'Hoy', piezas: [] },
  { id: 2, code: '#OT-108', mechanicId: 2, moto: 'Bajaj Pulsar NS 200', placa: 'NS2-200', cliente: 'Andrea Gómez', servicio: 'Cambio de kit de arrastre', prioridad: 'Media', km: 18200, estado: 'PENDIENTE', realSec: 0, startedAt: null, checklist: emptyChecklist(), notas: '', fecha: 'Hoy',
    piezas: [{ id: 1, code: '#REP-102', name: 'Kit de Arrastre Pulsar NS 200', qty: 1, estado: 'Solicitada', urgencia: 'Alta' }] },
  { id: 3, code: '#OT-097', mechanicId: 1, moto: 'Yamaha FZ 25', placa: 'XYZ-123', cliente: 'Alejandro Morales', servicio: 'Cambio de aceite y sincronización', prioridad: 'Media', km: 9800, estado: 'ENTREGADA', realSec: 4800, startedAt: null, checklist: allChecked(), notas: 'Cuerpos de aceleración limpiados. Sin fugas.', fecha: 'Hace 2 semanas',
    piezas: [{ id: 1, code: '#REP-101', name: 'Aceite Sintético 10W40 4T (1L)', qty: 1, estado: 'Aprobada', urgencia: 'Baja' }] },
  { id: 4, code: '#OT-081', mechanicId: 2, moto: 'Pulsar NS 200', placa: 'ABC-789', cliente: 'Diana Marcela', servicio: 'Reemplazo de kit de arrastre', prioridad: 'Alta', km: 15600, estado: 'ENTREGADA', realSec: 7200, startedAt: null, checklist: allChecked(), notas: 'Tensión de cadena ajustada a especificación.', fecha: 'Hace 1 mes',
    piezas: [{ id: 1, code: '#REP-102', name: 'Kit de Arrastre Pulsar NS 200', qty: 1, estado: 'Aprobada', urgencia: 'Alta' }] }
])

const myOrders = computed(() => orders.value.filter(o => o.mechanicId === currentMechanic.value.id))
const isClosed = (o) => o.estado === 'FINALIZADA' || o.estado === 'ENTREGADA'
const PRIORITY_WEIGHT = { Alta: 0, Media: 1, Baja: 2 }
const openOrders = computed(() => myOrders.value.filter(o => o.estado !== 'ENTREGADA').sort((a, b) => (a.estado === 'FINALIZADA') - (b.estado === 'FINALIZADA') || PRIORITY_WEIGHT[a.prioridad] - PRIORITY_WEIGHT[b.prioridad] || a.code.localeCompare(b.code)))
const filteredOrders = computed(() => {
  const q = search.ordenes.trim().toLowerCase()
  return q ? openOrders.value.filter(o => o.placa.toLowerCase().includes(q) || o.moto.toLowerCase().includes(q) || o.servicio.toLowerCase().includes(q)) : openOrders.value
})

const ESTADO_FLOW = ['DIAGNÓSTICO', 'PENDIENTE', 'EN_PROCESO', 'FINALIZADA']
const estadoLabel = (e) => ({ 'DIAGNÓSTICO': 'Diagnóstico', PENDIENTE: 'Pendiente', EN_PROCESO: 'En proceso', FINALIZADA: 'Finalizada', ENTREGADA: 'Entregada' }[e] || e)
const estadoClass = (e) => ({ 'DIAGNÓSTICO': 'st-diag', PENDIENTE: 'st-pend', EN_PROCESO: 'st-proc', FINALIZADA: 'st-fin', ENTREGADA: 'st-ent' }[e] || '')
const priorityClass = (p) => (p === 'Alta' ? 'prio-high' : p === 'Media' ? 'prio-mid' : 'prio-low')
const nextEstado = (o) => { const i = ESTADO_FLOW.indexOf(o.estado); return i >= 0 && i < ESTADO_FLOW.length - 1 ? ESTADO_FLOW[i + 1] : null }
const advanceLabel = (o) => { const n = nextEstado(o); return !n ? (o.estado === 'FINALIZADA' ? 'Esperando entrega' : 'Orden cerrada') : n === 'FINALIZADA' ? 'Marcar como finalizada' : `Pasar a ${estadoLabel(n)}` }
const checklistDoneCount = (o) => Object.values(o.checklist).filter(Boolean).length
const formatKm = (km) => (km || km === 0 ? `${Number(km).toLocaleString('es-CO')} km` : 'Km sin registrar')

/* ---------- Tiempo real (cronómetro) ---------- */
const SHIFT_SEC = 8 * 3600
const elapsedSec = (o) => o.realSec + (o.startedAt ? Math.max(0, (now.value - o.startedAt) / 1000) : 0)
const formatDuration = (sec) => { const m = Math.floor(sec / 60); const h = Math.floor(m / 60); return h > 0 ? `${h} h ${String(m % 60).padStart(2, '0')} min` : `${m} min` }
const timePercent = (o) => Math.min(100, (elapsedSec(o) / SHIFT_SEC) * 100)
const timeColor = (o) => { const p = timePercent(o); return p < 50 ? '#2ECC71' : p < 85 ? '#F1C40F' : '#E74C3C' }
const pauseTimer = (o) => { if (!o.startedAt) return; o.realSec += Math.max(0, (Date.now() - o.startedAt) / 1000); o.startedAt = null }
const toggleTimer = (o) => {
  if (isClosed(o)) return
  if (o.startedAt) { pauseTimer(o); return }
  myOrders.value.forEach(x => { if (x !== o) pauseTimer(x) })
  o.startedAt = Date.now()
}

/* ---------- Menú de indicadores ---------- */
const countByEstado = (e) => myOrders.value.filter(o => o.estado === e).length
const activeOrdersCount = computed(() => myOrders.value.filter(o => !isClosed(o)).length)
const orderFilter = ref('all')
const panelOrders = computed(() => myOrders.value.filter(o => orderFilter.value === 'all' || o.estado === orderFilter.value))

const totalWorkedSec = computed(() => myOrders.value.reduce((a, o) => a + elapsedSec(o), 0))
const finishedOrders = computed(() => myOrders.value.filter(isClosed))
const avgFinishedSec = computed(() => (finishedOrders.value.length ? finishedOrders.value.reduce((a, o) => a + o.realSec, 0) / finishedOrders.value.length : 0))
const timeRanking = computed(() => [...myOrders.value].sort((a, b) => elapsedSec(b) - elapsedSec(a)))
const rankPct = (o) => { const max = Math.max(1, ...myOrders.value.map(elapsedSec)); return Math.round((elapsedSec(o) / max) * 100) }

const urgFilter = ref('all')
const partStateFilter = ref('Solicitada')
const URG_WEIGHT = { Alta: 0, Media: 1, Baja: 2 }
const urgLabel = (u) => (u === 'Alta' ? 'Urgente' : u === 'Media' ? 'Media' : 'Baja')
const urgTone = (u) => (u === 'Alta' ? 'danger' : u === 'Media' ? 'warning' : 'info')
const partTone = (s) => (s === 'Aprobada' ? 'success' : s === 'Rechazada' ? 'danger' : 'warning')
const allParts = computed(() => myOrders.value.flatMap(o => o.piezas.map(p => ({ ...p, order: o }))))
const panelParts = computed(() => allParts.value
  .filter(r => (urgFilter.value === 'all' || r.urgencia === urgFilter.value) && (partStateFilter.value === 'all' || r.estado === partStateFilter.value))
  .sort((a, b) => URG_WEIGHT[a.urgencia] - URG_WEIGHT[b.urgencia]))
const pendingPartsCount = computed(() => allParts.value.filter(r => r.estado === 'Solicitada').length)
const urgentPendingCount = computed(() => allParts.value.filter(r => r.estado === 'Solicitada' && r.urgencia === 'Alta').length)

const menuItems = computed(() => [
  { key: 'ordenes', label: 'Órdenes', value: `${activeOrdersCount.value} activas`, icon: Wrench, tone: 'orange' },
  { key: 'tiempo', label: 'Tiempo de trabajo', value: formatDuration(totalWorkedSec.value), icon: Clock, tone: 'blue' },
  { key: 'repuestos', label: 'Repuestos por aprobar', value: `${pendingPartsCount.value} ${pendingPartsCount.value === 1 ? 'solicitud' : 'solicitudes'}`, icon: PackageSearch, tone: 'yellow' }
])

/* ---------- Detalle y gestión ---------- */
const detailOrderId = ref(null)
const manageOrderId = ref(null)
const orderError = ref('')
const detailOrder = computed(() => myOrders.value.find(o => o.id === detailOrderId.value) || null)
const manageOrder = computed(() => myOrders.value.find(o => o.id === manageOrderId.value) || null)
const openDetail = (id) => { detailOrderId.value = id }
const openManage = (id) => { detailOrderId.value = null; manageOrderId.value = id; orderError.value = '' }

const advanceOrder = (o) => {
  const next = nextEstado(o)
  if (!next) return
  if (next === 'FINALIZADA' && checklistDoneCount(o) < checklistItems.length) { orderError.value = 'Completa todo el checklist técnico (incluida la prueba de ruta) antes de finalizar.'; return }
  orderError.value = ''
  if (next === 'FINALIZADA') pauseTimer(o)
  o.estado = next
  showToast(`${o.code} pasó a ${estadoLabel(next)}.`)
}

/* ---------- Añadir reparación ---------- */
const showRepairModal = ref(false)
const repairError = ref('')
const defaultRepair = () => ({ placa: '', moto: '', cliente: '', servicio: '', prioridad: 'Media', km: null, startTimer: false })
const repairForm = ref(defaultRepair())
const openRepairModal = () => { repairForm.value = defaultRepair(); repairError.value = ''; showRepairModal.value = true }
const saveRepair = () => {
  const f = repairForm.value
  if (!f.placa.trim() || !f.moto.trim()) { repairError.value = 'Ingresa la placa y la moto.'; return }
  if (!f.servicio.trim()) { repairError.value = 'Describe el servicio o la falla reportada.'; return }
  const maxNum = orders.value.reduce((a, o) => Math.max(a, parseInt(o.code.replace(/\D/g, ''), 10) || 0), 0)
  const order = {
    id: Date.now(), code: `#OT-${maxNum + 1}`, mechanicId: currentMechanic.value.id, moto: f.moto.trim(), placa: f.placa.trim().toUpperCase(),
    cliente: f.cliente.trim(), servicio: f.servicio.trim(), prioridad: f.prioridad, km: f.km === null || f.km === '' ? null : Number(f.km),
    estado: 'DIAGNÓSTICO', realSec: 0, startedAt: null, checklist: emptyChecklist(), notas: '', fecha: 'Hoy', piezas: []
  }
  orders.value.push(order)
  if (f.startTimer) toggleTimer(orders.value.find(o => o.id === order.id))
  showRepairModal.value = false
  activeTab.value = 'ordenes'
  showToast('Reparación registrada a tu nombre.')
}

/* ---------- Solicitar repuestos ---------- */
const requestableOrders = computed(() => myOrders.value.filter(o => !isClosed(o)))
const showRequestModal = ref(false)
const requestError = ref('')
const requestForm = ref({ orderId: '', partCode: '', qty: 1, urgencia: 'Media' })
const openRequestModal = (orderId = null, partCode = null) => {
  requestForm.value = { orderId: orderId || (requestableOrders.value.length === 1 ? requestableOrders.value[0].id : ''), partCode: partCode || '', qty: 1, urgencia: 'Media' }
  requestError.value = ''
  showRequestModal.value = true
}
const requestFromDetail = (code) => { selectedProduct.value = null; openRequestModal(null, code) }
const sendRequest = () => {
  const f = requestForm.value
  const order = myOrders.value.find(o => o.id === f.orderId)
  const part = partsCatalog.value.find(p => p.code === f.partCode)
  const qty = Number(f.qty)
  if (!order) { requestError.value = 'Selecciona la orden para la que necesitas el repuesto.'; return }
  if (!part) { requestError.value = 'Selecciona un repuesto.'; return }
  if (!qty || qty < 1) { requestError.value = 'La cantidad debe ser al menos 1.'; return }
  if (qty > part.stock) { requestError.value = `Solo hay ${part.stock} u. disponibles de "${part.name}".`; return }
  order.piezas.push({ id: Date.now(), code: part.code, name: part.name, qty, estado: 'Solicitada', urgencia: f.urgencia })
  showRequestModal.value = false
  showToast('Solicitud enviada al Administrador.')
}

/* ---------- Historial ---------- */
const historyOrders = computed(() => myOrders.value.filter(isClosed))
const filteredHistory = computed(() => {
  const q = search.historial.trim().toLowerCase()
  return q ? historyOrders.value.filter(h => h.placa.toLowerCase().includes(q)) : historyOrders.value
})
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; }
.main-card { display: flex; flex-direction: column; gap: 22px; }
.main-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px; }
.header-left { display: flex; align-items: center; gap: 14px; }
.header-titles h3 { font-size: 17px; font-weight: 600; margin: 0 0 4px; }
.header-titles p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.controls { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.role-chip { display: flex; align-items: center; gap: 6px; background: rgba(230, 126, 34, 0.12); color: #E67E22; border: 1px solid rgba(230, 126, 34, 0.4); border-radius: 999px; padding: 6px 12px; font-size: 12px; font-weight: 700; white-space: nowrap; }
.search-box { position: relative; display: flex; align-items: center; }
.search-ico { position: absolute; left: 12px; color: var(--text-secondary); }
.search-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 8px 14px 8px 36px; color: var(--text-primary); font-size: 12px; outline: none; width: 230px; height: 40px; box-sizing: border-box; }
.search-input:focus { border-color: #E67E22; }
.view-toggle { display: flex; background: var(--input-bg); border: 1px solid var(--border-color); padding: 4px; border-radius: 10px; gap: 4px; height: 40px; box-sizing: border-box; align-items: center; }
.toggle-btn { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; }
.toggle-btn:hover { color: #E67E22; }
.toggle-btn.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.btn-primary { background-color: #E67E22; color: #FFFFFF; border: none; border-radius: 10px; padding: 8px 16px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 8px; height: 40px; transition: background-color 0.2s; }
.btn-primary:hover:not(:disabled) { background-color: #D35400; }
.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
.btn-primary.big { height: 46px; padding: 0 22px; font-size: 14px; }
.empty, .hint-text { font-size: 13px; color: var(--text-secondary); margin: 0; }
.hint-text { font-size: 12px; }

.orders-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(400px, 1fr)); gap: 22px; }
.order-card { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 18px; padding: 24px; display: flex; flex-direction: column; gap: 16px; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; }
.order-card:hover { transform: translateY(-3px); box-shadow: 0 12px 26px rgba(0, 0, 0, 0.2); border-color: #E67E22; }
.order-top { display: flex; justify-content: space-between; align-items: center; gap: 8px; flex-wrap: wrap; }
.order-code { font-size: 13px; font-weight: 700; color: var(--text-secondary); }
.order-tags { display: flex; gap: 6px; }
.order-main { display: flex; flex-direction: column; gap: 4px; }
.order-moto { font-size: 12px; font-weight: 700; color: var(--text-secondary); }
.order-main h4 { font-size: 20px; font-weight: 700; margin: 0; line-height: 1.25; }
.order-sub { font-size: 13px; color: var(--text-secondary); margin: 0; }
.time-block { display: flex; flex-direction: column; gap: 8px; }
.time-row { display: flex; justify-content: space-between; align-items: center; font-size: 12px; color: var(--text-secondary); gap: 8px; }
.time-label { display: flex; align-items: center; gap: 5px; }
.time-row strong { font-size: 15px; color: var(--text-primary); }
.time-track { height: 8px; border-radius: 999px; background: var(--border-color); overflow: hidden; }
.time-fill { height: 100%; border-radius: 999px; transition: width 0.4s ease; }
.order-footer { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-color); padding-top: 14px; gap: 8px; }
.checklist-progress { display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--text-secondary); }
.order-actions { display: flex; align-items: center; gap: 8px; }
.btn-icon { background: rgba(230, 126, 34, 0.12); color: #E67E22; border: 1px solid #E67E22; width: 34px; height: 34px; border-radius: 8px; cursor: pointer; display: flex; align-items: center; justify-content: center; transition: all 0.2s; }
.btn-icon:hover:not(:disabled) { background: #E67E22; color: #FFFFFF; }
.btn-icon:disabled { opacity: 0.4; cursor: not-allowed; }
.btn-action { background: rgba(230, 126, 34, 0.15); color: #E67E22; border: 1px solid #E67E22; padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
.btn-action:hover { background: #E67E22; color: #FFFFFF; }

.estado-badge { font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; white-space: nowrap; }
.st-diag { background: rgba(121, 134, 203, 0.2); color: #7986CB; }
.st-pend { background: rgba(241, 196, 15, 0.15); color: #F1C40F; }
.st-proc { background: rgba(38, 198, 218, 0.15); color: #26C6DA; }
.st-fin { background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.st-ent { background: #1E8449; color: #FFFFFF; }
.priority-pill { font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; }
.prio-high { background: rgba(231, 76, 60, 0.15); color: #E74C3C; }
.prio-mid { background: rgba(241, 196, 15, 0.15); color: #F1C40F; }
.prio-low { background: rgba(149, 165, 166, 0.2); color: #95A5A6; }

.big-list { display: flex; flex-direction: column; gap: 14px; }
.big-row { display: flex; align-items: center; gap: 20px; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 16px; padding: 20px 24px; cursor: pointer; transition: transform 0.2s, border-color 0.2s; }
.big-row:hover { transform: translateX(4px); border-color: #E67E22; }
.big-main { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.big-main h4 { margin: 0; font-size: 19px; }
.big-sub { font-size: 14px; color: var(--text-secondary); }
.big-end { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; }
.plate-box { background: rgba(241, 196, 15, 0.15); color: #F1C40F; font-weight: 800; font-size: 14px; padding: 6px 12px; border-radius: 8px; white-space: nowrap; align-self: flex-start; }
.big-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(330px, 1fr)); gap: 22px; }
.big-card { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 20px; padding: 24px; display: flex; flex-direction: column; gap: 8px; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; }
.big-card:hover { transform: translateY(-4px); box-shadow: 0 12px 26px rgba(0, 0, 0, 0.2); border-color: #E67E22; }
.big-card h4 { margin: 2px 0 0; font-size: 20px; line-height: 1.25; }
.big-notes { margin: 4px 0 0; font-size: 13px; line-height: 1.5; color: var(--text-secondary); }
.big-card-foot { display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-color); padding-top: 12px; margin-top: 8px; }
.order-code-or { color: #E67E22; font-size: 14px; }

.status-row { display: flex; gap: 8px; flex-wrap: wrap; }
.modal-service { font-size: 16px; font-weight: 600; margin: 0; }
.detail-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.detail-grid div { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 12px 14px; display: flex; flex-direction: column; gap: 4px; }
.detail-grid span { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.4px; }
.detail-grid strong { font-size: 15px; }
.check-readonly { display: flex; flex-wrap: wrap; gap: 8px; }
.check-pill { display: flex; align-items: center; gap: 6px; font-size: 12px; padding: 6px 12px; border-radius: 999px; background: rgba(231, 76, 60, 0.12); color: #E74C3C; }
.check-pill.done { background: rgba(46, 204, 113, 0.14); color: #2ECC71; }
.notes-text { margin: 0; font-size: 14px; line-height: 1.55; color: var(--text-secondary); }
.section-box { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
.section-title { display: flex; align-items: center; gap: 6px; font-size: 12px; font-weight: 700; color: var(--text-secondary); }
.section-title-row { justify-content: space-between; }
.section-title-row > span { display: flex; align-items: center; gap: 6px; }
.timer-row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.timer-big { font-size: 24px; }
.timer-est { font-size: 12px; color: var(--text-secondary); flex: 1; }
.btn-timer { background: rgba(230, 126, 34, 0.15); color: #E67E22; border: 1px solid #E67E22; border-radius: 8px; padding: 7px 14px; font-size: 12px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; }
.btn-timer:hover:not(:disabled) { background: #E67E22; color: #FFFFFF; }
.btn-timer:disabled { opacity: 0.4; cursor: not-allowed; }
.check-item { display: flex; align-items: center; gap: 10px; font-size: 13px; padding: 6px 4px; border-radius: 6px; cursor: pointer; }
.check-item:hover { background: rgba(230, 126, 34, 0.08); }
.check-item.done span { color: #2ECC71; }
.check-item input { accent-color: #E67E22; width: 16px; height: 16px; }
.cart-empty { font-size: 12px; color: var(--text-secondary); margin: 0; }
.part-line { display: flex; justify-content: space-between; align-items: center; font-size: 13px; padding: 6px 4px; border-top: 1px solid var(--border-color); gap: 8px; }
.btn-mini { background: rgba(230, 126, 34, 0.15); color: #E67E22; border: 1px solid #E67E22; border-radius: 6px; padding: 4px 10px; font-size: 11px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 4px; }
.btn-mini:hover:not(:disabled) { background: #E67E22; color: #FFFFFF; }
.btn-mini:disabled { opacity: 0.4; cursor: not-allowed; }

.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal-overlay.modal-top { z-index: 140; }
.modal-card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; width: 440px; max-width: 100%; max-height: 90vh; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.modal-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
.modal-header h3 { font-size: 16px; margin: 0; font-weight: 600; }
.close-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; }
.close-btn:hover { color: var(--text-primary); }
.modal-body { display: flex; flex-direction: column; gap: 12px; }
.form-row { display: flex; gap: 10px; }
.form-group { display: flex; flex-direction: column; gap: 4px; }
.form-group.grow { flex: 1; min-width: 0; }
.qty-group { width: 80px; }
.form-group label { font-size: 11px; font-weight: 700; color: var(--text-secondary); }
.form-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 8px 12px; color: var(--text-primary); font-size: 13px; outline: none; width: 100%; box-sizing: border-box; font-family: inherit; }
.form-input:focus { border-color: #E67E22; }
.form-textarea { resize: vertical; min-height: 70px; }
.real-time-field { display: flex; align-items: center; gap: 8px; background: var(--input-bg); border: 1px dashed var(--border-color); border-radius: 8px; padding: 9px 12px; font-size: 13px; color: var(--text-secondary); }
.form-error { font-size: 12px; color: #E74C3C; margin: 0; }
.btn-save { background: #E67E22; color: #FFF; border: none; border-radius: 8px; padding: 10px 16px; font-weight: 600; cursor: pointer; transition: background-color 0.2s; }
.btn-save:hover { background: #D35400; }
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--bg-card); color: var(--text-primary); border: 1px solid #E67E22; border-left-width: 4px; border-radius: 10px; padding: 12px 16px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 24px rgba(0,0,0,0.3); z-index: 200; }
@media (max-width: 768px) { .orders-grid { grid-template-columns: 1fr; } .detail-grid { grid-template-columns: 1fr 1fr; } .form-row { flex-direction: column; } .big-row { flex-wrap: wrap; } }
</style>
