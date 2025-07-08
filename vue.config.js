const { defineConfig } = require('@vue/cli-service')

module.exports = defineConfig({
  transpileDependencies: true,
  publicPath: process.env.NODE_ENV === 'production'
    ? '/ComprarBem/' // Nome correto do repositório
    : '/',
  lintOnSave: false // Desabilita o lint durante o build
}) 