// ===================================================
// Implementação Completa da Função criarNovaAta
// Sistema Comprar Bem - Funcionalidade CCL
// ===================================================

async criarNovaAta() {
  try {
    // 1. Buscar produtos julgados pendentes de inclusão em ata
    const { data: produtosJulgados, error: errorProdutos } = await supabase
      .from('produtos')
      .select(`
        id,
        nome,
        marca,
        modelo,
        fabricante,
        categoria_id,
        status,
        julgado_em,
        adequacao_tecnica,
        observacoes_ccl,
        base_legal
      `)
      .eq('tenant_id', this.currentTenantId)
      .in('status', ['julgado_aprovado', 'julgado_reprovado'])
      .not('julgado_em', 'is', null) // Só produtos que foram efetivamente julgados
      .is('ata_julgamento_id', null) // Só produtos que ainda não estão em uma ata

    if (errorProdutos) throw errorProdutos

    // 2. Verificar se há produtos para incluir na ata
    if (!produtosJulgados || produtosJulgados.length === 0) {
      this.$swal({
        title: '⚠️ Nenhum Produto Disponível',
        text: 'Não há produtos julgados disponíveis para incluir em uma nova ata. Realize julgamentos primeiro.',
        icon: 'warning'
      })
      return
    }

    // 3. Mostrar prévia dos produtos e formulário de criação da ata
    const produtosList = produtosJulgados.map(produto => `
      <tr style="border-bottom: 1px solid #eee;">
        <td style="padding: 8px;">${produto.nome}</td>
        <td style="padding: 8px;">${produto.marca}</td>
        <td style="padding: 8px;">
          <span class="status-badge ${produto.status === 'julgado_aprovado' ? 'status-aprovado' : 'status-reprovado'}">
            ${produto.status === 'julgado_aprovado' ? 'Aprovado' : 'Reprovado'}
          </span>
        </td>
        <td style="padding: 8px;">${this.formatDate(produto.julgado_em)}</td>
      </tr>
    `).join('')

    const result = await this.$swal({
      title: '📋 Criar Nova Ata de Julgamento',
      html: `
        <div style="text-align: left; padding: 15px;">
          <!-- Formulário da Ata -->
          <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;">
            <h4 style="margin: 0 0 15px 0; color: #495057;">📄 Dados da Ata</h4>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Período de Referência:</label>
              <input id="periodoAta" class="swal2-input" type="text" placeholder="Ex: Janeiro 2025" value="${new Date().toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' })}">
            </div>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Número da Ata:</label>
              <input id="numeroAta" class="swal2-input" type="text" placeholder="Ex: ATA-CCL-008/2025" value="ATA-CCL-${String(Math.floor(Math.random() * 900) + 100)}/${new Date().getFullYear()}">
            </div>
            <div style="margin-bottom: 15px;">
              <label style="display: block; font-weight: bold; margin-bottom: 5px;">Descrição:</label>
              <textarea id="descricaoAta" class="swal2-textarea" placeholder="Descrição da ata de julgamento..." rows="3">Ata de julgamento da Comissão de Contratação ou Licitação referente aos processos de pré-qualificação de bens do período.</textarea>
            </div>
          </div>

          <!-- Lista de Produtos -->
          <div style="background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px;">
            <h4 style="margin: 0 0 15px 0; color: #495057;">📦 Produtos a serem incluídos (${produtosJulgados.length})</h4>
            <div style="max-height: 300px; overflow-y: auto;">
              <table style="width: 100%; font-size: 12px;">
                <thead>
                  <tr style="background: #f8f9fa;">
                    <th style="padding: 8px; text-align: left;">Produto</th>
                    <th style="padding: 8px; text-align: left;">Marca</th>
                    <th style="padding: 8px; text-align: left;">Decisão</th>
                    <th style="padding: 8px; text-align: left;">Data Julgamento</th>
                  </tr>
                </thead>
                <tbody>
                  ${produtosList}
                </tbody>
              </table>
            </div>
          </div>

          <div style="background: #d1ecf1; padding: 10px; border-radius: 4px; margin-top: 15px;">
            <small><strong>📝 Próximos passos:</strong> Após criar a ata, ela estará disponível na aba "Atas de Julgamento" para elaboração do conteúdo e publicação oficial.</small>
          </div>
        </div>
      `,
      width: '900px',
      showCancelButton: true,
      confirmButtonText: '✅ Criar Ata com ' + produtosJulgados.length + ' Produtos',
      cancelButtonText: '❌ Cancelar',
      confirmButtonColor: '#28a745',
      preConfirm: () => {
        const periodo = document.getElementById('periodoAta').value.trim()
        const numero = document.getElementById('numeroAta').value.trim()
        const descricao = document.getElementById('descricaoAta').value.trim()
        
        if (!periodo || !numero) {
          this.$swal.showValidationMessage('Preencha o período e número da ata')
          return false
        }
        
        return { periodo, numero, descricao }
      }
    })

    if (!result.isConfirmed) return

    // 4. Criar a ata no banco de dados
    const ataData = {
      tenant_id: this.currentTenantId,
      numero: result.value.numero,
      periodo: result.value.periodo,
      descricao: result.value.descricao,
      total_processos: produtosJulgados.length,
      status_ata: 'EM PRAZO', // Status padrão existente na tabela
      data_inicio_elaboracao: new Date().toISOString(),
      responsavel_elaboracao: this.usuarioNome || 'CCL',
      progresso_elaboracao: 0,
      conteudo_ata: this.gerarConteudoAtaInicial(produtosJulgados, result.value),
      criado_em: new Date().toISOString(),
      atualizado_em: new Date().toISOString()
    }

    const { data: novaAta, error: errorAta } = await supabase
      .from('atas_julgamento')
      .insert([ataData])
      .select()

    if (errorAta) throw errorAta

    // 5. Vincular produtos à ata criada
    const ataId = novaAta[0].id
    const { error: errorVinculo } = await supabase
      .from('produtos')
      .update({ 
        ata_julgamento_id: ataId,
        atualizado_em: new Date().toISOString()
      })
      .in('id', produtosJulgados.map(p => p.id))

    if (errorVinculo) throw errorVinculo

    // 6. Recarregar dados da interface
    await this.carregarAtasJulgamento()
    await this.carregarAtasEmElaboracao()
    await this.carregarDados() // Recarregar contadores

    // 7. Mostrar sucesso
    this.$swal({
      title: '✅ Ata Criada com Sucesso!',
      html: `
        <div style="text-align: center; padding: 20px;">
          <h4>${result.value.numero}</h4>
          <p><strong>Período:</strong> ${result.value.periodo}</p>
          <p><strong>Produtos incluídos:</strong> ${produtosJulgados.length}</p>
          <hr>
          <p>A ata está disponível na aba "Atas de Julgamento" para elaboração e publicação.</p>
        </div>
      `,
      icon: 'success',
      confirmButtonText: '📋 Ver Atas de Julgamento',
      showCancelButton: true,
      cancelButtonText: '✅ OK'
    }).then((result) => {
      if (result.isConfirmed) {
        // Ir para a aba de atas
        this.activeTab = 'atas'
      }
    })

  } catch (error) {
    console.error('Erro ao criar nova ata:', error)
    this.$swal({
      title: '❌ Erro ao Criar Ata',
      text: `Erro: ${error.message}`,
      icon: 'error'
    })
  }
},

// Função auxiliar para gerar conteúdo inicial da ata
gerarConteudoAtaInicial(produtos, dadosAta) {
  const produtosAprovados = produtos.filter(p => p.status === 'julgado_aprovado')
  const produtosReprovados = produtos.filter(p => p.status === 'julgado_reprovado')
  
  return `
ATA DE JULGAMENTO DA COMISSÃO DE CONTRATAÇÃO OU LICITAÇÃO (CCL)

Número: ${dadosAta.numero}
Período: ${dadosAta.periodo}
Data de Elaboração: ${new Date().toLocaleDateString('pt-BR')}

RESUMO:
- Total de processos julgados: ${produtos.length}
- Produtos aprovados: ${produtosAprovados.length}
- Produtos reprovados: ${produtosReprovados.length}

PRODUTOS APROVADOS:
${produtosAprovados.map((produto, index) => `
${index + 1}. ${produto.nome} - ${produto.marca}
   Adequação Técnica: ${produto.adequacao_tecnica}
   Base Legal: ${produto.base_legal || 'Lei 14.133/2021'}
`).join('')}

PRODUTOS REPROVADOS:
${produtosReprovados.map((produto, index) => `
${index + 1}. ${produto.nome} - ${produto.marca}
   Motivo: ${produto.observacoes_ccl || 'Não atendimento aos requisitos técnicos'}
`).join('')}

[CONTEÚDO A SER COMPLETADO NA ELABORAÇÃO FINAL]
  `.trim()
}