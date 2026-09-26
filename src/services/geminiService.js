import { supabase } from './supabase';

let cachedApiKey = null;

const getApiKey = async () => {
  if (cachedApiKey) return cachedApiKey;

  const { data, error } = await supabase
    .from('configuracoes_api')
    .select('valor')
    .eq('chave', 'gemini_api_key')
    .single();

  if (error || !data) {
    throw new Error('Não foi possível obter a chave da API do Gemini');
  }

  cachedApiKey = data.valor;
  return cachedApiKey;
};

// Lista de modelos em ordem de prioridade (do mais novo e rápido para o mais antigo)
const GEMINI_MODELS = [
  {
    name: 'gemini-2.5-flash',
    url: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
    description: 'Gemini 2.5 Flash (Rápido e Eficiente)'
  },
  {
    name: 'gemini-flash-latest',
    url: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
    description: 'Gemini Flash (Última Versão Estável)'
  },
  {
    name: 'gemini-2.5-pro',
    url: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent',
    description: 'Gemini 2.5 Pro (Mais Avançado)'
  },
  {
    name: 'gemini-pro-latest',
    url: 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-latest:generateContent',
    description: 'Gemini Pro (Última Versão Estável)'
  }
];

// Configurações de retry por modelo (mais agressivo para o 2.0 Flash)
const RETRY_CONFIG = {
  maxRetries: 3, // Reduzido para ser mais rápido
  baseDelay: 800, // Delay inicial menor
  maxDelay: 12000, // Delay máximo menor
  backoffFactor: 1.8 // Fator de crescimento menor
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
  if (error && error.message && error.message.includes('Failed to fetch')) {
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

// Função para verificar se deve tentar outro modelo
const shouldTryNextModel = (error, response) => {
  // Se é um erro temporário, continuar tentando o mesmo modelo
  if (isRetryableError(error, response)) {
    return false;
  }
  
  // Se é um erro permanente, tentar próximo modelo
  if (response) {
    const status = response.status;
    // 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 500 (Internal Server Error)
    return status === 400 || status === 401 || status === 403 || status === 404 || status === 500;
  }
  
  return true;
};

// Função para fazer parse seguro do JSON
const safeJsonParse = (text) => {
  try {
    return JSON.parse(text);
  } catch (e) {
    console.error('Erro ao fazer parse do JSON:', e);
    console.error('Texto que causou erro:', text);
    return null;
  }
};

// Função para tentar um modelo específico
const tryModel = async (model, message, apiKey, attempt = 0) => {
  try {
    const apiUrl = `${model.url}?key=${apiKey}`;

    console.log(`Tentando modelo ${model.name} (tentativa ${attempt + 1}/${RETRY_CONFIG.maxRetries + 1})`);

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

    console.log(`Resposta do modelo ${model.name}:`, {
      status: response.status,
      statusText: response.statusText,
      ok: response.ok
    });

    const responseText = await response.text();
    
    // Se a resposta não for OK, verificar tipo de erro
    if (!response.ok) {
      const isTemporaryError = isRetryableError(null, response);
      
      if (isTemporaryError && attempt < RETRY_CONFIG.maxRetries) {
        const delay = calculateDelay(attempt);
        console.log(`Erro temporário (${response.status}) no modelo ${model.name}. Aguardando ${delay}ms...`);
        await sleep(delay);
        return tryModel(model, message, apiKey, attempt + 1);
      }
      
      // Erro permanente ou esgotaram tentativas
      let errorData = safeJsonParse(responseText);
      if (!errorData) {
        errorData = { 
          error: { 
            message: `Erro HTTP ${response.status}: ${response.statusText || 'Erro desconhecido'}` 
          } 
        };
      }
      
      console.error(`Erro no modelo ${model.name}:`, errorData);
      
      // Mensagem de erro mais específica
      let errorMessage = `Modelo ${model.name} falhou`;
      if (errorData.error && errorData.error.message) {
        errorMessage += `: ${errorData.error.message}`;
      } else {
        errorMessage += `: ${response.status} ${response.statusText || 'Erro desconhecido'}`;
      }
      
      throw new Error(errorMessage);
    }

    // Parse da resposta bem-sucedida
    const data = safeJsonParse(responseText);
    if (!data) {
      if (attempt < RETRY_CONFIG.maxRetries) {
        const delay = calculateDelay(attempt);
        console.log(`Erro de parse no modelo ${model.name}. Aguardando ${delay}ms...`);
        await sleep(delay);
        return tryModel(model, message, apiKey, attempt + 1);
      }
      
      throw new Error(`Modelo ${model.name} retornou resposta inválida`);
    }

    // Verificar se a resposta tem o formato esperado
    if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
      console.error(`Formato inválido no modelo ${model.name}:`, data);
      
      if (attempt < RETRY_CONFIG.maxRetries) {
        const delay = calculateDelay(attempt);
        console.log(`Formato inválido no modelo ${model.name}. Aguardando ${delay}ms...`);
        await sleep(delay);
        return tryModel(model, message, apiKey, attempt + 1);
      }
      
      throw new Error(`Modelo ${model.name} retornou formato inválido`);
    }

    // Sucesso!
    console.log(`✅ Sucesso com modelo ${model.name}!`);
    return {
      text: data.candidates[0].content.parts[0].text,
      modelUsed: model.name
    };

  } catch (error) {
    console.error(`Erro na tentativa ${attempt + 1} do modelo ${model.name}:`, error);

    // Se é um erro de rede ou temporário e ainda há tentativas restantes
    if (isRetryableError(error, null) && attempt < RETRY_CONFIG.maxRetries) {
      const delay = calculateDelay(attempt);
      console.log(`Erro de rede no modelo ${model.name}. Aguardando ${delay}ms...`);
      await sleep(delay);
      return tryModel(model, message, apiKey, attempt + 1);
    }

    // Re-throw o erro para ser tratado no nível superior
    throw error;
  }
};

export const geminiService = {
  async chat(message) {
    let lastError = null;
    let modelsAttempted = [];
    const apiKey = await getApiKey();

    // Tentar cada modelo em ordem de prioridade
    for (let i = 0; i < GEMINI_MODELS.length; i++) {
      const model = GEMINI_MODELS[i];
      modelsAttempted.push(model.name);

      try {
        console.log(`🚀 Tentando modelo ${i + 1}/${GEMINI_MODELS.length}: ${model.name}`);
        const result = await tryModel(model, message, apiKey);
        
        // Adicionar informação sobre qual modelo foi usado (apenas no console)
        console.log(`✅ Resposta obtida com sucesso usando: ${result.modelUsed}`);
        
        return result.text;
        
      } catch (error) {
        lastError = error;
        console.error(`❌ Modelo ${model.name} falhou:`, error.message);
        
        // Se não é o último modelo, tentar o próximo
        if (i < GEMINI_MODELS.length - 1) {
          console.log(`🔄 Tentando próximo modelo: ${GEMINI_MODELS[i + 1].name}`);
          continue;
        }
      }
    }

    // Se chegou aqui, todos os modelos falharam
    console.error('❌ Todos os modelos falharam. Modelos tentados:', modelsAttempted);
    console.error('Último erro:', lastError);
    
    // Retornar erro baseado no último erro encontrado
    if (lastError && lastError.message && lastError.message.includes('Failed to fetch')) {
      throw new Error('Não foi possível conectar aos serviços de IA. Verifique sua conexão com a internet.');
    }
    
    if (lastError && lastError.message && (lastError.message.includes('503') || lastError.message.includes('sobrecarregado'))) {
      throw new Error('Todos os serviços de IA estão temporariamente sobrecarregados. Tente novamente em alguns minutos.');
    }
    
    if (lastError && lastError.message && lastError.message.includes('429')) {
      throw new Error('Limite de requisições atingido. Aguarde alguns minutos antes de tentar novamente.');
    }
    
    throw new Error('Todos os serviços de IA estão temporariamente indisponíveis. Tente novamente mais tarde.');
  }
}; 