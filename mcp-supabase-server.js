#!/usr/bin/env node

const { Server } = require('@modelcontextprotocol/sdk/server/index.js')
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js')
const { CallToolRequestSchema, ListToolsRequestSchema } = require('@modelcontextprotocol/sdk/types.js')
const { createClient } = require('@supabase/supabase-js')

// Configuração do Supabase
const supabaseUrl = 'https://ruagsbbczuwgfflgcaol.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1YWdzYmJjenV3Z2ZmbGdjYW9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ0Njg5MDQsImV4cCI6MjA2MDA0NDkwNH0.S2KD6-9DpBYAOsodjibI7LGa04CspZZ5OdRQagNjoK8'

const supabase = createClient(supabaseUrl, supabaseAnonKey)

class SupabaseMCPServer {
    constructor() {
        this.server = new Server(
            {
                name: 'supabase-comprar-bem',
                version: '1.0.0',
            },
            {
                capabilities: {
                    tools: {},
                },
            }
        )

        this.setupToolHandlers()
    }

    setupToolHandlers() {
        this.server.setRequestHandler(ListToolsRequestSchema, async () => {
            return {
                tools: [
                    {
                        name: 'list_tables',
                        description: 'Lista todas as tabelas do banco de dados',
                        inputSchema: {
                            type: 'object',
                            properties: {},
                        },
                    },
                    {
                        name: 'describe_table',
                        description: 'Descreve a estrutura de uma tabela específica',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                table_name: {
                                    type: 'string',
                                    description: 'Nome da tabela',
                                },
                            },
                            required: ['table_name'],
                        },
                    },
                    {
                        name: 'query_table',
                        description: 'Executa uma consulta SELECT em uma tabela',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                table_name: {
                                    type: 'string',
                                    description: 'Nome da tabela',
                                },
                                columns: {
                                    type: 'string',
                                    description: 'Colunas a selecionar (default: *)',
                                    default: '*',
                                },
                                limit: {
                                    type: 'number',
                                    description: 'Limite de registros (default: 10)',
                                    default: 10,
                                },
                                where: {
                                    type: 'string',
                                    description: 'Condição WHERE (opcional)',
                                },
                            },
                            required: ['table_name'],
                        },
                    },
                    {
                        name: 'count_records',
                        description: 'Conta registros em uma tabela',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                table_name: {
                                    type: 'string',
                                    description: 'Nome da tabela',
                                },
                            },
                            required: ['table_name'],
                        },
                    },
                    {
                        name: 'run_sql',
                        description: 'Executa SQL personalizado (apenas SELECT)',
                        inputSchema: {
                            type: 'object',
                            properties: {
                                sql: {
                                    type: 'string',
                                    description: 'Comando SQL SELECT',
                                },
                            },
                            required: ['sql'],
                        },
                    },
                ],
            }
        })

        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            const { name, arguments: args } = request.params

            try {
                switch (name) {
                    case 'list_tables':
                        return await this.listTables()
                    case 'describe_table':
                        return await this.describeTable(args.table_name)
                    case 'query_table':
                        return await this.queryTable(args)
                    case 'count_records':
                        return await this.countRecords(args.table_name)
                    case 'run_sql':
                        return await this.runSQL(args.sql)
                    default:
                        throw new Error(`Ferramenta desconhecida: ${name}`)
                }
            } catch (error) {
                return {
                    content: [
                        {
                            type: 'text',
                            text: `Erro: ${error.message}`,
                        },
                    ],
                }
            }
        })
    }

    async listTables() {
        const { data, error } = await supabase.rpc('get_table_names')
        
        if (error) {
            // Fallback: tentar método alternativo
            const tables = [
                'usuarios_rdm', 'emails_enviados', 'tenants', 'rdm_feedbacks',
                'usuarios_rdm_produtos', 'lembretes_enviados', 'configuracoes_sistema'
            ]
            
            const results = []
            for (const table of tables) {
                try {
                    const { error: testError } = await supabase
                        .from(table)
                        .select('*')
                        .limit(1)
                    
                    if (!testError) {
                        results.push(table)
                    }
                } catch (e) {
                    // Tabela não existe
                }
            }
            
            return {
                content: [
                    {
                        type: 'text',
                        text: `Tabelas encontradas:\n${results.join('\n')}`,
                    },
                ],
            }
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `Tabelas do banco:\n${data.map(t => t.table_name).join('\n')}`,
                },
            ],
        }
    }

    async describeTable(tableName) {
        const { data, error } = await supabase
            .from(tableName)
            .select('*')
            .limit(1)

        if (error) {
            throw new Error(`Erro ao acessar tabela ${tableName}: ${error.message}`)
        }

        if (data.length === 0) {
            return {
                content: [
                    {
                        type: 'text',
                        text: `Tabela ${tableName} existe mas está vazia`,
                    },
                ],
            }
        }

        const columns = Object.keys(data[0])
        const sample = data[0]

        let description = `Estrutura da tabela ${tableName}:\n\n`
        description += `Colunas (${columns.length}):\n`
        
        columns.forEach(col => {
            const value = sample[col]
            const type = typeof value
            description += `  • ${col}: ${type} ${value !== null ? `(exemplo: ${value})` : '(null)'}\n`
        })

        return {
            content: [
                {
                    type: 'text',
                    text: description,
                },
            ],
        }
    }

    async queryTable(args) {
        const { table_name, columns = '*', limit = 10, where } = args
        
        let query = supabase
            .from(table_name)
            .select(columns)
            .limit(limit)

        if (where) {
            // Implementar condições WHERE básicas
            query = query.filter(where)
        }

        const { data, error } = await query

        if (error) {
            throw new Error(`Erro na consulta: ${error.message}`)
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `Resultados da tabela ${table_name}:\n${JSON.stringify(data, null, 2)}`,
                },
            ],
        }
    }

    async countRecords(tableName) {
        const { count, error } = await supabase
            .from(tableName)
            .select('*', { count: 'exact', head: true })

        if (error) {
            throw new Error(`Erro ao contar registros: ${error.message}`)
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `Tabela ${tableName} tem ${count} registros`,
                },
            ],
        }
    }

    async runSQL(sql) {
        // Por segurança, apenas comandos SELECT
        if (!sql.trim().toLowerCase().startsWith('select')) {
            throw new Error('Apenas comandos SELECT são permitidos')
        }

        const { data, error } = await supabase.rpc('run_sql', { sql_query: sql })

        if (error) {
            throw new Error(`Erro no SQL: ${error.message}`)
        }

        return {
            content: [
                {
                    type: 'text',
                    text: `Resultado SQL:\n${JSON.stringify(data, null, 2)}`,
                },
            ],
        }
    }

    async run() {
        const transport = new StdioServerTransport()
        await this.server.connect(transport)
        console.error('🚀 Servidor MCP Supabase iniciado!')
    }
}

const server = new SupabaseMCPServer()
server.run().catch(console.error)