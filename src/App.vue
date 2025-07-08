<template>
  <div id="app">
    <router-view />
    <AIChat />
  </div>
</template>

<script>
import AIChat from '@/components/common/AIChat.vue';

export default {
  name: 'App',
  components: {
    AIChat
  }
};
</script>

<style>
html, body {
  margin: 0;
  padding: 0;
  font-family: Arial, sans-serif;
  font-size: 16px;
  color: #333;
  background-color: #f5f7fa;
}

* {
  box-sizing: border-box;
}

#app {
  min-height: 100vh;
}
</style> 