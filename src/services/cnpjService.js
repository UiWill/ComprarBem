// Serviço para validação de CNPJ usando API pública
const CNPJ_API_URL = 'https://publica.cnpj.ws/cnpj'

export async function validarCNPJ(cnpj) {
  try {
    // Remove caracteres não numéricos
    const cnpjLimpo = cnpj.replace(/[^\d]/g, '')
    
    if (cnpjLimpo.length !== 14) {
      return {
        valido: false,
        mensagem: 'CNPJ deve ter 14 dígitos'
      }
    }

    // Faz a requisição para a API
    const response = await fetch(`${CNPJ_API_URL}/${cnpjLimpo}`)
    
    if (!response.ok) {
      if (response.status === 404) {
        return {
          valido: false,
          mensagem: 'CNPJ não encontrado na base de dados'
        }
      }
      throw new Error('Erro ao consultar CNPJ')
    }

    const data = await response.json()
    
    return {
      valido: true,
      mensagem: 'CNPJ válido',
      dados: {
        razaoSocial: data.razao_social,
        nomeFantasia: data.estabelecimento?.nome_fantasia || '',
        situacao: data.estabelecimento?.situacao_cadastral || ''
      }
    }
  } catch (error) {
    console.error('Erro ao validar CNPJ:', error)
    return {
      valido: false,
      mensagem: 'Erro ao validar CNPJ. Tente novamente mais tarde.'
    }
  }
} 