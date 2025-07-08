const GEMINI_API_KEY = 'AIzaSyAf-Oe56q4Rao0OodEOtnEjtI_FpOmDg6I';
const IS_DEVELOPMENT = process.env.NODE_ENV === 'development';

// Usando o modelo correto que está disponível na v1beta
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// Configurações de retry
const RETRY_CONFIG = {
  maxRetries: 5,
  baseDelay: 1000, // 1 segundo
  maxDelay: 30000, // 30 segundos
  backoffFactor: 2
};

// Função para aguardar um tempo específico
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Função para calcular o delay com exponential backoff
const calculateDelay = (attempt) => {
  const delay = RETRY_CONFIG.baseDelay * Math.pow(RETRY_CONFIG.backoffFactor, attempt);
  return Math.min(delay, RETRY_CONFIG.maxDelay);
};

// Função para verificar se o erro é temporário e deve ser retentado
const isRetryableError = (error, response) => {
  // Erros de rede
  if (error.message && error.message.includes('Failed to fetch')) {
    return true;
  }
  
  // Erros HTTP temporários
  if (response) {
    const status = response.status;
    // 429 (Too Many Requests), 503 (Service Unavailable), 502 (Bad Gateway), 504 (Gateway Timeout)
    return status === 429 || status === 503 || status === 502 || status === 504;
  }
  
  return false;
};

export const geminiService = {
  async chat(message) {
    let lastError = null;
    
    for (let attempt = 0; attempt <= RETRY_CONFIG.maxRetries; attempt++) {
      try {
        const apiUrl = `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`;

        console.log(`Tentativa ${attempt + 1}/${RETRY_CONFIG.maxRetries + 1} - Enviando requisição para:`, apiUrl);

        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
          },
          body: JSON.stringify({
            contents: [{
              parts: [{
                text: `Você é o QualiBot 2.0, um assistente especializado em licitações e compras públicas, com foco em ajudar os usuários de forma rápida e eficiente. Responda a seguinte pergunta de forma clara e objetiva, usando sua expertise em licitações: ${message}`
              }]
            }]
          })
        });

        // Log da resposta para debug
        console.log(`Resposta da API (tentativa ${attempt + 1}):`, {
          status: response.status,
          statusText: response.statusText,
          ok: response.ok
        });

        const responseText = await response.text();
        
        // Se a resposta não for OK, verificar se é um erro temporário
        if (!response.ok) {
          const isTemporaryError = isRetryableError(null, response);
          
          if (isTemporaryError && attempt < RETRY_CONFIG.maxRetries) {
            const delay = calculateDelay(attempt);
            console.log(`Erro temporário (${response.status}). Aguardando ${delay}ms antes da próxima tentativa...`);
            await sleep(delay);
            continue;
          }
          
          // Se não é temporário ou esgotaram as tentativas, processar o erro
          let errorData;
          try {
            errorData = JSON.parse(responseText);
          } catch (e) {
            errorData = { error: { message: `Erro HTTP ${response.status}: ${response.statusText}` } };
          }
          
          console.error('Erro da API após todas as tentativas:', errorData);
          
          // Mensagens de erro mais específicas
          if (response.status === 503) {
            throw new Error('O serviço está temporariamente sobrecarregado. Tente novamente em alguns minutos.');
          } else if (response.status === 429) {
            throw new Error('Muitas requisições. Aguarde alguns minutos antes de tentar novamente.');
          } else if (response.status === 500) {
            throw new Error('Erro interno do servidor. Tente novamente mais tarde.');
          } else {
            throw new Error(errorData.error?.message || 'Erro na comunicação com o servidor');
          }
        }

        // Parse da resposta bem-sucedida
        let data;
        try {
          data = JSON.parse(responseText);
        } catch (e) {
          console.error('Erro ao fazer parse da resposta:', e);
          console.error('Resposta que causou erro:', responseText);
          
          if (attempt < RETRY_CONFIG.maxRetries) {
            const delay = calculateDelay(attempt);
            console.log(`Erro de parse. Aguardando ${delay}ms antes da próxima tentativa...`);
            await sleep(delay);
            continue;
          }
          
          throw new Error('Resposta inválida do servidor');
        }

        // Verificar se a resposta tem o formato esperado
        if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
          console.error('Resposta sem o formato esperado:', data);
          
          if (attempt < RETRY_CONFIG.maxRetries) {
            const delay = calculateDelay(attempt);
            console.log(`Formato de resposta inválido. Aguardando ${delay}ms antes da próxima tentativa...`);
            await sleep(delay);
            continue;
          }
          
          throw new Error('Resposta inválida do servidor');
        }

        // Sucesso! Retornar a resposta
        console.log('Resposta bem-sucedida recebida');
        return data.candidates[0].content.parts[0].text;

      } catch (error) {
        lastError = error;
        console.error(`Erro na tentativa ${attempt + 1}:`, error);

        // Se é um erro de rede ou temporário e ainda há tentativas restantes
        if (isRetryableError(error, null) && attempt < RETRY_CONFIG.maxRetries) {
          const delay = calculateDelay(attempt);
          console.log(`Erro de rede. Aguardando ${delay}ms antes da próxima tentativa...`);
          await sleep(delay);
          continue;
        }

        // Se não há mais tentativas ou é um erro não temporário, parar
        if (attempt >= RETRY_CONFIG.maxRetries) {
          break;
        }

        // Re-throw erros não temporários imediatamente
        throw error;
      }
    }

    // Se chegou aqui, esgotaram todas as tentativas
    console.error('Todas as tentativas falharam. Último erro:', lastError);
    
    if (lastError?.message?.includes('Failed to fetch')) {
      throw new Error('Não foi possível conectar ao servidor. Verifique sua conexão com a internet.');
    }
    
    throw new Error('O serviço está temporariamente indisponível. Tente novamente mais tarde.');
  }
}; 