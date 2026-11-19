<template>
  <div :class="['login-container', isDarkMode ? 'dark-theme' : 'light-theme']">
    <div class="login-card">
      <div class="login-logo">
        <BrandLogo :isDarkMode="isDarkMode" :height="72" />
      </div>
      
      <div class="login-form">
        <div class="form-group">
          <label>Correo Electrónico</label>
          <input 
            type="email" 
            v-model="email" 
            placeholder="ejemplo@soulmotors.com"
            required
          />
        </div>

        <div class="form-group">
          <label>Contraseña</label>
          <input 
            type="password" 
            v-model="password" 
            placeholder="••••••••"
            required
          />
        </div>

        <button type="button" @click="handleLogin" class="btn-submit">Ingresar al Sistema</button>
      </div>

      <div class="login-footer">
        <button class="theme-toggle-btn" @click="toggleTheme">
          <Sun v-if="isDarkMode" :size="16" />
          <Moon v-else :size="16" />
          <span>{{ isDarkMode ? 'Modo Claro' : 'Modo Oscuro' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Sun, Moon } from 'lucide-vue-next'
import BrandLogo from '../components/BrandLogo.vue'

const router = useRouter()
defineProps({ isDarkMode: Boolean })
const emit = defineEmits(['toggle-theme', 'login'])

const email = ref('administrador@soulmotors.com')
const password = ref('')

const toggleTheme = () => emit('toggle-theme')

const handleLogin = () => {
  const mail = email.value.trim().toLowerCase()
  emit('login', email.value.trim())

  if (mail.includes('admin')) {
    router.push('/admin')
  } else if (mail.includes('finanzas')) {
    router.push('/finanzas')
  } else if (mail.includes('inventario')) {
    router.push('/inventario')
  } else if (mail.includes('mecanico')) {
    router.push('/mecanico')
  } else if (mail.includes('trabajador')) {
    router.push('/trabajadores')
  } else if (mail.includes('vendedor')) {
    router.push('/vendedor')
  } else {
    router.push('/gerente')
  }
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: var(--bg-main, #1E1F22);
  color: var(--text-primary, #F2F2F2);
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  transition: background-color 0.3s ease;
}

.login-container.dark-theme {
  background-color: #1E1F22;
  --bg-card: #2B2D30;
  --border-color: #3C3F41;
  --text-primary: #F2F2F2;
  --text-secondary: #9DA5B4;
  --input-bg: #232428;
}

.login-container.light-theme {
  background-color: #F4F6F8;
  --bg-card: #FFFFFF;
  --border-color: #D1D5DB;
  --text-primary: #1F2937;
  --text-secondary: #6B7280;
  --input-bg: #F9FAFB;
}

.login-card {
  background-color: var(--bg-card, #2B2D30);
  border: 1px solid var(--border-color, #3C3F41);
  padding: 40px;
  border-radius: 20px;
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  transition: background-color 0.3s ease, border-color 0.3s ease;
}

.login-logo {
  margin-bottom: 24px;
  display: flex;
  justify-content: center;
}

.login-form {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 13px;
  color: var(--text-secondary, #9DA5B4);
  font-weight: 500;
}

.form-group input {
  background-color: var(--input-bg, #232428);
  border: 1px solid var(--border-color, #3C3F41);
  color: var(--text-primary, #F2F2F2);
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s, background-color 0.3s ease, color 0.3s ease;
}

.form-group input::placeholder {
  color: var(--text-secondary, #9DA5B4);
  opacity: 0.7;
}

.form-group input:focus {
  border-color: #E67E22;
}

.btn-submit {
  background-color: #E67E22;
  color: #FFFFFF;
  border: none;
  padding: 12px;
  border-radius: 12px;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 10px;
  transition: background-color 0.2s;
}

.btn-submit:hover {
  background-color: #D35400;
}

.login-footer {
  margin-top: 24px;
  display: flex;
  justify-content: center;
}

.theme-toggle-btn {
  background-color: rgba(230, 126, 34, 0.1);
  color: #E67E22;
  border: 1px solid #E67E22;
  padding: 8px 16px;
  border-radius: 12px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background-color 0.2s;
}

.theme-toggle-btn:hover {
  background-color: rgba(230, 126, 34, 0.2);
}
</style>