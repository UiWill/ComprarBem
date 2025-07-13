<template>
  <div class="pesquisa-tecnica-view">
    <PesquisaBot />
  </div>
</template>

<script>
import PesquisaBot from '@/components/common/PesquisaBot.vue';

export default {
  name: 'PesquisaTecnica',
  components: {
    PesquisaBot
  }
};
</script>

<style scoped>
.pesquisa-tecnica-view {
  min-height: 100vh;
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 20px 0;
}
</style> 