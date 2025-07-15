<template>
  <div class="classificacao-container">
    <h2>Classificação de Materiais</h2>
    
    <div class="tabs">
      <button 
        :class="['tab-button', { active: activeTab === 'grupos' }]" 
        @click="activeTab = 'grupos'"
      >
        Grupos
      </button>
      <button 
        :class="['tab-button', { active: activeTab === 'classes' }]" 
        @click="activeTab = 'classes'"
      >
        Classes
      </button>
    </div>
    
    <div class="tab-content">
      <GruposList v-if="activeTab === 'grupos'" />
      <ClassesList v-if="activeTab === 'classes'" />
    </div>
  </div>
</template>

<script>
import GruposList from './GruposList.vue'
import ClassesList from './ClassesList.vue'
import { ref } from 'vue'

export default {
  name: 'Classificacao',
  components: {
    GruposList,
    ClassesList
  },
  setup() {
    const activeTab = ref('grupos')
    
    return {
      activeTab
    }
  }
}
</script>

<style scoped>
.classificacao-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

h2 {
  margin-bottom: 20px;
  color: #2c3e50;
}

.tabs {
  display: flex;
  margin-bottom: 20px;
  border-bottom: 1px solid #ddd;
}

.tab-button {
  padding: 10px 20px;
  margin-right: 5px;
  background-color: #f8f9fa;
  border: 1px solid #ddd;
  border-bottom: none;
  border-top-left-radius: 4px;
  border-top-right-radius: 4px;
  cursor: pointer;
  position: relative;
  top: 1px;
}

.tab-button.active {
  background-color: white;
  border-bottom: 1px solid white;
  font-weight: bold;
}

.tab-content {
  background-color: white;
  border: 1px solid #ddd;
  border-top: none;
  padding: 0;
  border-bottom-left-radius: 4px;
  border-bottom-right-radius: 4px;
}
</style> 