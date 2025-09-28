<template>
  <div class="visualizador-pagina">
    <!-- Visualizador customizado sem controles -->
    <div class="pdf-container">
      <embed
        :src="urlPagina"
        type="application/pdf"
        class="pdf-embed"
        :style="estiloEmbed"
      />
    </div>

    <!-- Fallback para navegadores que não suportam embed -->
    <div v-if="mostrarFallback" class="pdf-fallback">
      <iframe
        :src="urlPagina"
        class="pdf-iframe"
        frameborder="0"
        scrolling="no"
      ></iframe>
    </div>
  </div>
</template>

<script>
export default {
  name: 'VisualizadorPaginaPDF',
  props: {
    url: {
      type: String,
      required: true
    },
    numeroPagina: {
      type: Number,
      default: 1
    },
    largura: {
      type: String,
      default: '100%'
    },
    altura: {
      type: String,
      default: '600px'
    }
  },
  data() {
    return {
      mostrarFallback: false
    }
  },
  computed: {
    urlPagina() {
      // URL com parâmetros para mostrar página específica e ocultar controles
      return `${this.url}#page=${this.numeroPagina}&toolbar=0&navpanes=0&scrollbar=0&view=FitH`
    },
    estiloEmbed() {
      return {
        width: this.largura,
        height: this.altura,
        border: 'none',
        overflow: 'hidden'
      }
    }
  },
  mounted() {
    // Verificar se o navegador suporta embed para PDF
    this.verificarSuporteEmbed()
  },
  methods: {
    verificarSuporteEmbed() {
      // Tentar detectar se o navegador suporta embed para PDF
      const embed = document.createElement('embed')
      embed.src = 'data:application/pdf;base64,'

      setTimeout(() => {
        // Se embed não funcionar, usar iframe como fallback
        if (embed.offsetHeight === 0) {
          this.mostrarFallback = true
        }
      }, 100)
    }
  }
}
</script>

<style scoped>
.visualizador-pagina {
  width: 100%;
  height: 100%;
  position: relative;
  background: #f5f5f5;
}

.pdf-container {
  width: 100%;
  height: 100%;
  position: relative;
}

.pdf-embed,
.pdf-iframe {
  width: 100%;
  height: 100%;
  border: none;
  background: white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.pdf-fallback {
  width: 100%;
  height: 100%;
}

/* Ocultar controles do PDF via CSS se necessário */
.pdf-embed::-webkit-media-controls,
.pdf-embed::-webkit-media-controls-enclosure {
  display: none !important;
}
</style>