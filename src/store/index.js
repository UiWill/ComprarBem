import Vue from 'vue'
import Vuex from 'vuex'
import { supabase } from '@/services/supabase'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    user: null,
    tenant: null,
    isLoading: false
  },
  mutations: {
    SET_USER(state, user) {
      state.user = user
    },
    SET_TENANT(state, tenant) {
      state.tenant = tenant
    },
    SET_LOADING(state, isLoading) {
      state.isLoading = isLoading
    }
  },
  actions: {
    async fetchUser({ commit }) {
      const { data } = await supabase.auth.getSession()
      const user = data?.session?.user
      commit('SET_USER', user)
      
      if (user) {
        // Buscar informações do tenant
        const { data: tenantData, error } = await supabase
          .from('tenants')
          .select('*')
          .eq('id', user.user_metadata?.tenant_id)
          .single()
        
        if (!error && tenantData) {
          commit('SET_TENANT', tenantData)
        }
      }
    },
    setLoading({ commit }, isLoading) {
      commit('SET_LOADING', isLoading)
    }
  },
  getters: {
    isAuthenticated: state => !!state.user,
    currentUser: state => state.user,
    currentTenant: state => state.tenant,
    isLoading: state => state.isLoading
  }
}) 