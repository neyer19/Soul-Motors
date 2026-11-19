<template>
  <img 
    :src="logoSrc" 
    alt="SoulMotors Logo" 
    class="brand-logo-img"
    :style="{ height: `${height}px` }"
  />
</template>

<script setup>
import { computed } from 'vue'

// Usamos el naranja para el modo oscuro y el blanco para el modo claro
import logoNaranja from '../assets/logo-soulmotors-naranja.png'
import logoBlanco from '../assets/logo-soulmotors-blanco.png'

const props = defineProps({
  isDarkMode: {
    type: Boolean,
    default: true
  },
  height: {
    type: Number,
    default: 40
  }
})

const logoSrc = computed(() => {
  return props.isDarkMode ? logoNaranja : logoBlanco
})
</script>

<style scoped>
.brand-logo-img {
  width: auto;
  object-fit: contain;
  display: block;
  transition: opacity 0.2s ease;
}
</style>