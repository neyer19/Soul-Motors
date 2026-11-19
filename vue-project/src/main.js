import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './assets/tokens.css' // <--- Importante para cargar los tokens globales

createApp(App).use(router).mount('#app')