// Configuração do CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

async function handleRequest(request) {
  // Lidar com requisições OPTIONS (pre-flight)
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      headers: corsHeaders
    });
  }

  // Configurar a URL da API do Gemini (versão correta)
  const apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Fazer a requisição para a API do Gemini
  const response = await fetch(apiUrl + '?key=' + GEMINI_API_KEY, {
    method: request.method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: request.body
  });

  // Criar uma nova resposta com os headers CORS
  const responseData = await response.json();
  return new Response(JSON.stringify(responseData), {
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json'
    }
  });
}

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
}); 