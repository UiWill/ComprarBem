const { defineConfig } = require('@vue/cli-service')

module.exports = defineConfig({
  transpileDependencies: true,
  publicPath: process.env.NODE_ENV === 'production'
    ? '/' // Domínio próprio - sem subpasta
    : '/',
  lintOnSave: false // Desabilita o lint durante o build
}) 