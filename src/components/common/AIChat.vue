<template>
  <div class="ai-chat" :class="{ 'ai-chat--expanded': isExpanded }">
    <!-- Botão flutuante com animação de pulso -->
    <button 
      v-if="!isExpanded" 
      class="ai-chat__button"
      @click="toggleChat"
      title="QualiBot 2.0 - Seu Assistente de Licitações"
    >
      <div class="ai-chat__button-content">
        <i class="fas fa-robot"></i>
        <span class="ai-chat__button-label">QualiBot 2.0</span>
      </div>
      <div class="ai-chat__notification" v-if="!hasInteracted">
        <i class="fas fa-bolt"></i> Como posso ajudar?
      </div>
    </button>

    <!-- Janela do chat -->
    <div v-else class="ai-chat__window">
      <div class="ai-chat__header">
        <div class="ai-chat__header-info">
          <div class="ai-chat__logo">
            <i class="fas fa-robot"></i>
            <i class="fas fa-bolt ai-chat__bolt"></i>
          </div>
          <div>
            <h3>QualiBot 2.0</h3>
            <span class="ai-chat__status">
              <span class="ai-chat__status-dot"></span>
              Online e Pronto
            </span>
          </div>
        </div>
        <button class="ai-chat__close" @click="toggleChat">
          <i class="fas fa-times"></i>
        </button>
      </div>

      <div class="ai-chat__messages" ref="messagesContainer">
        <div 
          v-for="(message, index) in messages" 
          :key="index"
          :class="['ai-chat__message', `ai-chat__message--${message.type}`, { 'ai-chat__message--status': message.isStatus }]"
        >
          <div class="ai-chat__message-avatar" v-if="message.type === 'assistant'">
            <i class="fas fa-robot"></i>
            <i class="fas fa-bolt ai-chat__bolt-small"></i>
          </div>
          <div class="ai-chat__message-content">
            <span v-if="message.isStatus" class="ai-chat__status-text">
              <i class="fas fa-spinner fa-spin"></i>
              {{ message.text }}
            </span>
            <span v-else>{{ message.text }}</span>
          </div>
        </div>
        <div v-if="isLoading" class="ai-chat__message ai-chat__message--assistant">
          <div class="ai-chat__message-avatar">
            <i class="fas fa-robot"></i>
            <i class="fas fa-bolt ai-chat__bolt-small"></i>
          </div>
          <div class="ai-chat__typing">
            <span></span>
            <span></span>
            <span></span>
          </div>
        </div>
      </div>

      <div class="ai-chat__input">
        <textarea 
          v-model="currentMessage" 
          @keydown.enter.prevent="sendMessage"
          placeholder="Digite sua dúvida sobre licitações..."
          rows="2"
        ></textarea>
        <button 
          @click="sendMessage"
          :disabled="isLoading || !currentMessage.trim()"
          class="ai-chat__send"
        >
          <i class="fas fa-paper-plane"></i>
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { geminiService } from '@/services/geminiService';

export default {
  name: 'AIChat',
  data() {
    return {
      isExpanded: false,
      hasInteracted: false,
      messages: [
        {
          type: 'assistant',
          text: 'Olá! Sou o QualiBot 2.0, seu assistente virtual especializado em licitações e compras públicas. Como posso ajudar hoje?'
        }
      ],
      currentMessage: '',
      isLoading: false
    };
  },
  methods: {
    toggleChat() {
      this.isExpanded = !this.isExpanded;
      this.hasInteracted = true;
      if (this.isExpanded) {
        this.$nextTick(() => {
          this.scrollToBottom();
        });
      }
    },
    async sendMessage() {
      if (!this.currentMessage.trim() || this.isLoading) return;

      const userMessage = this.currentMessage.trim();
      this.messages.push({
        type: 'user',
        text: userMessage
      });
      this.currentMessage = '';
      this.isLoading = true;

      // Adicionar mensagem de status para tentativas
      const statusMessage = {
        type: 'assistant',
        text: 'Processando sua solicitação...',
        isStatus: true
      };
      this.messages.push(statusMessage);
      
      // Função para atualizar status
      const updateStatus = (newText) => {
        const statusIndex = this.messages.findIndex(msg => msg.isStatus);
        if (statusIndex !== -1) {
          this.messages[statusIndex].text = newText;
        }
      };

      // Interceptar logs do console para atualizar status
      const originalLog = console.log;
      console.log = (...args) => {
        const message = args.join(' ');
        
        // Atualizar status baseado nos logs do geminiService
        if (message.includes('🚀 Tentando modelo')) {
          const modelMatch = message.match(/🚀 Tentando modelo \d+\/\d+: (.+)/);
          if (modelMatch) {
            updateStatus(`Tentando modelo ${modelMatch[1]}...`);
          }
        } else if (message.includes('Erro temporário')) {
          updateStatus('Erro temporário detectado, tentando novamente...');
        } else if (message.includes('🔄 Tentando próximo modelo')) {
          const modelMatch = message.match(/🔄 Tentando próximo modelo: (.+)/);
          if (modelMatch) {
            updateStatus(`Tentando modelo alternativo: ${modelMatch[1]}...`);
          }
        }
        
        // Chamar o log original
        originalLog.apply(console, args);
      };

      try {
        const response = await geminiService.chat(userMessage);
        
        // Restaurar console.log original
        console.log = originalLog;
        
        // Remover mensagem de status
        const statusIndex = this.messages.findIndex(msg => msg.isStatus);
        if (statusIndex !== -1) {
          this.messages.splice(statusIndex, 1);
        }
        
        this.messages.push({
          type: 'assistant',
          text: response
        });
      } catch (error) {
        console.error('Erro no chat:', error);
        
        // Restaurar console.log original
        console.log = originalLog;
        
        // Remover mensagem de status
        const statusIndex = this.messages.findIndex(msg => msg.isStatus);
        if (statusIndex !== -1) {
          this.messages.splice(statusIndex, 1);
        }
        
        // Mensagem de erro mais específica baseada no tipo de erro
        let errorMessage = 'Desculpe, estou enfrentando algumas dificuldades técnicas no momento.';
        
        if (error.message.includes('sobrecarregado') || error.message.includes('overloaded')) {
          errorMessage = 'O serviço está temporariamente sobrecarregado devido ao alto volume de usuários. Já tentei várias vezes automaticamente. Por favor, aguarde alguns minutos e tente novamente.';
        } else if (error.message.includes('conexão') || error.message.includes('network')) {
          errorMessage = 'Problema de conexão detectado. Verifique sua internet e tente novamente.';
        } else if (error.message.includes('indisponível') || error.message.includes('unavailable')) {
          errorMessage = 'O serviço está temporariamente indisponível. Nossa equipe já está trabalhando nisso. Tente novamente em alguns minutos.';
        }
        
        this.messages.push({
          type: 'assistant',
          text: errorMessage + '\n\n💡 **Dica**: Se o problema persistir, você pode tentar reformular sua pergunta ou contactar o suporte através do menu principal.'
        });
      } finally {
        this.isLoading = false;
        this.$nextTick(() => {
          this.scrollToBottom();
        });
      }
    },
    scrollToBottom() {
      const container = this.$refs.messagesContainer;
      container.scrollTop = container.scrollHeight;
    }
  }
};
</script>

<style scoped>
.ai-chat {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 1000;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.ai-chat__button {
  min-width: 60px;
  height: 60px;
  border-radius: 30px;
  background: linear-gradient(135deg, #00c6ff, #0072ff);
  border: none;
  color: white;
  cursor: pointer;
  box-shadow: 0 4px 15px rgba(0, 198, 255, 0.3);
  transition: all 0.3s ease;
  padding: 0 25px;
  position: relative;
  overflow: hidden;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% {
    box-shadow: 0 4px 15px rgba(0, 198, 255, 0.3);
  }
  50% {
    box-shadow: 0 4px 25px rgba(0, 198, 255, 0.5);
  }
  100% {
    box-shadow: 0 4px 15px rgba(0, 198, 255, 0.3);
  }
}

.ai-chat__button-content {
  display: flex;
  align-items: center;
  gap: 10px;
}

.ai-chat__button-label {
  font-weight: 600;
  font-size: 16px;
  white-space: nowrap;
}

.ai-chat__button:hover {
  transform: translateY(-2px);
  background: linear-gradient(135deg, #00d4ff, #0080ff);
}

.ai-chat__notification {
  position: absolute;
  top: -45px;
  right: 0;
  background: linear-gradient(135deg, #ffffff, #f8f9fa);
  padding: 10px 20px;
  border-radius: 20px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  color: #0072ff;
  font-size: 14px;
  font-weight: 600;
  animation: fadeInDown 0.5s ease;
  border: 2px solid rgba(0, 198, 255, 0.2);
}

.ai-chat__notification i {
  color: #00c6ff;
  margin-right: 5px;
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.ai-chat__window {
  width: 380px;
  height: 600px;
  background: white;
  border-radius: 20px;
  box-shadow: 0 5px 25px rgba(0, 0, 0, 0.15);
  display: flex;
  flex-direction: column;
  animation: slideIn 0.3s ease;
  border: 2px solid rgba(0, 198, 255, 0.1);
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.ai-chat__header {
  padding: 20px;
  background: linear-gradient(135deg, #00c6ff, #0072ff);
  color: white;
  border-radius: 18px 18px 0 0;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.ai-chat__header-info {
  display: flex;
  align-items: center;
  gap: 15px;
}

.ai-chat__logo {
  position: relative;
  width: 40px;
  height: 40px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ai-chat__bolt {
  position: absolute;
  bottom: -2px;
  right: -2px;
  font-size: 12px;
  background: #00c6ff;
  padding: 4px;
  border-radius: 50%;
  animation: flash 1.5s infinite;
}

@keyframes flash {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.ai-chat__header h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
}

.ai-chat__status {
  font-size: 12px;
  display: flex;
  align-items: center;
  gap: 5px;
  opacity: 0.9;
}

.ai-chat__status-dot {
  width: 8px;
  height: 8px;
  background: #4CAF50;
  border-radius: 50%;
  display: inline-block;
  animation: pulse-dot 1.5s infinite;
}

@keyframes pulse-dot {
  0% {
    transform: scale(0.95);
    opacity: 0.8;
  }
  50% {
    transform: scale(1.1);
    opacity: 1;
  }
  100% {
    transform: scale(0.95);
    opacity: 0.8;
  }
}

.ai-chat__close {
  background: rgba(255, 255, 255, 0.2);
  border: none;
  color: white;
  width: 30px;
  height: 30px;
  border-radius: 15px;
  cursor: pointer;
  transition: all 0.2s;
}

.ai-chat__close:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: rotate(90deg);
}

.ai-chat__messages {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  background: #f8f9fa;
}

.ai-chat__message {
  max-width: 85%;
  padding: 12px 16px;
  border-radius: 15px;
  font-size: 14px;
  line-height: 1.4;
  display: flex;
  gap: 10px;
  transition: all 0.2s;
}

.ai-chat__message:hover {
  transform: translateY(-1px);
}

.ai-chat__message--user {
  background: linear-gradient(135deg, #E3F2FD, #BBDEFB);
  align-self: flex-end;
  border-bottom-right-radius: 5px;
  color: #1565C0;
}

.ai-chat__message--assistant {
  background: white;
  align-self: flex-start;
  border-bottom-left-radius: 5px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
  border: 1px solid rgba(0, 198, 255, 0.1);
}

.ai-chat__message-avatar {
  position: relative;
  width: 30px;
  height: 30px;
  background: linear-gradient(135deg, #00c6ff, #0072ff);
  border-radius: 15px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 14px;
}

.ai-chat__bolt-small {
  position: absolute;
  bottom: -2px;
  right: -2px;
  font-size: 8px;
  background: #00c6ff;
  padding: 2px;
  border-radius: 50%;
  animation: flash 1.5s infinite;
}

.ai-chat__typing {
  display: flex;
  gap: 5px;
  padding: 10px;
}

.ai-chat__typing span {
  width: 8px;
  height: 8px;
  background: #00c6ff;
  border-radius: 50%;
  display: inline-block;
  animation: typing 1.4s infinite ease-in-out;
}

.ai-chat__typing span:nth-child(2) {
  animation-delay: 0.2s;
}

.ai-chat__typing span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-5px);
  }
}

.ai-chat__input {
  padding: 20px;
  border-top: 1px solid rgba(0, 198, 255, 0.1);
  display: flex;
  gap: 10px;
  background: white;
  border-radius: 0 0 20px 20px;
}

.ai-chat__input textarea {
  flex: 1;
  border: 2px solid rgba(0, 198, 255, 0.2);
  border-radius: 12px;
  padding: 12px;
  resize: none;
  font-family: inherit;
  font-size: 14px;
  transition: all 0.2s;
}

.ai-chat__input textarea:focus {
  outline: none;
  border-color: #00c6ff;
  box-shadow: 0 0 0 3px rgba(0, 198, 255, 0.1);
}

.ai-chat__send {
  background: linear-gradient(135deg, #00c6ff, #0072ff);
  border: none;
  color: white;
  width: 40px;
  height: 40px;
  border-radius: 20px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.ai-chat__send:hover:not(:disabled) {
  transform: scale(1.05);
  background: linear-gradient(135deg, #00d4ff, #0080ff);
}

.ai-chat__send:disabled {
  background: #ccc;
  cursor: not-allowed;
}

/* Estilização da barra de rolagem */
.ai-chat__messages::-webkit-scrollbar {
  width: 6px;
}

.ai-chat__messages::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 3px;
}

.ai-chat__messages::-webkit-scrollbar-thumb {
  background: rgba(0, 198, 255, 0.3);
  border-radius: 3px;
}

.ai-chat__messages::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 198, 255, 0.5);
}

/* Estilo para mensagem de status */
.ai-chat__message--status {
  opacity: 0.8;
  border: 2px dashed rgba(0, 198, 255, 0.3);
  background: linear-gradient(135deg, #f0f8ff, #e6f3ff) !important;
}

.ai-chat__status-text {
  color: #0072ff;
  font-style: italic;
  display: flex;
  align-items: center;
  gap: 8px;
}

.ai-chat__status-text i {
  color: #00c6ff;
}
</style> 