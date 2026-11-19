<template>
  <div class="app-wrapper">
    <router-view
      :isDarkMode="isDarkMode"
      :userEmail="email"
      @toggle-theme="toggleTheme"
      @change-view="changeView"
      @login="onLogin"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const isDarkMode = ref(true)
const email = ref('') // correo con el que se inició sesión (lo usa MecanicoView)

const applyTheme = (dark) => {
  const root = document.documentElement
  root.classList.remove('dark', 'light')
  root.classList.add(dark ? 'dark' : 'light')
}

const toggleTheme = () => { 
  isDarkMode.value = !isDarkMode.value
  applyTheme(isDarkMode.value)
}

onMounted(() => {
  applyTheme(isDarkMode.value)
})

// Las vistas emiten 'change-view' con 'login', 'inventario', 'gerente', etc.
const changeView = (name) => { router.push('/' + name) }

// LoginView avisa con qué correo entró
const onLogin = (mail) => { email.value = mail }
</script>

<style>
/* Eliminamos los duplicados y dejamos que tokens.css mande las variables globales */
.app-wrapper {
  min-height: 100vh;
  background-color: var(--bg-canvas);
  color: var(--text-primary);
  transition: background-color 0.3s ease, color 0.3s ease;
}
</style>