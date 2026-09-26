// Serviço especializado para pesquisas técnicas de produtos
import { GoogleGenerativeAI } from '@google/generative-ai';
import { supabase } from './supabase';

let cachedModel = null;

const getModel = async () => {
  if (cachedModel) return cachedModel;

  const { data, error } = await supabase
    .from('configuracoes_api')
    .select('valor')
    .eq('chave', 'gemini_api_key')
    .single();

  if (error || !data) {
    throw new Error('Não foi possível obter a chave da API do Gemini');
  }

  const genAI = new GoogleGenerativeAI(data.valor);
  cachedModel = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  return cachedModel;
};

class PesquisaService {

  // Categorias de busca disponíveis
  getCategoriasBusca() {
    return [
      {
        id: 'manuais',
        nome: 'Manuais do Fabricante',
        descricao: 'Manuais técnicos e de instruções do fabricante',
        fontes: ['Sites oficiais dos fabricantes', 'Portais técnicos', 'Documentação oficial']
      },
      {
        id: 'laudos',
        nome: 'Laudos e Testes',
        descricao: 'Laudos técnicos e resultados de testes de funcionalidade',
        fontes: ['Laboratórios certificados', 'Institutos de pesquisa', 'Órgãos reguladores']
      },
      {
        id: 'normas',
        nome: 'Normas Técnicas',
        descricao: 'Normas ABNT, NR e outras regulamentações técnicas',
        fontes: ['ABNT', 'Ministério do Trabalho', 'Órgãos reguladores setoriais']
      },
      {
        id: 'anvisa',
        nome: 'Informações ANVISA',
        descricao: 'Registros, alertas e informações da ANVISA',
        fontes: ['Portal ANVISA', 'Sistema de notificações', 'Boletins técnicos']
      },
      {
        id: 'vigilancia',
        nome: 'Vigilância Sanitária',
        descricao: 'Informações de vigilâncias sanitárias estaduais e municipais',
        fontes: ['Órgãos estaduais', 'Vigilâncias municipais', 'Sistemas de notificação']
      },
      {
        id: 'reclamacoes',
        nome: 'Reclamações de Usuários',
        descricao: 'Reclamações e avaliações de usuários sobre produtos',
        fontes: ['Reclame Aqui', 'Procon', 'Fóruns especializados']
      },
      {
        id: 'recalls',
        nome: 'Recalls e Alertas',
        descricao: 'Recalls de produtos e alertas de segurança',
        fontes: ['Portal do Consumidor', 'INMETRO', 'Fabricantes']
      },
      {
        id: 'certificacoes',
        nome: 'Certificações',
        descricao: 'Certificações de qualidade e conformidade',
        fontes: ['INMETRO', 'Organismos certificadores', 'ISO']
      }
    ];
  }

  // Gerar prompt especializado para cada tipo de busca
  gerarPromptEspecializado(categoria, produto, marca, especificacoes) {
    const prompts = {
      manuais: `
        Você é um especialista em pesquisa técnica de produtos. Preciso encontrar informações sobre manuais do fabricante para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, forneça informações detalhadas sobre:
        1. Onde encontrar o manual oficial do fabricante
        2. Especificações técnicas principais
        3. Instruções de uso e instalação
        4. Requisitos de manutenção
        5. Garantias e condições de uso
        
        Seja específico e cite fontes confiáveis quando possível.
      `,
      
      laudos: `
        Você é um especialista em análise técnica de produtos. Preciso encontrar informações sobre laudos e testes para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, forneça informações sobre:
        1. Laudos técnicos disponíveis
        2. Testes de funcionalidade realizados
        3. Certificações de qualidade
        4. Resultados de desempenho
        5. Laboratórios que realizaram os testes
        
        Priorize informações de fontes oficiais e laboratórios certificados.
      `,
      
      normas: `
        Você é um especialista em normas técnicas. Preciso encontrar informações sobre regulamentações para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, identifique:
        1. Normas ABNT aplicáveis
        2. Normas Regulamentadoras (NR) relevantes
        3. Outras regulamentações técnicas
        4. Requisitos de conformidade
        5. Certificações obrigatórias
        
        Cite os números das normas e órgãos responsáveis.
      `,
      
      anvisa: `
        Você é um especialista em regulamentações sanitárias. Preciso encontrar informações da ANVISA sobre:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, pesquise:
        1. Registro na ANVISA (se aplicável)
        2. Alertas ou notificações
        3. Restrições de uso
        4. Classificação de risco
        5. Histórico de irregularidades
        
        Foque em informações oficiais do portal da ANVISA.
      `,
      
      vigilancia: `
        Você é um especialista em vigilância sanitária. Preciso encontrar informações sobre:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, pesquise em vigilâncias sanitárias:
        1. Notificações estaduais
        2. Alertas municipais
        3. Interdições ou apreensões
        4. Irregularidades encontradas
        5. Medidas cautelares
        
        Inclua informações de diferentes estados quando relevante.
      `,
      
      reclamacoes: `
        Você é um especialista em análise de satisfação do consumidor. Preciso encontrar informações sobre reclamações para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, analise:
        1. Principais reclamações dos usuários
        2. Problemas mais frequentes
        3. Avaliações e notas
        4. Resoluções de problemas
        5. Tendências de satisfação
        
        Use fontes como Reclame Aqui, Procon e fóruns especializados.
      `,
      
      recalls: `
        Você é um especialista em segurança de produtos. Preciso encontrar informações sobre recalls para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, pesquise:
        1. Recalls oficiais
        2. Alertas de segurança
        3. Defeitos identificados
        4. Medidas corretivas
        5. Cronograma de correções
        
        Priorize informações do Portal do Consumidor e INMETRO.
      `,
      
      certificacoes: `
        Você é um especialista em certificações de qualidade. Preciso encontrar informações sobre certificações para:
        
        Produto: ${produto}
        Marca: ${marca}
        Especificações: ${especificacoes}
        
        Por favor, identifique:
        1. Certificações de qualidade
        2. Selos de conformidade
        3. Organismos certificadores
        4. Validade das certificações
        5. Processos de certificação
        
        Foque em certificações oficiais e reconhecidas.
      `
    };
    
    return prompts[categoria] || prompts.manuais;
  }

  // Realizar busca especializada
  async buscarInformacoesTecnicas(categoria, produto, marca, especificacoes = '') {
    try {
      console.log(`🔍 PesquisaService: Iniciando busca para categoria ${categoria}`);
      
      const prompt = this.gerarPromptEspecializado(categoria, produto, marca, especificacoes);
      
      console.log(`📝 PesquisaService: Prompt gerado para ${categoria}:`, prompt.substring(0, 200) + '...');
      
      console.log(`🤖 PesquisaService: Enviando para Gemini API...`);

      const model = await getModel();
      const result = await model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();
      
      console.log(`✅ PesquisaService: Resposta recebida para ${categoria}:`, text.substring(0, 200) + '...');
      
      return {
        success: true,
        categoria,
        produto,
        marca,
        resultado: text,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error(`❌ PesquisaService: Erro na busca técnica para ${categoria}:`, error);
      return {
        success: false,
        error: error.message,
        categoria,
        produto,
        marca
      };
    }
  }

  // Buscar múltiplas categorias simultaneamente
  async buscarMultiplasCategorias(categorias, produto, marca, especificacoes = '') {
    const promisses = categorias.map(categoria => 
      this.buscarInformacoesTecnicas(categoria, produto, marca, especificacoes)
    );
    
    try {
      const resultados = await Promise.all(promisses);
      return {
        success: true,
        produto,
        marca,
        resultados: resultados.filter(r => r.success),
        erros: resultados.filter(r => !r.success)
      };
    } catch (error) {
      console.error('Erro na busca múltipla:', error);
      return {
        success: false,
        error: error.message,
        produto,
        marca
      };
    }
  }

  // Gerar relatório consolidado
  async gerarRelatorioConsolidado(produto, marca, especificacoes = '') {
    const todasCategorias = this.getCategoriasBusca().map(cat => cat.id);
    
    const resultado = await this.buscarMultiplasCategorias(
      todasCategorias, 
      produto, 
      marca, 
      especificacoes
    );
    
    if (resultado.success) {
      // Gerar prompt para consolidação
      const promptConsolidacao = `
        Você é um especialista em análise técnica de produtos. Com base nas informações coletadas sobre o produto "${produto}" da marca "${marca}", gere um relatório consolidado que inclua:
        
        1. RESUMO EXECUTIVO
        2. ESPECIFICAÇÕES TÉCNICAS
        3. CONFORMIDADE REGULATÓRIA
        4. QUALIDADE E CERTIFICAÇÕES
        5. HISTÓRICO DE PROBLEMAS
        6. RECOMENDAÇÕES
        
        Informações coletadas:
        ${resultado.resultados.map(r => `\n=== ${r.categoria.toUpperCase()} ===\n${r.resultado}`).join('\n')}
        
        Organize as informações de forma clara e profissional, destacando pontos importantes para a pré-qualificação de bens.
      `;
      
      try {
        const model = await getModel();
        const consolidacao = await model.generateContent(promptConsolidacao);
        const response = await consolidacao.response;
        const relatorio = response.text();
        
        return {
          success: true,
          produto,
          marca,
          relatorio,
          detalhes: resultado.resultados,
          timestamp: new Date().toISOString()
        };
      } catch (error) {
        return {
          success: true,
          produto,
          marca,
          relatorio: 'Erro ao gerar relatório consolidado',
          detalhes: resultado.resultados,
          timestamp: new Date().toISOString()
        };
      }
    }
    
    return resultado;
  }
}

export default new PesquisaService(); 