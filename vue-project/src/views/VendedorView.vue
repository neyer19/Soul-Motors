<template>
  <AppShell
    :isDarkMode="isDarkMode"
    :navItems="navItems"
    :activeKey="activeTab"
    title="Panel de Ventas y Atención al Cliente"
    subtitle="Acceso exclusivo de Vendedor: ventas, catálogo, clientes y citas"
    @navigate="activeTab = $event"
    @toggle-theme="$emit('toggle-theme')"
    @logout="$emit('change-view', 'login')"
  >
    <section class="card main-card">
      <!-- Encabezado común a las 4 secciones -->
      <div class="main-header">
        <div class="header-left">
          <MetricsMenu :items="menuItems">
            <template #ventas>
              <div class="mm-seg">
                <button v-for="p in periods" :key="p.value" :class="{ active: salesPeriod === p.value }" @click="salesPeriod = p.value">{{ p.label }}</button>
              </div>
              <div class="mm-stats">
                <div class="mm-stat"><span>Ventas</span><strong class="mm-green">{{ periodSales.length }}</strong></div>
                <div class="mm-stat"><span>Total del periodo</span><strong class="mm-orange">$ {{ formatCOP(sumSales(periodSales)) }}</strong></div>
              </div>
              <div class="mm-list">
                <div v-for="s in periodSales" :key="s.id" class="mm-row">
                  <div class="mm-row-main"><strong>{{ s.client }}</strong><small>{{ s.code }} · {{ fmtDate(s.date) }} {{ s.time }} · {{ saleSummary(s) }}</small></div>
                  <div class="mm-row-end mm-green">$ {{ formatCOP(s.total) }}<small>{{ s.method }}</small></div>
                </div>
              </div>
              <p v-if="!periodSales.length" class="mm-empty">No hay ventas en este periodo.</p>
            </template>

            <template #total>
              <div class="mm-seg">
                <button v-for="p in periods" :key="p.value" :class="{ active: totalGroup === p.value }" @click="totalGroup = p.value">Por {{ p.label.toLowerCase() }}</button>
              </div>
              <div class="mm-stats">
                <div class="mm-stat"><span>Total vendido</span><strong class="mm-orange">$ {{ formatCOP(sumSales(sales)) }}</strong></div>
                <div class="mm-stat"><span>Ventas registradas</span><strong>{{ sales.length }}</strong></div>
              </div>
              <h4 class="mm-section-title">Total vendido por {{ totalGroup === 'dia' ? 'día' : totalGroup === 'mes' ? 'mes' : 'año' }}</h4>
              <div class="mm-list">
                <div v-for="g in groupedTotals" :key="g.key" class="mm-row">
                  <div class="mm-row-main">
                    <strong>{{ g.label }}</strong>
                    <div class="mm-bar"><i :style="{ width: g.pct + '%', background: '#E67E22' }"></i></div>
                  </div>
                  <div class="mm-row-end">$ {{ formatCOP(g.total) }}<small>{{ g.count }} {{ g.count === 1 ? 'venta' : 'ventas' }}</small></div>
                </div>
              </div>
            </template>

            <template #info>
              <div class="mm-toolbar">
                <div class="mm-field">
                  <label>Disponibilidad</label>
                  <select v-model="infoAvail" class="mm-select">
                    <option value="all">Todos los repuestos</option>
                    <option value="danger">Bajo stock</option>
                    <option value="warning">Stock medio</option>
                    <option value="success">Alto stock</option>
                  </select>
                </div>
                <div class="mm-field">
                  <label>Ordenar por</label>
                  <select v-model="infoSort" class="mm-select">
                    <option value="stock-asc">Menor cantidad disponible</option>
                    <option value="stock-desc">Mayor cantidad disponible</option>
                    <option value="sold-desc">Más vendido</option>
                    <option value="sold-asc">Menos vendido</option>
                  </select>
                </div>
              </div>
              <div class="mm-list">
                <button v-for="p in infoList" :key="p.code" class="mm-row" @click="selectedProduct = p">
                  <div class="mm-row-main">
                    <strong>{{ p.name }}</strong>
                    <small>{{ p.category }} · Stock {{ p.stock }} de {{ p.maxStock }} · Vendidos {{ p.sold }}</small>
                  </div>
                  <div class="mm-row-end"><span :class="['mm-tag', stockLevel(p.stock)]">{{ stockLabel(p.stock) }}</span></div>
                  <div class="mm-mini-bar"><i :style="{ width: stockPct(p), background: stockColor(p.stock) }"></i></div>
                </button>
              </div>
              <p v-if="!infoList.length" class="mm-empty">No hay repuestos con ese filtro.</p>
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
          <div v-if="activeTab !== 'ventas'" class="view-toggle">
            <button :class="['toggle-btn', { active: views[activeTab] === 'list' }]" @click="views[activeTab] = 'list'"><List :size="15" /><span>Lista</span></button>
            <button :class="['toggle-btn', { active: views[activeTab] === 'cards' }]" @click="views[activeTab] = 'cards'"><LayoutGrid :size="15" /><span>Tarjetas</span></button>
          </div>
          <button v-if="activeTab === 'ventas'" class="btn-primary" @click="openSaleModal()"><PlusCircle :size="16" /><span>Añadir nueva venta</span></button>
          <button v-if="activeTab === 'clientes'" class="btn-primary" @click="openClientModal"><UserPlus :size="16" /><span>Nuevo cliente</span></button>
          <button v-if="activeTab === 'citas'" class="btn-primary" @click="openCitaModal"><CalendarPlus :size="16" /><span>Agendar cita</span></button>
        </div>
      </div>

      <!-- 1. VENTAS DEL DÍA -->
      <template v-if="activeTab === 'ventas'">
        <p v-if="!filteredSales.length" class="empty">{{ todaySales.length ? 'No hay ventas que coincidan con la búsqueda.' : 'Aún no registras ventas hoy. Usa "Añadir nueva venta" para empezar.' }}</p>
        <div class="big-list">
          <div v-for="s in filteredSales" :key="s.id" class="big-row">
            <div class="big-main">
              <span class="big-code">{{ s.code }} · {{ s.time }}</span>
              <h4>{{ s.client }}</h4>
              <span class="big-sub">{{ saleSummary(s) }}</span>
            </div>
            <div class="big-end"><span class="method-badge">{{ s.method }}</span><strong class="money">$ {{ formatCOP(s.total) }}</strong></div>
          </div>
        </div>
      </template>

      <!-- 2. CATÁLOGO -->
      <template v-else-if="activeTab === 'catalogo'">
        <p v-if="!filteredCatalog.length" class="empty">No hay repuestos que coincidan con la búsqueda.</p>
        <ProductCollection :items="filteredCatalog" :view="views.catalogo" actionLabel="Vender" :actionIcon="ShoppingCart" @open="selectedProduct = $event" @action="openSaleModal($event.code)" />
      </template>

      <!-- 3. CLIENTES -->
      <template v-else-if="activeTab === 'clientes'">
        <p v-if="!filteredClients.length" class="empty">No hay clientes que coincidan con la búsqueda.</p>
        <div v-if="views.clientes === 'list'" class="big-list">
          <div v-for="c in filteredClients" :key="c.id" class="big-row clickable" tabindex="0" @click="selectedClient = c" @keydown.enter="selectedClient = c">
            <div class="big-avatar">{{ initials(c.name) }}</div>
            <div class="big-main"><h4>{{ c.name }}</h4><span class="big-sub">CC {{ c.documento }} · {{ c.phone }}</span></div>
            <div class="big-end"><strong>{{ c.moto || 'Sin moto' }}</strong><span class="big-sub">{{ c.placa }}</span></div>
          </div>
        </div>
        <div v-else class="big-grid">
          <div v-for="c in filteredClients" :key="c.id" class="big-card clickable" tabindex="0" @click="selectedClient = c" @keydown.enter="selectedClient = c">
            <div class="big-avatar lg">{{ initials(c.name) }}</div>
            <h4>{{ c.name }}</h4>
            <span class="big-sub">CC {{ c.documento }}</span>
            <span class="big-sub">{{ c.phone }}</span>
            <span class="big-chip">{{ c.moto || 'Sin moto' }} · {{ c.placa || '—' }}</span>
          </div>
        </div>
      </template>

      <!-- 4. CITAS -->
      <template v-else-if="activeTab === 'citas'">
        <p v-if="!filteredCitas.length" class="empty">No hay citas que coincidan con la búsqueda.</p>
        <div v-if="views.citas === 'list'" class="big-list">
          <div v-for="c in filteredCitas" :key="c.id" class="big-row clickable" tabindex="0" @click="selectedCita = c" @keydown.enter="selectedCita = c">
            <div class="big-time">{{ formatHour(c.time24) }}</div>
            <div class="big-main"><h4>{{ c.cliente }}</h4><span class="big-sub">{{ c.moto }}</span></div>
            <div class="big-end"><strong class="plate">{{ c.placa }}</strong><span class="status-pill">Agendado</span></div>
          </div>
        </div>
        <div v-else class="big-grid">
          <div v-for="c in filteredCitas" :key="c.id" class="big-card clickable" tabindex="0" @click="selectedCita = c" @keydown.enter="selectedCita = c">
            <span class="status-pill right">Agendado</span>
            <span class="big-time-lg">{{ formatHour(c.time24) }}</span>
            <h4>{{ c.cliente }}</h4>
            <span class="big-sub">Moto: {{ c.moto }}</span>
            <strong class="plate">Placa: {{ c.placa }}</strong>
          </div>
        </div>
      </template>
    </section>

    <!-- DETALLE DE PRODUCTO (conserva el botón Vender) -->
    <ProductDetailModal v-if="selectedProduct" :product="selectedProduct" @close="selectedProduct = null">
      <template #actions>
        <button class="btn-primary big" :disabled="selectedProduct.stock === 0" @click="sellFromDetail(selectedProduct.code)"><ShoppingCart :size="16" /><span>{{ selectedProduct.stock === 0 ? 'Sin stock' : 'Vender' }}</span></button>
      </template>
    </ProductDetailModal>

    <!-- DETALLE DE CLIENTE -->
    <BigModal v-if="selectedClient" :title="selectedClient.name" :subtitle="'Cliente · CC ' + selectedClient.documento" wide @close="selectedClient = null">
      <div class="detail-top">
        <div class="big-avatar xl">{{ initials(selectedClient.name) }}</div>
        <div class="detail-grid">
          <div><span>Cédula</span><strong>{{ selectedClient.documento }}</strong></div>
          <div><span>Teléfono</span><strong>{{ selectedClient.phone }}</strong></div>
          <div><span>Moto</span><strong>{{ selectedClient.moto || '—' }}</strong></div>
          <div><span>Placa</span><strong>{{ selectedClient.placa || '—' }}</strong></div>
        </div>
      </div>
      <div class="mm-stats">
        <div class="mm-stat"><span>Compras</span><strong>{{ clientSales.length }}</strong></div>
        <div class="mm-stat"><span>Total comprado</span><strong class="mm-green">$ {{ formatCOP(sumSales(clientSales)) }}</strong></div>
        <div class="mm-stat"><span>Última compra</span><strong style="font-size:15px">{{ clientSales.length ? fmtDate(clientSales[0].date) : '—' }}</strong></div>
      </div>
      <h4 class="mm-section-title">Historial de compras</h4>
      <div class="mm-list">
        <div v-for="s in clientSales" :key="s.id" class="mm-row">
          <div class="mm-row-main"><strong>{{ s.code }} · {{ fmtDate(s.date) }}</strong><small>{{ saleSummary(s) }}</small></div>
          <div class="mm-row-end mm-green">$ {{ formatCOP(s.total) }}</div>
        </div>
      </div>
      <p v-if="!clientSales.length" class="mm-empty">Este cliente aún no tiene compras registradas.</p>
      <template #footer>
        <button class="btn-primary" @click="sellToClient(selectedClient.id)"><ShoppingCart :size="16" /><span>Nueva venta para este cliente</span></button>
      </template>
    </BigModal>

    <!-- DETALLE DE CITA -->
    <BigModal v-if="selectedCita" :title="'Cita de ' + selectedCita.cliente" :subtitle="formatHour(selectedCita.time24) + ' · Recepción de motocicleta'" @close="selectedCita = null">
      <div class="detail-grid single">
        <div><span>Hora</span><strong>{{ formatHour(selectedCita.time24) }}</strong></div>
        <div><span>Cliente</span><strong>{{ selectedCita.cliente }}</strong></div>
        <div><span>Teléfono</span><strong>{{ citaClientPhone(selectedCita) }}</strong></div>
        <div><span>Moto</span><strong>{{ selectedCita.moto }}</strong></div>
        <div><span>Placa</span><strong>{{ selectedCita.placa }}</strong></div>
        <div><span>Estado</span><strong class="mm-green">Agendado</strong></div>
        <div><span>Motivo</span><strong>Mantenimiento preventivo</strong></div>
      </div>
    </BigModal>

    <!-- MODAL: NUEVA VENTA (solo efectivo) -->
    <div v-if="showSaleModal" class="modal-overlay" @click.self="showSaleModal = false">
      <div class="modal-card modal-wide">
        <div class="modal-header"><h3>Añadir nueva venta</h3><button class="close-btn" aria-label="Cerrar" @click="showSaleModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group">
            <label>Cliente</label>
            <select v-model="saleForm.clientId" class="form-input">
              <option value="">Cliente de mostrador (sin registrar)</option>
              <option v-for="c in clients" :key="c.id" :value="c.id">{{ c.name }} — CC {{ c.documento }}</option>
            </select>
          </div>
          <div class="add-line-row">
            <div class="form-group grow">
              <label>Repuesto</label>
              <select v-model="saleForm.productCode" class="form-input">
                <option value="" disabled>Selecciona un repuesto</option>
                <option v-for="p in products" :key="p.code" :value="p.code" :disabled="p.stock === 0">{{ p.name }} — $ {{ formatCOP(p.price) }} ({{ p.stock }} u.)</option>
              </select>
            </div>
            <div class="form-group qty-group"><label>Cant.</label><input v-model.number="saleForm.qty" type="number" min="1" class="form-input" /></div>
            <button class="btn-add-line" aria-label="Agregar a la venta" @click="addLine"><Plus :size="16" /></button>
          </div>
          <p v-if="saleError" class="form-error">{{ saleError }}</p>

          <div class="cart-box">
            <p v-if="!cartLines.length" class="cart-empty">Aún no agregas repuestos a esta venta.</p>
            <div v-for="line in cartLines" :key="line.code" class="cart-line">
              <div class="cart-line-info"><strong>{{ line.name }}</strong><span>$ {{ formatCOP(line.price) }} c/u</span></div>
              <div class="cart-qty">
                <button aria-label="Quitar una unidad" @click="changeQty(line, -1)"><Minus :size="12" /></button>
                <span>{{ line.qty }}</span>
                <button aria-label="Agregar una unidad" @click="changeQty(line, 1)"><Plus :size="12" /></button>
              </div>
              <span class="cart-line-total">$ {{ formatCOP(line.qty * line.price) }}</span>
              <button class="cart-remove" aria-label="Eliminar línea" @click="removeLine(line)"><Trash2 :size="14" /></button>
            </div>
          </div>

          <div class="form-group">
            <label>Método de pago</label>
            <div class="method-selector"><button type="button" class="method-option active"><Banknote :size="15" /><span>Efectivo</span></button></div>
          </div>
          <div class="cart-total-row"><span>Total a cobrar</span><strong>$ {{ formatCOP(cartTotal) }}</strong></div>
          <div class="modal-actions"><button class="btn-save" :disabled="!cartLines.length" @click="confirmSale">Registrar venta</button></div>
        </div>
      </div>
    </div>

    <!-- MODAL: NUEVO CLIENTE -->
    <div v-if="showClientModal" class="modal-overlay" @click.self="showClientModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Nuevo cliente</h3><button class="close-btn" aria-label="Cerrar" @click="showClientModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group"><label>Nombre completo</label><input v-model="clientForm.name" type="text" placeholder="Ej: Laura Ramírez" class="form-input" /></div>
          <div class="form-group"><label>Cédula</label><input v-model="clientForm.documento" type="text" class="form-input" /></div>
          <div class="form-group"><label>Teléfono</label><input v-model="clientForm.phone" type="text" placeholder="Ej: 3001234567" class="form-input" /></div>
          <div class="form-group"><label>Moto (opcional)</label><input v-model="clientForm.moto" type="text" placeholder="Ej: Yamaha FZ 25" class="form-input" /></div>
          <div class="form-group"><label>Placa (opcional)</label><input v-model="clientForm.placa" type="text" placeholder="Ej: ABC-123" class="form-input" /></div>
          <p v-if="clientError" class="form-error">{{ clientError }}</p>
          <button class="btn-save" @click="saveClient">Guardar cliente</button>
        </div>
      </div>
    </div>

    <!-- MODAL: NUEVA CITA -->
    <div v-if="showCitaModal" class="modal-overlay" @click.self="showCitaModal = false">
      <div class="modal-card">
        <div class="modal-header"><h3>Agendar cita</h3><button class="close-btn" aria-label="Cerrar" @click="showCitaModal = false"><X :size="18" /></button></div>
        <div class="modal-body">
          <div class="form-group">
            <label>Cliente</label>
            <select v-model="citaForm.clientId" class="form-input" @change="fillCitaFromClient">
              <option value="" disabled>Selecciona un cliente</option>
              <option v-for="c in clients" :key="c.id" :value="c.id">{{ c.name }}</option>
            </select>
          </div>
          <div class="form-group"><label>Hora</label><input v-model="citaForm.time24" type="time" class="form-input" /></div>
          <div class="form-group"><label>Moto</label><input v-model="citaForm.moto" type="text" placeholder="Ej: Pulsar NS 200" class="form-input" /></div>
          <div class="form-group"><label>Placa</label><input v-model="citaForm.placa" type="text" placeholder="Ej: XYZ-123" class="form-input" /></div>
          <p v-if="citaError" class="form-error">{{ citaError }}</p>
          <button class="btn-save" @click="saveCita">Agendar cita</button>
        </div>
      </div>
    </div>

    <div v-if="toastMessage" class="toast" role="status">{{ toastMessage }}</div>
  </AppShell>
</template>

<script setup>
import { ref, reactive, computed, onUnmounted } from 'vue'
import {
  ShoppingBag, Package, Users, CalendarDays, Receipt, Wallet, PackageSearch, Search, List, LayoutGrid,
  PlusCircle, UserPlus, CalendarPlus, ShoppingCart, Plus, Minus, Trash2, X, Banknote
} from 'lucide-vue-next'
import AppShell from '../components/AppShell.vue'
import MetricsMenu from '../components/MetricsMenu.vue'
import ProductCollection from '../components/ProductCollection.vue'
import ProductDetailModal from '../components/ProductDetailModal.vue'
import BigModal from '../components/BigModal.vue'
import { getProducts, stockLevel, stockLabel, stockColor, stockPct, formatCOP } from '../data/productos'

defineProps({ isDarkMode: Boolean })
defineEmits(['change-view', 'toggle-theme'])

const navItems = [
  { key: 'ventas', label: 'Ventas', icon: ShoppingBag },
  { key: 'catalogo', label: 'Catálogo', icon: Package },
  { key: 'clientes', label: 'Clientes', icon: Users },
  { key: 'citas', label: 'Citas', icon: CalendarDays }
]
const activeTab = ref('ventas')
const tabs = {
  ventas: { title: 'Mis Ventas del Día', sub: 'Ventas de mostrador registradas por tu usuario', placeholder: 'Buscar venta o cliente...' },
  catalogo: { title: 'Catálogo de Repuestos', sub: 'Consulta precios y stock en tiempo real para venta inmediata', placeholder: 'Buscar repuesto...' },
  clientes: { title: 'Fichas de Clientes', sub: 'Consulta clientes y registra nuevos para la factura', placeholder: 'Buscar nombre, cédula o placa...' },
  citas: { title: 'Agenda de Citas y Recepción', sub: 'Control de ingresos de motocicletas a mantenimiento preventivo', placeholder: 'Buscar cliente o placa...' }
}
const tabInfo = computed(() => tabs[activeTab.value])
const search = reactive({ ventas: '', catalogo: '', clientes: '', citas: '' })
const views = reactive({ catalogo: 'cards', clientes: 'cards', citas: 'cards' })

const initials = (n) => n.split(' ').filter(Boolean).slice(0, 2).map(w => w[0].toUpperCase()).join('')

/* ---------- Aviso ---------- */
const toastMessage = ref('')
let toastTimer = null
const showToast = (msg) => { toastMessage.value = msg; clearTimeout(toastTimer); toastTimer = setTimeout(() => { toastMessage.value = '' }, 2800) }
onUnmounted(() => clearTimeout(toastTimer))

/* ---------- Fechas ---------- */
const toISO = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
const todayISO = () => toISO(new Date())
const daysAgoISO = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return toISO(d) }
const fmtDate = (iso) => new Date(iso + 'T00:00:00').toLocaleDateString('es-CO', { day: '2-digit', month: 'short', year: 'numeric' })
const formatHour = (t) => {
  const [h, m] = t.split(':').map(Number)
  return `${String(h % 12 === 0 ? 12 : h % 12).padStart(2, '0')}:${String(m).padStart(2, '0')} ${h >= 12 ? 'PM' : 'AM'}`
}

/* ---------- Productos ---------- */
const products = ref(getProducts())
const selectedProduct = ref(null)
const filteredCatalog = computed(() => {
  const q = search.catalogo.trim().toLowerCase()
  const list = q ? products.value.filter(p => p.name.toLowerCase().includes(q) || p.code.toLowerCase().includes(q) || p.category.toLowerCase().includes(q)) : products.value
  return [...list].sort((a, b) => a.name.localeCompare(b.name))
})

/* ---------- Clientes ---------- */
const clients = ref([
  { id: 1, name: 'Carlos Mendoza', documento: '1023456789', phone: '3001112233', moto: 'Yamaha FZ 25', placa: 'FZ2-250' },
  { id: 2, name: 'Andrea Gómez', documento: '1098765432', phone: '3004445566', moto: 'Pulsar NS 200', placa: 'NS2-200' },
  { id: 3, name: 'Alejandro Morales', documento: '1034567812', phone: '3007778899', moto: 'Pulsar NS 200', placa: 'XYZ-123' },
  { id: 4, name: 'Diana Marcela', documento: '1012345678', phone: '3000001122', moto: 'Yamaha FZ 25', placa: 'ABC-789' }
])
const filteredClients = computed(() => {
  const q = search.clientes.trim().toLowerCase()
  if (!q) return clients.value
  return clients.value.filter(c => c.name.toLowerCase().includes(q) || c.documento.includes(q) || (c.placa || '').toLowerCase().includes(q))
})
const selectedClient = ref(null)
const clientSales = computed(() => (selectedClient.value ? sales.value.filter(s => s.client === selectedClient.value.name).sort((a, b) => b.date.localeCompare(a.date)) : []))

const showClientModal = ref(false)
const clientError = ref('')
const clientForm = ref({ name: '', documento: '', phone: '', moto: '', placa: '' })
const openClientModal = () => { clientForm.value = { name: '', documento: '', phone: '', moto: '', placa: '' }; clientError.value = ''; showClientModal.value = true }
const saveClient = () => {
  const f = clientForm.value
  if (!f.name.trim() || !f.documento.trim() || !f.phone.trim()) { clientError.value = 'Ingresa nombre, cédula y teléfono.'; return }
  if (clients.value.some(c => c.documento === f.documento.trim())) { clientError.value = 'Ya existe un cliente con esa cédula.'; return }
  clients.value.unshift({ id: Date.now(), name: f.name.trim(), documento: f.documento.trim(), phone: f.phone.trim(), moto: f.moto.trim(), placa: f.placa.trim().toUpperCase() })
  showClientModal.value = false
  showToast('Cliente registrado.')
}

/* ---------- Ventas (solo efectivo) ---------- */
const mkSale = (id, daysAgo, time, client, items) => ({
  id, code: `#VTA-${String(id).padStart(3, '0')}`, date: daysAgoISO(daysAgo), time, client, method: 'Efectivo',
  items, total: items.reduce((a, i) => a + i.qty * i.price, 0)
})
const it = (code, name, qty, price) => ({ code, name, qty, price })
const sales = ref([
  mkSale(1, 0, '10:20', 'Carlos Mendoza', [it('#REP-101', 'Aceite Sintético 10W40 4T (1L)', 2, 45000), it('#REP-105', 'Filtro de Aceite Yamaha FZ 25', 1, 28000)]),
  mkSale(2, 0, '11:05', 'Andrea Gómez', [it('#REP-102', 'Kit de Arrastre Pulsar NS 200', 1, 210000)]),
  mkSale(3, 1, '15:40', 'Alejandro Morales', [it('#REP-103', 'Pastillas de Freno Delanteras', 2, 65000)]),
  mkSale(4, 3, '09:15', 'Diana Marcela', [it('#REP-104', 'Bujía Iridium CR9EIX', 2, 52000)]),
  mkSale(5, 12, '16:30', 'Carlos Mendoza', [it('#REP-101', 'Aceite Sintético 10W40 4T (1L)', 1, 45000), it('#REP-104', 'Bujía Iridium CR9EIX', 1, 52000)]),
  mkSale(6, 40, '12:10', 'Andrea Gómez', [it('#REP-105', 'Filtro de Aceite Yamaha FZ 25', 2, 28000)]),
  mkSale(7, 100, '10:00', 'Cliente de mostrador', [it('#REP-102', 'Kit de Arrastre Pulsar NS 200', 1, 210000)]),
  mkSale(8, 400, '14:25', 'Diana Marcela', [it('#REP-103', 'Pastillas de Freno Delanteras', 1, 65000)])
])
let saleCounter = sales.value.length

const sumSales = (list) => list.reduce((a, s) => a + s.total, 0)
const saleSummary = (s) => s.items.map(i => `${i.qty}× ${i.name}`).join(', ')
const todaySales = computed(() => sales.value.filter(s => s.date === todayISO()))
const filteredSales = computed(() => {
  const q = search.ventas.trim().toLowerCase()
  const list = [...todaySales.value].reverse()
  if (!q) return list
  return list.filter(s => s.client.toLowerCase().includes(q) || s.code.toLowerCase().includes(q) || s.items.some(i => i.name.toLowerCase().includes(q)))
})

// Paneles del menú de indicadores
const periods = [{ value: 'dia', label: 'Día' }, { value: 'mes', label: 'Mes' }, { value: 'anio', label: 'Año' }]
const salesPeriod = ref('dia')
const totalGroup = ref('dia')
const inPeriod = (s, p) => {
  const t = todayISO()
  return p === 'dia' ? s.date === t : p === 'mes' ? s.date.slice(0, 7) === t.slice(0, 7) : s.date.slice(0, 4) === t.slice(0, 4)
}
const periodSales = computed(() => sales.value.filter(s => inPeriod(s, salesPeriod.value)).sort((a, b) => b.date.localeCompare(a.date) || b.time.localeCompare(a.time)))

const groupedTotals = computed(() => {
  const len = totalGroup.value === 'dia' ? 10 : totalGroup.value === 'mes' ? 7 : 4
  const map = {}
  sales.value.forEach(s => {
    const key = s.date.slice(0, len)
    map[key] = map[key] || { key, total: 0, count: 0 }
    map[key].total += s.total
    map[key].count += 1
  })
  const list = Object.values(map).sort((a, b) => b.key.localeCompare(a.key))
  const max = Math.max(1, ...list.map(g => g.total))
  return list.map(g => ({
    ...g,
    pct: Math.round((g.total / max) * 100),
    label: totalGroup.value === 'dia' ? fmtDate(g.key)
      : totalGroup.value === 'mes' ? new Date(g.key + '-01T00:00:00').toLocaleDateString('es-CO', { month: 'long', year: 'numeric' })
      : g.key
  }))
})

const infoAvail = ref('all')
const infoSort = ref('stock-asc')
const infoList = computed(() => {
  const list = products.value.filter(p => infoAvail.value === 'all' || stockLevel(p.stock) === infoAvail.value)
  const sorters = { 'stock-asc': (a, b) => a.stock - b.stock, 'stock-desc': (a, b) => b.stock - a.stock, 'sold-desc': (a, b) => b.sold - a.sold, 'sold-asc': (a, b) => a.sold - b.sold }
  return [...list].sort(sorters[infoSort.value])
})

const menuItems = computed(() => [
  { key: 'ventas', label: 'Ventas', value: `${todaySales.value.length} hoy`, icon: Receipt, tone: 'green' },
  { key: 'total', label: 'Total vendido', value: `$ ${formatCOP(sumSales(todaySales.value))} hoy`, icon: Wallet, tone: 'orange' },
  { key: 'info', label: 'Info repuestos', value: `${products.value.length} referencias`, icon: PackageSearch, tone: 'yellow' }
])

/* ---------- Nueva venta ---------- */
const showSaleModal = ref(false)
const saleError = ref('')
const saleForm = ref({ clientId: '', productCode: '', qty: 1 })
const cartLines = ref([])
const cartTotal = computed(() => cartLines.value.reduce((a, l) => a + l.qty * l.price, 0))
const stockOf = (code) => (products.value.find(p => p.code === code) || { stock: 0 }).stock

const openSaleModal = (productCode = null, clientId = '') => {
  saleForm.value = { clientId, productCode: productCode || '', qty: 1 }
  cartLines.value = []
  saleError.value = ''
  if (productCode) addLine()
  showSaleModal.value = true
}
const sellFromDetail = (code) => { selectedProduct.value = null; openSaleModal(code) }
const sellToClient = (id) => { selectedClient.value = null; openSaleModal(null, id) }

const addLine = () => {
  saleError.value = ''
  const product = products.value.find(p => p.code === saleForm.value.productCode)
  const qty = Number(saleForm.value.qty)
  if (!product) { saleError.value = 'Selecciona un repuesto.'; return }
  if (!qty || qty < 1) { saleError.value = 'La cantidad debe ser al menos 1.'; return }
  const existing = cartLines.value.find(l => l.code === product.code)
  if ((existing ? existing.qty : 0) + qty > product.stock) { saleError.value = `Solo hay ${product.stock} u. disponibles de "${product.name}".`; return }
  if (existing) existing.qty += qty
  else cartLines.value.push({ code: product.code, name: product.name, price: product.price, qty })
  saleForm.value.productCode = ''
  saleForm.value.qty = 1
}
const removeLine = (line) => { cartLines.value = cartLines.value.filter(l => l.code !== line.code) }
const changeQty = (line, delta) => {
  saleError.value = ''
  const next = line.qty + delta
  if (next < 1) { removeLine(line); return }
  if (next > stockOf(line.code)) { saleError.value = `Solo hay ${stockOf(line.code)} u. disponibles de "${line.name}".`; return }
  line.qty = next
}
const confirmSale = () => {
  if (!cartLines.value.length) { saleError.value = 'Agrega al menos un repuesto a la venta.'; return }
  for (const l of cartLines.value) {
    if (l.qty > stockOf(l.code)) { saleError.value = `El stock de "${l.name}" cambió. Ajusta la cantidad.`; return }
  }
  cartLines.value.forEach(l => {
    const p = products.value.find(x => x.code === l.code)
    if (p) { p.stock -= l.qty; p.sold += l.qty }
  })
  saleCounter += 1
  const client = clients.value.find(c => c.id === saleForm.value.clientId)
  sales.value.push({
    id: Date.now(), code: `#VTA-${String(saleCounter).padStart(3, '0')}`, date: todayISO(),
    time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    client: client ? client.name : 'Cliente de mostrador', method: 'Efectivo',
    items: cartLines.value.map(l => ({ ...l })), total: cartTotal.value
  })
  showSaleModal.value = false
  activeTab.value = 'ventas'
  showToast('Venta registrada y stock actualizado.')
}

/* ---------- Citas ---------- */
const citas = ref([
  { id: 1, time24: '09:00', cliente: 'Alejandro Morales', moto: 'Pulsar NS 200', placa: 'XYZ-123' },
  { id: 2, time24: '11:30', cliente: 'Diana Marcela', moto: 'Yamaha FZ 25', placa: 'ABC-789' }
])
const filteredCitas = computed(() => {
  const q = search.citas.trim().toLowerCase()
  const list = [...citas.value].sort((a, b) => a.time24.localeCompare(b.time24))
  return q ? list.filter(c => c.cliente.toLowerCase().includes(q) || c.placa.toLowerCase().includes(q)) : list
})
const selectedCita = ref(null)
const citaClientPhone = (c) => (clients.value.find(x => x.name === c.cliente) || {}).phone || '—'

const showCitaModal = ref(false)
const citaError = ref('')
const citaForm = ref({ clientId: '', time24: '09:00', moto: '', placa: '' })
const openCitaModal = () => { citaForm.value = { clientId: '', time24: '09:00', moto: '', placa: '' }; citaError.value = ''; showCitaModal.value = true }
const fillCitaFromClient = () => {
  const c = clients.value.find(x => x.id === citaForm.value.clientId)
  if (c) { citaForm.value.moto = c.moto || ''; citaForm.value.placa = c.placa || '' }
}
const saveCita = () => {
  const f = citaForm.value
  const client = clients.value.find(c => c.id === f.clientId)
  if (!client) { citaError.value = 'Selecciona un cliente.'; return }
  if (!f.time24) { citaError.value = 'Indica la hora de la cita.'; return }
  if (!f.moto.trim() || !f.placa.trim()) { citaError.value = 'Ingresa la moto y la placa.'; return }
  citas.value.push({ id: Date.now(), time24: f.time24, cliente: client.name, moto: f.moto.trim(), placa: f.placa.trim().toUpperCase() })
  showCitaModal.value = false
  showToast('Cita agendada.')
}
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; }
.main-card { display: flex; flex-direction: column; gap: 22px; }
.main-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px; }
.header-left { display: flex; align-items: center; gap: 14px; }
.header-titles h3 { font-size: 17px; font-weight: 600; margin: 0 0 4px; }
.header-titles p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.controls { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
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
.empty { font-size: 13px; color: var(--text-secondary); margin: 0; }

.big-list { display: flex; flex-direction: column; gap: 14px; }
.big-row { display: flex; align-items: center; gap: 20px; background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 16px; padding: 20px 24px; transition: transform 0.2s, border-color 0.2s; }
.big-row.clickable, .big-card.clickable { cursor: pointer; }
.big-row.clickable:hover { transform: translateX(4px); border-color: #E67E22; }
.big-main { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 4px; }
.big-main h4 { margin: 0; font-size: 19px; font-weight: 700; }
.big-code { font-size: 12px; font-weight: 700; color: var(--text-secondary); }
.big-sub { font-size: 14px; color: var(--text-secondary); }
.big-end { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; flex-shrink: 0; }
.big-end strong { font-size: 15px; }
.money { font-size: 21px !important; color: #2ECC71; }
.method-badge, .status-pill { font-size: 11px; font-weight: 700; padding: 4px 10px; border-radius: 6px; background: rgba(46, 204, 113, 0.15); color: #2ECC71; }
.status-pill.right { align-self: flex-end; }
.plate { color: #E67E22; font-size: 16px; }
.big-avatar { width: 56px; height: 56px; border-radius: 14px; background: rgba(230, 126, 34, 0.15); color: #E67E22; font-weight: 800; font-size: 20px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.big-avatar.lg { width: 76px; height: 76px; font-size: 26px; border-radius: 18px; }
.big-avatar.xl { width: 92px; height: 92px; font-size: 32px; border-radius: 22px; }
.big-time { min-width: 100px; font-size: 20px; font-weight: 800; color: #E67E22; }
.big-time-lg { font-size: 26px; font-weight: 800; color: #E67E22; }
.big-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 22px; }
.big-card { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 20px; padding: 26px; display: flex; flex-direction: column; align-items: flex-start; gap: 8px; transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s; }
.big-card:hover { transform: translateY(-4px); box-shadow: 0 12px 26px rgba(0, 0, 0, 0.2); border-color: #E67E22; }
.big-card h4 { margin: 6px 0 0; font-size: 21px; font-weight: 700; }
.big-chip { margin-top: 6px; font-size: 13px; font-weight: 600; padding: 6px 12px; border-radius: 8px; background: rgba(230, 126, 34, 0.12); color: #E67E22; }

.detail-top { display: flex; align-items: center; gap: 22px; flex-wrap: wrap; }
.detail-grid { flex: 1; display: grid; grid-template-columns: repeat(2, minmax(150px, 1fr)); gap: 14px; }
.detail-grid.single { grid-template-columns: 1fr 1fr; }
.detail-grid div { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 14px 16px; display: flex; flex-direction: column; gap: 4px; }
.detail-grid span { font-size: 11px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.4px; }
.detail-grid strong { font-size: 16px; }

.modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.6); backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; z-index: 100; padding: 16px; }
.modal-card { background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; width: 440px; max-width: 100%; max-height: 90vh; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 16px; }
.modal-card.modal-wide { width: 580px; }
.modal-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border-color); padding-bottom: 12px; }
.modal-header h3 { font-size: 16px; margin: 0; font-weight: 600; }
.close-btn { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; }
.close-btn:hover { color: var(--text-primary); }
.modal-body { display: flex; flex-direction: column; gap: 12px; }
.form-group { display: flex; flex-direction: column; gap: 4px; }
.form-group.grow { flex: 1; min-width: 0; }
.form-group label { font-size: 11px; font-weight: 700; color: var(--text-secondary); }
.form-input { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 8px; padding: 8px 12px; color: var(--text-primary); font-size: 13px; outline: none; width: 100%; box-sizing: border-box; }
.form-input:focus { border-color: #E67E22; }
.form-error { font-size: 12px; color: #E74C3C; margin: 0; }
.btn-save { background: #E67E22; color: #FFF; border: none; border-radius: 8px; padding: 10px 16px; font-weight: 600; cursor: pointer; transition: background-color 0.2s, opacity 0.2s; }
.btn-save:hover:not(:disabled) { background: #D35400; }
.btn-save:disabled { opacity: 0.5; cursor: not-allowed; }
.add-line-row { display: flex; align-items: flex-end; gap: 10px; }
.qty-group { width: 80px; }
.btn-add-line { background: #E67E22; color: #FFF; border: none; border-radius: 8px; width: 38px; height: 36px; cursor: pointer; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.btn-add-line:hover { background: #D35400; }
.cart-box { background: var(--input-bg); border: 1px solid var(--border-color); border-radius: 12px; padding: 10px; display: flex; flex-direction: column; gap: 8px; min-height: 52px; }
.cart-empty { font-size: 12px; color: var(--text-secondary); margin: 0; padding: 6px 4px; }
.cart-line { display: flex; align-items: center; gap: 12px; padding: 6px 4px; border-bottom: 1px solid var(--border-color); }
.cart-line:last-child { border-bottom: none; }
.cart-line-info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.cart-line-info strong { font-size: 13px; }
.cart-line-info span { font-size: 11px; color: var(--text-secondary); }
.cart-qty { display: flex; align-items: center; gap: 8px; }
.cart-qty span { font-size: 13px; font-weight: 700; min-width: 18px; text-align: center; }
.cart-qty button { background: var(--bg-card); border: 1px solid var(--border-color); color: var(--text-primary); width: 24px; height: 24px; border-radius: 6px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.cart-qty button:hover { border-color: #E67E22; color: #E67E22; }
.cart-line-total { font-size: 13px; font-weight: 700; color: #2ECC71; min-width: 84px; text-align: right; }
.cart-remove { background: transparent; border: none; color: var(--text-secondary); cursor: pointer; display: flex; padding: 4px; border-radius: 6px; }
.cart-remove:hover { color: #E74C3C; background: rgba(231, 76, 60, 0.1); }
.method-selector { display: flex; gap: 8px; }
.method-option { flex: 1; background: var(--input-bg); border: 1px solid var(--border-color); color: var(--text-secondary); border-radius: 8px; padding: 8px 10px; font-size: 12px; font-weight: 600; display: flex; align-items: center; justify-content: center; gap: 6px; }
.method-option.active { background: #E67E22; border-color: #E67E22; color: #FFFFFF; }
.cart-total-row { display: flex; justify-content: space-between; align-items: center; font-size: 14px; border-top: 1px solid var(--border-color); padding-top: 12px; }
.cart-total-row strong { font-size: 20px; color: #2ECC71; }
.modal-actions { display: flex; justify-content: flex-end; }
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--bg-card); color: var(--text-primary); border: 1px solid #E67E22; border-left-width: 4px; border-radius: 10px; padding: 12px 16px; font-size: 13px; font-weight: 600; box-shadow: 0 8px 24px rgba(0,0,0,0.3); z-index: 200; }
@media (max-width: 768px) { .big-row { flex-wrap: wrap; } .big-end { align-items: flex-start; } }
</style>
