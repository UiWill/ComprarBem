<template>
  <div style="background: red; color: white; padding: 50px; font-size: 24px; font-weight: bold;">
    🚨 TESTE BÁSICO - VOCÊ ESTÁ VENDO ISTO?
    <br><br>
    Se você vê esta mensagem vermelha, o Vue.js funciona!
    <br><br>
    Número: {{ numero || $route.params.numero || 'NENHUM' }}
    <br>
    Ano: {{ ano || $route.params.ano || 'NENHUM' }}
    <br>
    Data: {{ new Date().toLocaleString('pt-BR') }}
    <br><br>
    <button @click="testarAlert" style="background: white; color: red; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer;">
      CLIQUE PARA TESTAR JAVASCRIPT
    </button>
  </div>
</template>

<script>
export default {
  name: 'ValidarDCB',
  props: {
    numero: String,
    ano: String
  },
  mounted() {
    console.log('=== COMPONENTE VALIDAR DCB CARREGOU ===')
    console.log('Params:', this.$route.params)
    console.log('Numero:', this.numero)
    console.log('Ano:', this.ano)
    
    // Alert para confirmar que o componente carregou
    setTimeout(() => {
      alert('🎯 COMPONENTE VALIDAR DCB CARREGOU COM SUCESSO!')
    }, 500)
  },
  methods: {
    testarAlert() {
      alert('✅ JavaScript está funcionando!')
    }
  }
}
</script> 