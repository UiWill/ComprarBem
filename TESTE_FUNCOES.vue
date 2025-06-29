<template>
  <div>
    <h1>Teste Funções</h1>
    <button @click="teste1">Teste 1</button>
    <button @click="teste2">Teste 2</button>
  </div>
</template>

<script>
export default {
  methods: {
    teste1() {
      console.log('Teste 1 funcionou!')
    },
    teste2() {
      console.log('Teste 2 funcionou!')
    }
  }
}
</script> 