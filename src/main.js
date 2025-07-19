import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import VueSweetalert2 from 'vue-sweetalert2'
import 'sweetalert2/dist/sweetalert2.min.css'
import Loading from 'vue-loading-overlay'
import 'vue-loading-overlay/dist/vue-loading.css'
import '@fortawesome/fontawesome-free/css/all.css'

Vue.config.productionTip = false

Vue.use(VueSweetalert2)
Vue.use(Loading)

new Vue({
  router,
  store,
  render: h => h(App),
  mounted() {
    console.log('🚀 Sistema Comprar Bem carregado - Notificações automáticas via GitHub Actions')
  }
}).$mount('#app') 