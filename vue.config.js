module.exports = {
  publicPath: process.env.NODE_ENV === 'production'
    ? '/ComprarBem/'  // Nome do repositório no GitHub
    : '/',
  lintOnSave: false,
  // Outras configurações do Vue CLI
  configureWebpack: {
    performance: {
      hints: false
    }
  }
} 