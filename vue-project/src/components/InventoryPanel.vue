<template>
  <section class="card inv-card">
    <div class="inv-header">
      <div class="inv-left">
        <MetricsMenu :items="menuItems">
          <template #total>
            <div class="mm-stats">
              <div class="mm-stat"><span>Referencias</span><strong>{{ products.length }}</strong></div>
              <div class="mm-stat"><span>Unidades en bodega</span><strong class="mm-orange">{{ totalUnits }}</strong></div>
            </div>
            <div class="mm-toolbar">
              <div class="mm-field">
                <label>Ordenar por</label>
                <select v-model="ctl.total.sort" class="mm-select">
                  <option v-for="o in sortOptions" :key="o.value" :value="o.value">{{ o.label }}</option>
                </select>
              </div>
              <div class="mm-field">
                <label>Categoría</label>
                <select v-model="ctl.total.cat" class="mm-select">
                  <option value="">Todas las categorías</option>
                  <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
                </select>
              </div>
              <div class="mm-seg">
                <button :class="{ active: ctl.total.view === 'list' }" @click="ctl.total.view = 'list'"><List :size="14" /> Lista</button>
                <button :class="{ active: ctl.total.view === 'cards' }" @click="ctl.total.view = 'cards'"><LayoutGrid :size="14" /> Tarjetas</button>
              </div>
            </div>
            <ProductCollection :items="panelList('total')" :view="ctl.total.view" compact @open="selected = $event" />
            <p v-if="!panelList('total').length" class="mm-empty">No hay repuestos en esa categoría.</p>
          </template>

          <template #critico>
            <div class="mm-stats">
              <div class="mm-stat"><span>Ítems urgentes</span><strong class="mm-red">{{ criticalCount }}</strong></div>
              <div class="mm-stat"><span>Stock medio</span><strong class="mm-yellow">{{ mediumCount }}</strong></div>
            </div>
            <div class="mm-toolbar">
              <div class="mm-field">
                <label>Ordenar por</label>
                <select v-model="ctl.critico.sort" class="mm-select">
                  <option v-for="o in sortOptions" :key="o.value" :value="o.value">{{ o.label }}</option>
                </select>
              </div>
              <div class="mm-field">
                <label>Categoría</label>
                <select v-model="ctl.critico.cat" class="mm-select">
                  <option value="">Todas las categorías</option>
                  <option v-for="c in categories" :key="c" :value="c">{{ c }}</option>
                </select>
              </div>
              <div class="mm-seg">
                <button :class="{ active: ctl.critico.view === 'list' }" @click="ctl.critico.view = 'list'"><List :size="14" /> Lista</button>
                <button :class="{ active: ctl.critico.view === 'cards' }" @click="ctl.critico.view = 'cards'"><LayoutGrid :size="14" /> Tarjetas</button>
              </div>
            </div>
            <ProductCollection :items="panelList('critico')" :view="ctl.critico.view" compact @open="selected = $event" />
            <p v-if="!panelList('critico').length" class="mm-empty">No hay repuestos en stock crítico con ese filtro.</p>
          </template>

          <template #valor>
            <div class="mm-stats">
              <div class="mm-stat"><span>Valor total</span><strong class="mm-green">$ {{ formatCOP(inventoryValue) }}</strong></div>
              <div class="mm-stat"><span>Unidades</span><strong>{{ totalUnits }}</strong></div>
            </div>
            <h4 class="mm-section-title">Valor por categoría</h4>
            <div class="mm-list">
              <div v-for="c in valueByCategory" :key="c.name" class="mm-row">
                <div class="mm-row-main">
                  <strong>{{ c.name }}</strong>
                  <div class="mm-bar"><i :style="{ width: c.pct + '%', background: '#2ECC71' }"></i></div>
                </div>
                <div class="mm-row-end">$ {{ formatCOP(c.value) }}<small>{{ c.pct }}%</small></div>
              </div>
            </div>
            <h4 class="mm-section-title">Productos de mayor valor en bodega</h4>
            <div class="mm-list">
              <button v-for="p in topByValue" :key="p.code" class="mm-row" @click="selected = p">
                <div class="mm-row-main"><strong>{{ p.name }}</strong><small>{{ p.stock }} u. × $ {{ formatCOP(p.price) }}</small></div>
                <div class="mm-row-end">$ {{ formatCOP(p.price * p.stock) }}</div>
              </button>
            </div>
          </template>
        </MetricsMenu>

        <div class="header-titles">
          <h3>Catálogo Global de Inventario</h3>
          <p>Ordenado automáticamente de menor a mayor stock disponible</p>
        </div>
      </div>

      <div class="inv-controls">
        <div class="search-box">
          <Search :size="16" class="search-ico" />
          <input v-model="searchQuery" type="text" placeholder="Buscar repuesto..." class="search-input" />
        </div>
        <div class="view-toggle">
          <button :class="['toggle-btn', { active: viewMode === 'list' }]" @click="viewMode = 'list'"><List :size="15" /><span>Lista</span></button>
          <button :class="['toggle-btn', { active: viewMode === 'cards' }]" @click="viewMode = 'cards'"><LayoutGrid :size="15" /><span>Tarjetas</span></button>
        </div>
      </div>
    </div>

    <p v-if="!sortedProducts.length" class="empty">No hay repuestos que coincidan con la búsqueda.</p>
    <ProductCollection :items="sortedProducts" :view="viewMode" @open="selected = $event" />

    <ProductDetailModal v-if="selected" :product="selected" @close="selected = null" />
  </section>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { Package, AlertTriangle, DollarSign, Search, List, LayoutGrid } from 'lucide-vue-next'
import MetricsMenu from './MetricsMenu.vue'
import ProductCollection from './ProductCollection.vue'
import ProductDetailModal from './ProductDetailModal.vue'
import { formatCOP } from '../data/productos'

const props = defineProps({ products: { type: Array, default: () => [] } })

const searchQuery = ref('')
const viewMode = ref('list')
const selected = ref(null)

const ctl = reactive({
  total: { sort: 'stock-desc', cat: '', view: 'list' },
  critico: { sort: 'stock-asc', cat: '', view: 'list' }
})

const sortOptions = [
  { value: 'stock-desc', label: 'Mayor a menor stock' },
  { value: 'stock-asc', label: 'Menor a mayor stock' },
  { value: 'cat', label: 'Categoría (A–Z)' },
  { value: 'name', label: 'Nombre (A–Z)' },
  { value: 'price-desc', label: 'Mayor precio' },
  { value: 'price-asc', label: 'Menor precio' }
]
const sorters = {
  'stock-desc': (a, b) => b.stock - a.stock,
  'stock-asc': (a, b) => a.stock - b.stock,
  cat: (a, b) => a.category.localeCompare(b.category) || a.name.localeCompare(b.name),
  name: (a, b) => a.name.localeCompare(b.name),
  'price-desc': (a, b) => b.price - a.price,
  'price-asc': (a, b) => a.price - b.price
}

const categories = computed(() => [...new Set(props.products.map(p => p.category))].sort())

const sortedProducts = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  const list = q
    ? props.products.filter(p => p.name.toLowerCase().includes(q) || p.code.toLowerCase().includes(q) || p.category.toLowerCase().includes(q))
    : props.products
  return [...list].sort(sorters['stock-asc'])
})

const panelList = (kind) => {
  const c = ctl[kind]
  let list = kind === 'critico' ? props.products.filter(p => p.stock <= 3) : props.products
  if (c.cat) list = list.filter(p => p.category === c.cat)
  return [...list].sort(sorters[c.sort])
}

const totalUnits = computed(() => props.products.reduce((a, p) => a + p.stock, 0))
const criticalCount = computed(() => props.products.filter(p => p.stock <= 3).length)
const mediumCount = computed(() => props.products.filter(p => p.stock > 3 && p.stock <= 15).length)
const inventoryValue = computed(() => props.products.reduce((a, p) => a + p.price * p.stock, 0))

const valueByCategory = computed(() => {
  const map = {}
  props.products.forEach(p => { map[p.category] = (map[p.category] || 0) + p.price * p.stock })
  const total = inventoryValue.value || 1
  return Object.entries(map)
    .map(([name, value]) => ({ name, value, pct: Math.round((value / total) * 100) }))
    .sort((a, b) => b.value - a.value)
})
const topByValue = computed(() => [...props.products].sort((a, b) => b.price * b.stock - a.price * a.stock).slice(0, 3))

const menuItems = computed(() => [
  { key: 'total', label: 'Total de repuestos', value: `${props.products.length} referencias · ${totalUnits.value} u.`, icon: Package, tone: 'orange' },
  { key: 'critico', label: 'Stock crítico', value: `${criticalCount.value} ${criticalCount.value === 1 ? 'ítem urgente' : 'ítems urgentes'}`, icon: AlertTriangle, tone: 'red' },
  { key: 'valor', label: 'Valor del inventario', value: `$ ${formatCOP(inventoryValue.value)}`, icon: DollarSign, tone: 'green' }
])
</script>

<style scoped>
.card { background-color: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; display: flex; flex-direction: column; gap: 22px; }
.inv-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px; }
.inv-left { display: flex; align-items: center; gap: 14px; }
.header-titles h3 { font-size: 17px; font-weight: 600; margin: 0 0 4px; }
.header-titles p { font-size: 12px; color: var(--text-secondary); margin: 0; }
.inv-controls { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.search-box { position: relative; display: flex; align-items: center; }
.search-ico { position: absolute; left: 12px; color: var(--text-secondary); }
.search-input { background-color: var(--input-bg); border: 1px solid var(--border-color); border-radius: 10px; padding: 8px 14px 8px 36px; color: var(--text-primary); font-size: 12px; outline: none; width: 220px; height: 40px; box-sizing: border-box; }
.search-input:focus { border-color: #E67E22; }
.view-toggle { display: flex; background: var(--input-bg); border: 1px solid var(--border-color); padding: 4px; border-radius: 10px; gap: 4px; height: 40px; box-sizing: border-box; align-items: center; }
.toggle-btn { background: transparent; border: none; color: var(--text-secondary); padding: 6px 12px; border-radius: 6px; font-size: 12px; cursor: pointer; display: flex; align-items: center; gap: 6px; transition: all 0.2s; }
.toggle-btn:hover { color: #E67E22; }
.toggle-btn.active { background-color: #E67E22; color: #FFFFFF; font-weight: 600; }
.empty { font-size: 13px; color: var(--text-secondary); margin: 0; }
</style>
