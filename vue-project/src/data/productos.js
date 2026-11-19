// Fuente única de productos para Administrador, Gerente, Vendedor y Mecánico.
// Las fotos están en /public/assets/productos. Specs y "sold" son datos de ejemplo editables.
export const productosBase = [
  { code: '#REP-102', name: 'Kit de Arrastre Pulsar NS 200', category: 'Transmisión', price: 210000, stock: 2, maxStock: 20, sold: 6,
    image: '/assets/productos/kit-arrastre.jpg', compat: 'Bajaj Pulsar NS 200', ubicacion: 'Bodega A · Estante 4',
    description: 'Juego completo de transmisión secundaria para mantener la potencia y la suavidad de marcha de la moto.',
    specs: [{ label: 'Componentes', value: 'Piñón, cadena y corona' }, { label: 'Aplicación', value: 'Transmisión' }] },
  { code: '#REP-105', name: 'Filtro de Aceite Yamaha FZ 25', category: 'Filtros', price: 28000, stock: 5, maxStock: 25, sold: 31,
    image: '/assets/productos/filtro-aceite.jpg', compat: 'Yamaha FZ 25', ubicacion: 'Bodega A · Estante 1',
    description: 'Filtro de aceite para retener impurezas y proteger el motor entre cada cambio de lubricante.',
    specs: [{ label: 'Aplicación', value: 'Filtrado de aceite del motor' }, { label: 'Cambio sugerido', value: 'Con cada cambio de aceite' }] },
  { code: '#REP-103', name: 'Pastillas de Freno Delanteras', category: 'Frenos', price: 65000, stock: 12, maxStock: 30, sold: 19,
    image: '/assets/productos/pastillas-freno.jpg', compat: 'Según referencia de la moto', ubicacion: 'Bodega B · Estante 1',
    description: 'Juego de pastillas para el freno delantero. Verifica la referencia de la moto antes de la instalación.',
    specs: [{ label: 'Posición', value: 'Delantera' }, { label: 'Aplicación', value: 'Sistema de frenos' }] },
  { code: '#REP-101', name: 'Aceite Sintético 10W40 4T (1L)', category: 'Lubricantes', price: 45000, stock: 34, maxStock: 50, sold: 48,
    image: '/assets/productos/aceite-10w40.jpg', compat: 'Motocicletas de 4 tiempos', ubicacion: 'Bodega A · Estante 2',
    description: 'Lubricante sintético para motores de cuatro tiempos, pensado para uso diario en ciudad y carretera.',
    specs: [{ label: 'Viscosidad', value: '10W-40' }, { label: 'Tipo', value: 'Sintético' }, { label: 'Presentación', value: '1 litro' }] },
  { code: '#REP-104', name: 'Bujía Iridium CR9EIX', category: 'Encendido', price: 52000, stock: 45, maxStock: 60, sold: 27,
    image: '/assets/productos/bujia-iridium.jpg', compat: 'Motocicletas 4T (verificar referencia)', ubicacion: 'Bodega B · Estante 3',
    description: 'Bujía de electrodo de iridio para un encendido estable y una combustión eficiente.',
    specs: [{ label: 'Tipo', value: 'Iridium' }, { label: 'Referencia', value: 'CR9EIX' }, { label: 'Aplicación', value: 'Sistema de encendido' }] }
]

export const getProducts = () => productosBase.map(p => ({ ...p, specs: p.specs.map(s => ({ ...s })) }))

export const stockLevel = (s) => (s <= 3 ? 'danger' : s <= 15 ? 'warning' : 'success')
export const stockLabel = (s) => (s === 0 ? 'Sin stock' : s <= 3 ? 'Agotándose' : s <= 15 ? 'Stock medio' : 'Disponible')
export const stockColor = (s) => ({ danger: '#E74C3C', warning: '#F1C40F', success: '#2ECC71' }[stockLevel(s)])
export const stockPct = (p) => `${Math.min(100, Math.max(0, (p.stock / p.maxStock) * 100))}%`
export const formatCOP = (n) => Number(n).toLocaleString('es-CO')
