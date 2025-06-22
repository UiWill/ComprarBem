<template>
  <div style="background: red; color: white; padding: 50px; font-size: 24px; font-weight: bold;">
    🚨 TESTE BÁSICO - VOCÊ ESTÁ VENDO ISTO?
    <br><br>
    Se você vê esta mensagem vermelha, o Vue.js funciona!
    <br><br>
    Número: {{ numero || $route.params.numero || 'NENHUM' }}
    <br>
    Data: {{ new Date().toLocaleString('pt-BR') }}
  </div>
</template>

<script>
export default {
  name: 'ValidarDCB',
  props: {
    numero: String
  }
}
</script> 