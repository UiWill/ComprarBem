const GEMINI_API_KEY = 'AIzaSyAf-Oe56q4Rao0OodEOtnEjtI_FpOmDg6I';
const IS_DEVELOPMENT = process.env.NODE_ENV === 'development';
const PROXY_URL = IS_DEVELOPMENT 
  ? 'https://cors-anywhere.herokuapp.com/'
  : 'https://seu-worker.seu-nome.workers.dev/';
// Usando o modelo correto que está disponível na v1beta
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

export const geminiService = {
  async chat(message) {
    try {
      const apiUrl = IS_DEVELOPMENT 
        ? `${PROXY_URL}${GEMINI_API_URL}?key=${GEMINI_API_KEY}`
        : PROXY_URL;

      console.log('Enviando requisição para:', apiUrl);

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

      // Log da resposta bruta para debug
      const responseText = await response.text();
      console.log('Resposta bruta:', responseText);

      let data;
      try {
        data = JSON.parse(responseText);
      } catch (e) {
        console.error('Erro ao fazer parse da resposta:', e);
        console.error('Resposta que causou erro:', responseText);
        throw new Error('Resposta inválida do servidor');
      }

      if (!response.ok) {
        console.error('Erro detalhado da API:', data);
        throw new Error(data.error?.message || 'Erro na comunicação com o servidor');
      }

      if (!data.candidates || !data.candidates[0]?.content?.parts?.[0]?.text) {
        console.error('Resposta sem o formato esperado:', data);
        throw new Error('Resposta inválida do servidor');
      }

      return data.candidates[0].content.parts[0].text;
    } catch (error) {
      console.error('Erro ao chamar o serviço:', error);
      if (error.message.includes('Failed to fetch')) {
        throw new Error('Não foi possível conectar ao servidor. Verifique sua conexão com a internet.');
      }
      throw new Error('Não foi possível processar sua solicitação no momento. Por favor, tente novamente mais tarde.');
    }
  }
}; 