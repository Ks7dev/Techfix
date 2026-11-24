-- =============================================================================
-- TechFix — Banco Upgrade — script completo  (SQLite >= 3.38)
-- Script COMPLETO: limpeza + estrutura + regras + auditoria + views + dados.
-- Reúne, nesta ordem, 01_estrutura.sql, 02_regras.sql, 03_auditoria.sql,
-- 04_views.sql e 05_dados.sql. Para alterar o banco, edite os arquivos de
-- origem e regere este script.
--
-- COMO EXECUTAR (o script roda sozinho e pode ser executado varias vezes:
-- o bloco de limpeza abaixo apaga o que ja existir):
--   * DB Browser for SQLite: Arquivo > Novo banco de dados (ou abra um vazio),
--     aba "Executar SQL" > "Abrir arquivo SQL" > techfix_upgrade_completo.sql >
--     "Executar tudo" (Ctrl+Return) > "Gravar alteracoes" (Ctrl+S).
--   * SQLiteStudio: crie/abra um banco > Ferramentas > Abrir editor SQL >
--     abra este arquivo > Executar (F9).
--   * sqlite3 (linha de comando):
--       sqlite3 techfix_upgrade.sqlite < techfix_upgrade_completo.sql
--
-- PRAGMAs RECOMENDADOS A CADA CONEXAO (sao por conexao, exceto journal_mode):
--   PRAGMA foreign_keys = ON;        -- obrigatorio: integridade referencial
--   PRAGMA journal_mode = WAL;       -- leitores nao bloqueiam o escritor
--   PRAGMA busy_timeout = 5000;      -- espera 5 s por lock em vez de falhar
--   PRAGMA recursive_triggers = OFF; -- o projeto depende desse padrao
--
-- Senhas: os senha_hash do seed sao PLACEHOLDERS - troque antes de usar de verdade.
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA recursive_triggers = OFF;

-- ---------------------------------------------------------------------------
-- LIMPEZA: permite reexecutar o script (views > triggers > indices > tabelas,
-- tabelas na ordem inversa de criacao para respeitar as FKs)
-- ---------------------------------------------------------------------------
PRAGMA foreign_keys = OFF;
DROP VIEW IF EXISTS vw_auditoria;
DROP VIEW IF EXISTS vw_garantias_ativas;
DROP VIEW IF EXISTS vw_produtividade_tecnico;
DROP VIEW IF EXISTS vw_faturamento_mensal;
DROP VIEW IF EXISTS vw_kardex;
DROP VIEW IF EXISTS vw_estoque_reposicao;
DROP VIEW IF EXISTS vw_os_extrato;
DROP VIEW IF EXISTS vw_os_painel;
DROP TRIGGER IF EXISTS trg_auditoria_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_os_pagamento_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_forma_pagamento_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_movimento_estoque_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_os_peca_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_os_servico_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_os_orcamento_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_os_historico_status_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_ordem_servico_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_status_transicao_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_status_os_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_compra_item_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_compra_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_fornecedor_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_historico_preco_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_peca_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_servico_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_categoria_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_equipamento_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_modelo_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_tipo_equipamento_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_marca_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_cliente_endereco_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_cliente_contato_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_cliente_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_usuario_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_funcionario_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_permissao_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_cargo_bd_bloqueia;
DROP TRIGGER IF EXISTS trg_historico_preco_bu_imutavel;
DROP TRIGGER IF EXISTS trg_auditoria_bu_imutavel;
DROP TRIGGER IF EXISTS trg_forma_pagamento_au_auditoria;
DROP TRIGGER IF EXISTS trg_forma_pagamento_ai_auditoria;
DROP TRIGGER IF EXISTS trg_os_pagamento_au_auditoria;
DROP TRIGGER IF EXISTS trg_os_pagamento_ai_auditoria;
DROP TRIGGER IF EXISTS trg_ordem_servico_au_auditoria;
DROP TRIGGER IF EXISTS trg_ordem_servico_ai_auditoria;
DROP TRIGGER IF EXISTS trg_peca_au_auditoria;
DROP TRIGGER IF EXISTS trg_peca_ai_auditoria;
DROP TRIGGER IF EXISTS trg_servico_au_auditoria;
DROP TRIGGER IF EXISTS trg_servico_ai_auditoria;
DROP TRIGGER IF EXISTS trg_equipamento_au_auditoria;
DROP TRIGGER IF EXISTS trg_equipamento_ai_auditoria;
DROP TRIGGER IF EXISTS trg_cliente_au_auditoria;
DROP TRIGGER IF EXISTS trg_cliente_ai_auditoria;
DROP TRIGGER IF EXISTS trg_usuario_au_auditoria;
DROP TRIGGER IF EXISTS trg_usuario_ai_auditoria;
DROP TRIGGER IF EXISTS trg_funcionario_au_auditoria;
DROP TRIGGER IF EXISTS trg_funcionario_ai_auditoria;
DROP TRIGGER IF EXISTS trg_servico_au_versao;
DROP TRIGGER IF EXISTS trg_peca_au_versao;
DROP TRIGGER IF EXISTS trg_ordem_servico_au_versao;
DROP TRIGGER IF EXISTS trg_equipamento_au_versao;
DROP TRIGGER IF EXISTS trg_cliente_au_versao;
DROP TRIGGER IF EXISTS trg_os_pagamento_bu_regras;
DROP TRIGGER IF EXISTS trg_os_pagamento_bi_regras;
DROP TRIGGER IF EXISTS trg_os_peca_au_estorno;
DROP TRIGGER IF EXISTS trg_os_peca_bu_regras;
DROP TRIGGER IF EXISTS trg_os_peca_ai_baixa;
DROP TRIGGER IF EXISTS trg_os_peca_bi_regras;
DROP TRIGGER IF EXISTS trg_os_servico_au_recalcula;
DROP TRIGGER IF EXISTS trg_os_servico_bu_regras;
DROP TRIGGER IF EXISTS trg_os_servico_ai_recalcula;
DROP TRIGGER IF EXISTS trg_os_servico_bi_regras;
DROP TRIGGER IF EXISTS trg_os_orcamento_bu_regras;
DROP TRIGGER IF EXISTS trg_os_orcamento_bi_regras;
DROP TRIGGER IF EXISTS trg_os_historico_status_bu_imutavel;
DROP TRIGGER IF EXISTS trg_os_historico_status_ai_aplica;
DROP TRIGGER IF EXISTS trg_os_historico_status_bi_regras;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_total_pago;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_subtotais;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_desconto;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_tecnico;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_fechamento;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_status;
DROP TRIGGER IF EXISTS trg_ordem_servico_bu_imutaveis;
DROP TRIGGER IF EXISTS trg_ordem_servico_ai_abertura;
DROP TRIGGER IF EXISTS trg_ordem_servico_bi_regras;
DROP TRIGGER IF EXISTS trg_movimento_estoque_bu_imutavel;
DROP TRIGGER IF EXISTS trg_movimento_estoque_ai_aplica;
DROP TRIGGER IF EXISTS trg_movimento_estoque_bi_regras;
DROP TRIGGER IF EXISTS trg_compra_item_bu_imutavel;
DROP TRIGGER IF EXISTS trg_compra_item_ai_entrada;
DROP TRIGGER IF EXISTS trg_compra_item_bi_regras;
DROP TRIGGER IF EXISTS trg_compra_bu_regras;
DROP TRIGGER IF EXISTS trg_compra_bi_regras;
DROP TRIGGER IF EXISTS trg_peca_au_historico_preco;
DROP TRIGGER IF EXISTS trg_peca_bu_estoque_somente_kardex;
DROP TRIGGER IF EXISTS trg_peca_bu_regras;
DROP TRIGGER IF EXISTS trg_peca_bi_regras;
DROP TRIGGER IF EXISTS trg_servico_au_historico_preco;
DROP TRIGGER IF EXISTS trg_servico_bu_regras;
DROP TRIGGER IF EXISTS trg_servico_bi_regras;
DROP TRIGGER IF EXISTS trg_equipamento_bu_imei;
DROP TRIGGER IF EXISTS trg_equipamento_bi_imei;
DROP TRIGGER IF EXISTS trg_equipamento_bu_permissao;
DROP TRIGGER IF EXISTS trg_equipamento_bi_permissao;
DROP TRIGGER IF EXISTS trg_cliente_endereco_bu_permissao;
DROP TRIGGER IF EXISTS trg_cliente_endereco_bi_permissao;
DROP TRIGGER IF EXISTS trg_cliente_contato_bu_permissao;
DROP TRIGGER IF EXISTS trg_cliente_contato_bi_permissao;
DROP TRIGGER IF EXISTS trg_cliente_bu_permissao;
DROP TRIGGER IF EXISTS trg_cliente_bi_permissao;
DROP TRIGGER IF EXISTS trg_usuario_bi_regras;
DROP TRIGGER IF EXISTS trg_funcionario_au_desativa_usuario;
DROP TRIGGER IF EXISTS trg_funcionario_bu_permissao;
DROP TRIGGER IF EXISTS trg_funcionario_bi_permissao;
DROP INDEX IF EXISTS idx_auditoria_funcionario;
DROP INDEX IF EXISTS idx_os_pagamento_func;
DROP INDEX IF EXISTS idx_os_pagamento_forma;
DROP INDEX IF EXISTS idx_os_pagamento_os;
DROP INDEX IF EXISTS idx_os_peca_tecnico;
DROP INDEX IF EXISTS idx_os_peca_peca;
DROP INDEX IF EXISTS idx_os_peca_os;
DROP INDEX IF EXISTS idx_os_servico_tecnico;
DROP INDEX IF EXISTS idx_os_servico_servico;
DROP INDEX IF EXISTS idx_os_servico_os;
DROP INDEX IF EXISTS idx_os_orcamento_criado;
DROP INDEX IF EXISTS idx_os_historico_novo;
DROP INDEX IF EXISTS idx_os_historico_anterior;
DROP INDEX IF EXISTS idx_os_historico_func;
DROP INDEX IF EXISTS idx_os_historico_os;
DROP INDEX IF EXISTS idx_os_atualizado_por;
DROP INDEX IF EXISTS idx_os_atendente;
DROP INDEX IF EXISTS idx_os_equipamento;
DROP INDEX IF EXISTS idx_os_cliente;
DROP INDEX IF EXISTS idx_status_transicao_dest;
DROP INDEX IF EXISTS idx_movimento_funcionario;
DROP INDEX IF EXISTS idx_movimento_os_peca;
DROP INDEX IF EXISTS idx_movimento_compra_item;
DROP INDEX IF EXISTS idx_compra_item_peca;
DROP INDEX IF EXISTS idx_compra_funcionario;
DROP INDEX IF EXISTS idx_historico_preco_func;
DROP INDEX IF EXISTS idx_historico_preco_item;
DROP INDEX IF EXISTS idx_peca_criado_por;
DROP INDEX IF EXISTS idx_peca_categoria;
DROP INDEX IF EXISTS idx_servico_criado_por;
DROP INDEX IF EXISTS idx_servico_categoria;
DROP INDEX IF EXISTS idx_categoria_pai;
DROP INDEX IF EXISTS idx_equipamento_criado_por;
DROP INDEX IF EXISTS idx_equipamento_modelo;
DROP INDEX IF EXISTS idx_equipamento_cliente;
DROP INDEX IF EXISTS idx_modelo_tipo;
DROP INDEX IF EXISTS idx_modelo_marca;
DROP INDEX IF EXISTS idx_cliente_endereco_criado;
DROP INDEX IF EXISTS idx_cliente_endereco_cliente;
DROP INDEX IF EXISTS idx_cliente_contato_criado;
DROP INDEX IF EXISTS idx_cliente_contato_cliente;
DROP INDEX IF EXISTS idx_cliente_atualizado_por;
DROP INDEX IF EXISTS idx_cliente_criado_por;
DROP INDEX IF EXISTS idx_funcionario_atualizado_por;
DROP INDEX IF EXISTS idx_funcionario_criado_por;
DROP INDEX IF EXISTS idx_funcionario_cargo;
DROP INDEX IF EXISTS idx_cargo_permissao_perm;
DROP INDEX IF EXISTS idx_cliente_nome;
DROP INDEX IF EXISTS idx_peca_estoque_ativa;
DROP INDEX IF EXISTS idx_os_pagamento_os_valido;
DROP INDEX IF EXISTS idx_auditoria_tabela_reg;
DROP INDEX IF EXISTS idx_movimento_peca_data;
DROP INDEX IF EXISTS idx_os_tecnico_status;
DROP INDEX IF EXISTS idx_os_status_abertura;
DROP INDEX IF EXISTS uq_categoria_raiz_nome;
DROP INDEX IF EXISTS uq_os_orcamento_vigente;
DROP INDEX IF EXISTS uq_cliente_endereco_principal;
DROP INDEX IF EXISTS uq_cliente_contato_principal;
DROP TABLE IF EXISTS schema_versao;
DROP TABLE IF EXISTS auditoria;
DROP TABLE IF EXISTS os_pagamento;
DROP TABLE IF EXISTS forma_pagamento;
DROP TABLE IF EXISTS movimento_estoque;
DROP TABLE IF EXISTS os_peca;
DROP TABLE IF EXISTS os_servico;
DROP TABLE IF EXISTS os_orcamento;
DROP TABLE IF EXISTS os_historico_status;
DROP TABLE IF EXISTS ordem_servico;
DROP TABLE IF EXISTS status_transicao;
DROP TABLE IF EXISTS status_os;
DROP TABLE IF EXISTS compra_item;
DROP TABLE IF EXISTS compra;
DROP TABLE IF EXISTS fornecedor;
DROP TABLE IF EXISTS historico_preco;
DROP TABLE IF EXISTS peca;
DROP TABLE IF EXISTS servico;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS equipamento;
DROP TABLE IF EXISTS modelo;
DROP TABLE IF EXISTS tipo_equipamento;
DROP TABLE IF EXISTS marca;
DROP TABLE IF EXISTS cliente_endereco;
DROP TABLE IF EXISTS cliente_contato;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS funcionario;
DROP TABLE IF EXISTS cargo_permissao;
DROP TABLE IF EXISTS permissao;
DROP TABLE IF EXISTS cargo;
PRAGMA foreign_keys = ON;

-- #############################################################################
-- SECAO 1. ESTRUTURA (tabelas e indices)   (origem: 01_estrutura.sql)
-- #############################################################################

-- =============================================================================
-- TechFix - Banco Upgrade (SQLite >= 3.38)
-- 01_estrutura.sql : tabelas (STRICT) e indices
-- Fonte de verdade: upgrade/docs/especificacao_upgrade.md
--
-- Convencoes: dinheiro em centavos (INTEGER), percentual em pontos-base,
-- datas ISO 'AAAA-MM-DD HH:MM:SS' / 'AAAA-MM-DD', booleano 0/1, exclusao logica.
-- PRAGMAs de conexao recomendados: foreign_keys=ON, journal_mode=WAL,
-- busy_timeout=5000, recursive_triggers=OFF.
--
-- Decisoes/desvios (ver tambem upgrade/README.md):
--  * funcionario ganhou criado_por/atualizado_por (opcionais) para permitir
--    verificar FUNCIONARIO_GERENCIAR; o primeiro funcionario (bootstrap) e livre.
--  * cliente_contato/cliente_endereco ganharam criado_por/atualizado_por
--    (RF02: CLIENTE_GERENCIAR do responsavel).
--  * ordem_servico.valor_total e coluna GERADA (STORED) =
--    subtotal_servicos + subtotal_pecas - desconto; assim o CHECK da
--    especificacao e sempre verdadeiro e UPDATE de desconto nao exige
--    reenviar valor_total.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 2.1 Acesso e pessoas
-- ---------------------------------------------------------------------------
CREATE TABLE cargo (
    id        INTEGER PRIMARY KEY,
    nome      TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(nome)) >= 3),
    descricao TEXT,
    ativo     INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
) STRICT;

CREATE TABLE permissao (
    id        INTEGER PRIMARY KEY,
    codigo    TEXT NOT NULL UNIQUE CHECK (codigo = upper(codigo) AND length(codigo) >= 3),
    descricao TEXT NOT NULL
) STRICT;

CREATE TABLE cargo_permissao (
    id_cargo     INTEGER NOT NULL REFERENCES cargo(id),
    id_permissao INTEGER NOT NULL REFERENCES permissao(id),
    PRIMARY KEY (id_cargo, id_permissao)
) STRICT, WITHOUT ROWID;

CREATE TABLE funcionario (
    id             INTEGER PRIMARY KEY,
    nome           TEXT    NOT NULL CHECK (length(trim(nome)) >= 3),
    cpf            TEXT    NOT NULL UNIQUE CHECK (length(cpf) = 11 AND cpf NOT GLOB '*[^0-9]*'),
    email          TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (email LIKE '%_@_%.__%'),
    telefone       TEXT    CHECK (telefone IS NULL OR (length(telefone) BETWEEN 10 AND 11 AND telefone NOT GLOB '*[^0-9]*')),
    id_cargo       INTEGER NOT NULL REFERENCES cargo(id),
    data_admissao  TEXT    NOT NULL CHECK (date(data_admissao) = data_admissao),
    data_demissao  TEXT    CHECK (data_demissao IS NULL OR (date(data_demissao) = data_demissao AND data_demissao >= data_admissao)),
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_em      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    criado_por     INTEGER REFERENCES funcionario(id),
    atualizado_por INTEGER REFERENCES funcionario(id),
    CHECK (ativo = 0 OR data_demissao IS NULL)
) STRICT;

CREATE TABLE usuario (
    id                INTEGER PRIMARY KEY,
    id_funcionario    INTEGER NOT NULL UNIQUE REFERENCES funcionario(id),
    login             TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (length(login) BETWEEN 4 AND 30),
    senha_hash        TEXT    NOT NULL CHECK (length(senha_hash) >= 60),  -- argon2/bcrypt gerado pela aplicacao
    tentativas_falhas INTEGER NOT NULL DEFAULT 0 CHECK (tentativas_falhas >= 0),
    bloqueado_ate     TEXT    CHECK (bloqueado_ate IS NULL OR datetime(bloqueado_ate) = bloqueado_ate),
    ultimo_login      TEXT    CHECK (ultimo_login IS NULL OR datetime(ultimo_login) = ultimo_login),
    ativo             INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.2 Clientes
-- ---------------------------------------------------------------------------
CREATE TABLE cliente (
    id                 INTEGER PRIMARY KEY,
    tipo_pessoa        TEXT    NOT NULL CHECK (tipo_pessoa IN ('PF','PJ')),
    nome               TEXT    NOT NULL CHECK (length(trim(nome)) >= 2),
    documento          TEXT    NOT NULL UNIQUE CHECK (documento NOT GLOB '*[^0-9]*'),
    data_nascimento    TEXT    CHECK (data_nascimento IS NULL OR date(data_nascimento) = data_nascimento),
    aceita_comunicacao INTEGER NOT NULL DEFAULT 0 CHECK (aceita_comunicacao IN (0,1)),  -- LGPD
    ativo              INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_em          TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    criado_por         INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_em      TEXT    CHECK (atualizado_em IS NULL OR datetime(atualizado_em) = atualizado_em),
    atualizado_por     INTEGER REFERENCES funcionario(id),
    versao             INTEGER NOT NULL DEFAULT 1 CHECK (versao >= 1),
    CHECK ((tipo_pessoa = 'PF' AND length(documento) = 11) OR (tipo_pessoa = 'PJ' AND length(documento) = 14))
) STRICT;

CREATE TABLE cliente_contato (
    id             INTEGER PRIMARY KEY,
    id_cliente     INTEGER NOT NULL REFERENCES cliente(id),
    tipo           TEXT    NOT NULL CHECK (tipo IN ('CELULAR','TELEFONE','EMAIL','WHATSAPP')),
    valor          TEXT    NOT NULL,
    principal      INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1)),
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_por     INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_por INTEGER REFERENCES funcionario(id),
    CHECK ((tipo = 'EMAIL' AND valor LIKE '%_@_%')
        OR (tipo <> 'EMAIL' AND length(valor) BETWEEN 10 AND 11 AND valor NOT GLOB '*[^0-9]*'))
) STRICT;

CREATE TABLE cliente_endereco (
    id             INTEGER PRIMARY KEY,
    id_cliente     INTEGER NOT NULL REFERENCES cliente(id),
    cep            TEXT    NOT NULL CHECK (length(cep) = 8 AND cep NOT GLOB '*[^0-9]*'),
    logradouro     TEXT    NOT NULL,
    numero         TEXT    NOT NULL,
    complemento    TEXT,
    bairro         TEXT    NOT NULL,
    cidade         TEXT    NOT NULL,
    uf             TEXT    NOT NULL CHECK (uf IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA','MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO')),
    principal      INTEGER NOT NULL DEFAULT 0 CHECK (principal IN (0,1)),
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_por     INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_por INTEGER REFERENCES funcionario(id)
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.3 Equipamentos
-- ---------------------------------------------------------------------------
CREATE TABLE marca (
    id    INTEGER PRIMARY KEY,
    nome  TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(nome)) >= 2),
    ativo INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
) STRICT;

CREATE TABLE tipo_equipamento (
    id         INTEGER PRIMARY KEY,
    nome       TEXT NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(nome)) >= 2),
    exige_imei INTEGER NOT NULL DEFAULT 0 CHECK (exige_imei IN (0,1)),
    ativo      INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
) STRICT;

CREATE TABLE modelo (
    id                  INTEGER PRIMARY KEY,
    id_marca            INTEGER NOT NULL REFERENCES marca(id),
    id_tipo_equipamento INTEGER NOT NULL REFERENCES tipo_equipamento(id),
    nome                TEXT    NOT NULL CHECK (length(trim(nome)) >= 1),
    ativo               INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    UNIQUE (id_marca, nome)
) STRICT;

CREATE TABLE equipamento (
    id             INTEGER PRIMARY KEY,
    id_cliente     INTEGER NOT NULL REFERENCES cliente(id),
    id_modelo      INTEGER NOT NULL REFERENCES modelo(id),
    numero_serie   TEXT    UNIQUE,
    imei           TEXT    UNIQUE CHECK (imei IS NULL OR (length(imei) = 15 AND imei NOT GLOB '*[^0-9]*')),
    cor            TEXT,
    observacao     TEXT,
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_em      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    criado_por     INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_em  TEXT    CHECK (atualizado_em IS NULL OR datetime(atualizado_em) = atualizado_em),
    atualizado_por INTEGER REFERENCES funcionario(id),
    versao         INTEGER NOT NULL DEFAULT 1 CHECK (versao >= 1),
    CHECK (numero_serie IS NOT NULL OR imei IS NOT NULL)
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.4 Catalogo
-- ---------------------------------------------------------------------------
CREATE TABLE categoria (
    id               INTEGER PRIMARY KEY,
    nome             TEXT    NOT NULL CHECK (length(trim(nome)) >= 2),
    id_categoria_pai INTEGER REFERENCES categoria(id),
    aplica_a         TEXT    NOT NULL CHECK (aplica_a IN ('SERVICO','PECA','AMBOS')),
    ativo            INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    UNIQUE (id_categoria_pai, nome),
    CHECK (id_categoria_pai IS NULL OR id_categoria_pai <> id)
) STRICT;

CREATE TABLE servico (
    id                 INTEGER PRIMARY KEY,
    codigo             TEXT    NOT NULL UNIQUE CHECK (codigo GLOB 'SRV-[0-9][0-9][0-9]*'),
    nome               TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(nome)) >= 3),
    id_categoria       INTEGER NOT NULL REFERENCES categoria(id),
    preco_base         INTEGER NOT NULL CHECK (preco_base >= 0),
    tempo_estimado_min INTEGER NOT NULL CHECK (tempo_estimado_min > 0),
    garantia_dias      INTEGER NOT NULL DEFAULT 90 CHECK (garantia_dias >= 0),
    ativo              INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_em          TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    criado_por         INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_em      TEXT    CHECK (atualizado_em IS NULL OR datetime(atualizado_em) = atualizado_em),
    atualizado_por     INTEGER REFERENCES funcionario(id),
    versao             INTEGER NOT NULL DEFAULT 1 CHECK (versao >= 1)
) STRICT;

CREATE TABLE peca (
    id             INTEGER PRIMARY KEY,
    sku            TEXT    NOT NULL UNIQUE CHECK (sku GLOB 'PEC-[0-9][0-9][0-9]*'),
    nome           TEXT    NOT NULL UNIQUE COLLATE NOCASE CHECK (length(trim(nome)) >= 3),
    id_categoria   INTEGER NOT NULL REFERENCES categoria(id),
    unidade        TEXT    NOT NULL DEFAULT 'UN' CHECK (unidade IN ('UN','KIT','CX','PCT','L','M','G')),
    preco_venda    INTEGER NOT NULL CHECK (preco_venda >= 0),
    custo_medio    INTEGER NOT NULL DEFAULT 0 CHECK (custo_medio >= 0),
    estoque_atual  INTEGER NOT NULL DEFAULT 0 CHECK (estoque_atual >= 0),     -- RN03
    estoque_minimo INTEGER NOT NULL DEFAULT 0 CHECK (estoque_minimo >= 0),
    localizacao    TEXT,
    garantia_dias  INTEGER NOT NULL DEFAULT 90 CHECK (garantia_dias >= 0),
    ativo          INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    criado_em      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    criado_por     INTEGER NOT NULL REFERENCES funcionario(id),
    atualizado_em  TEXT    CHECK (atualizado_em IS NULL OR datetime(atualizado_em) = atualizado_em),
    atualizado_por INTEGER REFERENCES funcionario(id),
    versao         INTEGER NOT NULL DEFAULT 1 CHECK (versao >= 1)
) STRICT;

CREATE TABLE historico_preco (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_item      TEXT    NOT NULL CHECK (tipo_item IN ('SERVICO','PECA')),
    id_item        INTEGER NOT NULL,
    preco_anterior INTEGER NOT NULL CHECK (preco_anterior >= 0),
    preco_novo     INTEGER NOT NULL CHECK (preco_novo >= 0),
    id_funcionario INTEGER NOT NULL REFERENCES funcionario(id),
    data_hora      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_hora) = data_hora)
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.5 Fornecedores e compras (RF09)
-- ---------------------------------------------------------------------------
CREATE TABLE fornecedor (
    id           INTEGER PRIMARY KEY,
    razao_social TEXT    NOT NULL CHECK (length(trim(razao_social)) >= 3),
    cnpj         TEXT    NOT NULL UNIQUE CHECK (length(cnpj) = 14 AND cnpj NOT GLOB '*[^0-9]*'),
    email        TEXT    CHECK (email IS NULL OR email LIKE '%_@_%'),
    telefone     TEXT    CHECK (telefone IS NULL OR (length(telefone) BETWEEN 10 AND 11 AND telefone NOT GLOB '*[^0-9]*')),
    ativo        INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1))
) STRICT;

CREATE TABLE compra (
    id             INTEGER PRIMARY KEY,
    id_fornecedor  INTEGER NOT NULL REFERENCES fornecedor(id),
    numero_nf      TEXT    NOT NULL CHECK (length(trim(numero_nf)) >= 1),
    data_compra    TEXT    NOT NULL CHECK (date(data_compra) = data_compra),
    valor_total    INTEGER NOT NULL DEFAULT 0 CHECK (valor_total >= 0),   -- mantido por trigger
    id_funcionario INTEGER NOT NULL REFERENCES funcionario(id),
    criado_em      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    UNIQUE (id_fornecedor, numero_nf)
) STRICT;

CREATE TABLE compra_item (
    id                   INTEGER PRIMARY KEY,
    id_compra            INTEGER NOT NULL REFERENCES compra(id),
    id_peca              INTEGER NOT NULL REFERENCES peca(id),
    quantidade           INTEGER NOT NULL CHECK (quantidade > 0),
    custo_unitario       INTEGER NOT NULL CHECK (custo_unitario >= 0),
    preco_venda_sugerido INTEGER NOT NULL DEFAULT 0 CHECK (preco_venda_sugerido >= 0),
    UNIQUE (id_compra, id_peca)
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.7 Ordem de servico (status e demais tabelas; movimento_estoque vem depois
--     de os_peca por causa da FK id_os_peca)
-- ---------------------------------------------------------------------------
CREATE TABLE status_os (
    id                     INTEGER PRIMARY KEY,
    codigo                 TEXT    NOT NULL UNIQUE,
    nome                   TEXT    NOT NULL,
    ordem_exibicao         INTEGER NOT NULL,
    permite_baixa_peca     INTEGER NOT NULL DEFAULT 0 CHECK (permite_baixa_peca IN (0,1)),
    permite_lancar_servico INTEGER NOT NULL DEFAULT 0 CHECK (permite_lancar_servico IN (0,1)),
    final                  INTEGER NOT NULL DEFAULT 0 CHECK (final IN (0,1))
) STRICT;

CREATE TABLE status_transicao (
    id_origem  INTEGER NOT NULL REFERENCES status_os(id),
    id_destino INTEGER NOT NULL REFERENCES status_os(id),
    PRIMARY KEY (id_origem, id_destino),
    CHECK (id_origem <> id_destino)
) STRICT, WITHOUT ROWID;

CREATE TABLE ordem_servico (
    id                   INTEGER PRIMARY KEY,
    numero               TEXT    UNIQUE,                -- gerado por trigger (OS-AAAA-NNNNNN)
    id_cliente           INTEGER NOT NULL REFERENCES cliente(id),
    id_equipamento       INTEGER NOT NULL REFERENCES equipamento(id),
    id_atendente         INTEGER NOT NULL REFERENCES funcionario(id),
    id_tecnico           INTEGER REFERENCES funcionario(id),
    id_status            INTEGER NOT NULL DEFAULT 1 REFERENCES status_os(id),
    prioridade           TEXT    NOT NULL DEFAULT 'NORMAL' CHECK (prioridade IN ('BAIXA','NORMAL','ALTA','URGENTE')),
    defeito_relatado     TEXT    NOT NULL CHECK (length(trim(defeito_relatado)) >= 5),
    defeito_constatado   TEXT,
    acessorios_recebidos TEXT,
    data_abertura        TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_abertura) = data_abertura),
    previsao_entrega     TEXT    CHECK (previsao_entrega IS NULL OR date(previsao_entrega) = previsao_entrega),
    data_fechamento      TEXT    CHECK (data_fechamento IS NULL OR datetime(data_fechamento) = data_fechamento),
    subtotal_servicos    INTEGER NOT NULL DEFAULT 0 CHECK (subtotal_servicos >= 0),
    subtotal_pecas       INTEGER NOT NULL DEFAULT 0 CHECK (subtotal_pecas >= 0),
    desconto             INTEGER NOT NULL DEFAULT 0 CHECK (desconto >= 0),
    valor_total          INTEGER GENERATED ALWAYS AS (subtotal_servicos + subtotal_pecas - desconto) STORED,
    garantia_ate         TEXT    CHECK (garantia_ate IS NULL OR date(garantia_ate) = garantia_ate),
    criado_em            TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    atualizado_em        TEXT    CHECK (atualizado_em IS NULL OR datetime(atualizado_em) = atualizado_em),
    atualizado_por       INTEGER REFERENCES funcionario(id),
    versao               INTEGER NOT NULL DEFAULT 1 CHECK (versao >= 1),
    CHECK (valor_total = subtotal_servicos + subtotal_pecas - desconto),
    CHECK (desconto <= subtotal_servicos + subtotal_pecas),
    CHECK ((id_status IN (6,7)) = (data_fechamento IS NOT NULL))
) STRICT;

CREATE TABLE os_historico_status (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    id_os              INTEGER NOT NULL REFERENCES ordem_servico(id),
    id_status_anterior INTEGER REFERENCES status_os(id),
    id_status_novo     INTEGER NOT NULL REFERENCES status_os(id),
    id_funcionario     INTEGER NOT NULL REFERENCES funcionario(id),
    observacao         TEXT,
    data_hora          TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_hora) = data_hora)
) STRICT;

CREATE TABLE os_orcamento (
    id              INTEGER PRIMARY KEY,
    id_os           INTEGER NOT NULL REFERENCES ordem_servico(id),
    valor_previsto  INTEGER NOT NULL CHECK (valor_previsto >= 0),
    validade        TEXT    NOT NULL CHECK (date(validade) = validade),
    situacao        TEXT    NOT NULL DEFAULT 'PENDENTE' CHECK (situacao IN ('PENDENTE','APROVADO','RECUSADO','EXPIRADO')),
    aprovado_em     TEXT    CHECK (aprovado_em IS NULL OR datetime(aprovado_em) = aprovado_em),
    forma_aprovacao TEXT    CHECK (forma_aprovacao IS NULL OR forma_aprovacao IN ('PRESENCIAL','TELEFONE','WHATSAPP','EMAIL')),
    criado_por      INTEGER NOT NULL REFERENCES funcionario(id),
    criado_em       TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(criado_em) = criado_em),
    CHECK (situacao <> 'APROVADO' OR (aprovado_em IS NOT NULL AND forma_aprovacao IS NOT NULL))
) STRICT;

CREATE TABLE os_servico (
    id                  INTEGER PRIMARY KEY,
    id_os               INTEGER NOT NULL REFERENCES ordem_servico(id),
    id_servico          INTEGER NOT NULL REFERENCES servico(id),
    id_tecnico          INTEGER NOT NULL REFERENCES funcionario(id),
    quantidade          INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    preco_unitario      INTEGER NOT NULL CHECK (preco_unitario >= 0),   -- congelado (RN02)
    desconto_item       INTEGER NOT NULL DEFAULT 0 CHECK (desconto_item >= 0),
    data_execucao       TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_execucao) = data_execucao),
    cancelado           INTEGER NOT NULL DEFAULT 0 CHECK (cancelado IN (0,1)),
    motivo_cancelamento TEXT,
    CHECK (desconto_item <= quantidade * preco_unitario),
    CHECK (cancelado = 0 OR (motivo_cancelamento IS NOT NULL AND length(trim(motivo_cancelamento)) >= 5))
) STRICT;

CREATE TABLE os_peca (
    id             INTEGER PRIMARY KEY,
    id_os          INTEGER NOT NULL REFERENCES ordem_servico(id),
    id_peca        INTEGER NOT NULL REFERENCES peca(id),
    id_tecnico     INTEGER NOT NULL REFERENCES funcionario(id),
    quantidade     INTEGER NOT NULL CHECK (quantidade > 0),
    preco_unitario INTEGER NOT NULL CHECK (preco_unitario >= 0),   -- congelado = peca.preco_venda
    custo_unitario INTEGER NOT NULL CHECK (custo_unitario >= 0),   -- snapshot de peca.custo_medio (margem)
    data_uso       TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_uso) = data_uso),
    estornado      INTEGER NOT NULL DEFAULT 0 CHECK (estornado IN (0,1)),
    motivo_estorno TEXT,
    CHECK (estornado = 0 OR (motivo_estorno IS NOT NULL AND length(trim(motivo_estorno)) >= 5))
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.6 Razao de estoque (kardex) - imutavel
-- ---------------------------------------------------------------------------
CREATE TABLE movimento_estoque (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_peca               INTEGER NOT NULL REFERENCES peca(id),
    tipo                  TEXT    NOT NULL CHECK (tipo IN ('ENTRADA','SAIDA_OS','DESCARTE','AJUSTE_ENTRADA','AJUSTE_SAIDA','ESTORNO_OS')),
    quantidade            INTEGER NOT NULL CHECK (quantidade > 0),
    custo_unitario        INTEGER NOT NULL CHECK (custo_unitario >= 0),
    saldo_anterior        INTEGER NOT NULL CHECK (saldo_anterior >= 0),
    saldo_posterior       INTEGER NOT NULL CHECK (saldo_posterior >= 0),
    custo_medio_anterior  INTEGER NOT NULL CHECK (custo_medio_anterior >= 0),
    custo_medio_posterior INTEGER NOT NULL CHECK (custo_medio_posterior >= 0),
    id_compra_item        INTEGER REFERENCES compra_item(id),
    id_os_peca            INTEGER REFERENCES os_peca(id),
    motivo                TEXT,
    id_funcionario        INTEGER NOT NULL REFERENCES funcionario(id),
    data_hora             TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_hora) = data_hora),
    CHECK ((tipo = 'ENTRADA') = (id_compra_item IS NOT NULL)),
    CHECK ((tipo IN ('SAIDA_OS','ESTORNO_OS')) = (id_os_peca IS NOT NULL)),
    CHECK (tipo NOT IN ('DESCARTE','AJUSTE_ENTRADA','AJUSTE_SAIDA') OR (motivo IS NOT NULL AND length(trim(motivo)) >= 5)),
    CHECK ((tipo IN ('ENTRADA','AJUSTE_ENTRADA','ESTORNO_OS') AND saldo_posterior = saldo_anterior + quantidade)
        OR (tipo IN ('SAIDA_OS','DESCARTE','AJUSTE_SAIDA') AND saldo_posterior = saldo_anterior - quantidade))
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.7 Pagamentos
-- ---------------------------------------------------------------------------
CREATE TABLE forma_pagamento (
    id                   INTEGER PRIMARY KEY,
    nome                 TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    permite_parcelamento INTEGER NOT NULL DEFAULT 0 CHECK (permite_parcelamento IN (0,1)),
    max_parcelas         INTEGER NOT NULL DEFAULT 1 CHECK (max_parcelas >= 1),
    taxa_bp              INTEGER NOT NULL DEFAULT 0 CHECK (taxa_bp >= 0),
    ativo                INTEGER NOT NULL DEFAULT 1 CHECK (ativo IN (0,1)),
    CHECK (permite_parcelamento = 1 OR max_parcelas = 1)
) STRICT;

CREATE TABLE os_pagamento (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    id_os              INTEGER NOT NULL REFERENCES ordem_servico(id),
    id_forma_pagamento INTEGER NOT NULL REFERENCES forma_pagamento(id),
    valor              INTEGER NOT NULL CHECK (valor > 0),
    parcelas           INTEGER NOT NULL DEFAULT 1 CHECK (parcelas >= 1),
    data_pagamento     TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_pagamento) = data_pagamento),
    id_funcionario     INTEGER NOT NULL REFERENCES funcionario(id),
    estornado          INTEGER NOT NULL DEFAULT 0 CHECK (estornado IN (0,1)),
    estornado_em       TEXT    CHECK (estornado_em IS NULL OR datetime(estornado_em) = estornado_em),
    motivo_estorno     TEXT,
    CHECK (estornado = 0 OR (estornado_em IS NOT NULL AND motivo_estorno IS NOT NULL AND length(trim(motivo_estorno)) >= 5))
) STRICT;

-- ---------------------------------------------------------------------------
-- 2.8 Auditoria e metadados
-- ---------------------------------------------------------------------------
CREATE TABLE auditoria (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    tabela         TEXT    NOT NULL,
    id_registro    INTEGER NOT NULL,
    operacao       TEXT    NOT NULL CHECK (operacao IN ('INSERT','UPDATE','DELETE')),
    dados_antes    TEXT    CHECK (dados_antes IS NULL OR json_valid(dados_antes)),
    dados_depois   TEXT    CHECK (dados_depois IS NULL OR json_valid(dados_depois)),
    id_funcionario INTEGER REFERENCES funcionario(id),
    data_hora      TEXT    NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(data_hora) = data_hora)
) STRICT;

CREATE TABLE schema_versao (
    versao     INTEGER PRIMARY KEY,
    descricao  TEXT NOT NULL,
    aplicado_em TEXT NOT NULL DEFAULT (datetime('now','localtime')) CHECK (datetime(aplicado_em) = aplicado_em)
) STRICT;

-- =============================================================================
-- INDICES (todas as FKs + indices de consulta; parciais onde indicado)
-- =============================================================================
-- Unicidade parcial
CREATE UNIQUE INDEX uq_cliente_contato_principal ON cliente_contato(id_cliente, tipo) WHERE principal = 1 AND ativo = 1;
CREATE UNIQUE INDEX uq_cliente_endereco_principal ON cliente_endereco(id_cliente) WHERE principal = 1 AND ativo = 1;
CREATE UNIQUE INDEX uq_os_orcamento_vigente ON os_orcamento(id_os) WHERE situacao IN ('PENDENTE','APROVADO');
CREATE UNIQUE INDEX uq_categoria_raiz_nome ON categoria(nome COLLATE NOCASE) WHERE id_categoria_pai IS NULL;

-- Indices de consulta pedidos na especificacao
CREATE INDEX idx_os_status_abertura      ON ordem_servico(id_status, data_abertura);
CREATE INDEX idx_os_tecnico_status       ON ordem_servico(id_tecnico, id_status);
CREATE INDEX idx_movimento_peca_data     ON movimento_estoque(id_peca, data_hora);
CREATE INDEX idx_auditoria_tabela_reg    ON auditoria(tabela, id_registro);
CREATE INDEX idx_os_pagamento_os_valido  ON os_pagamento(id_os) WHERE estornado = 0;
CREATE INDEX idx_peca_estoque_ativa      ON peca(estoque_atual) WHERE ativo = 1;
CREATE INDEX idx_cliente_nome            ON cliente(nome);

-- Indices de chaves estrangeiras
CREATE INDEX idx_cargo_permissao_perm    ON cargo_permissao(id_permissao);
CREATE INDEX idx_funcionario_cargo       ON funcionario(id_cargo);
CREATE INDEX idx_funcionario_criado_por  ON funcionario(criado_por);
CREATE INDEX idx_funcionario_atualizado_por ON funcionario(atualizado_por);
CREATE INDEX idx_cliente_criado_por      ON cliente(criado_por);
CREATE INDEX idx_cliente_atualizado_por  ON cliente(atualizado_por);
CREATE INDEX idx_cliente_contato_cliente ON cliente_contato(id_cliente);
CREATE INDEX idx_cliente_contato_criado  ON cliente_contato(criado_por);
CREATE INDEX idx_cliente_endereco_cliente ON cliente_endereco(id_cliente);
CREATE INDEX idx_cliente_endereco_criado ON cliente_endereco(criado_por);
CREATE INDEX idx_modelo_marca            ON modelo(id_marca);
CREATE INDEX idx_modelo_tipo             ON modelo(id_tipo_equipamento);
CREATE INDEX idx_equipamento_cliente     ON equipamento(id_cliente);
CREATE INDEX idx_equipamento_modelo      ON equipamento(id_modelo);
CREATE INDEX idx_equipamento_criado_por  ON equipamento(criado_por);
CREATE INDEX idx_categoria_pai           ON categoria(id_categoria_pai);
CREATE INDEX idx_servico_categoria       ON servico(id_categoria);
CREATE INDEX idx_servico_criado_por      ON servico(criado_por);
CREATE INDEX idx_peca_categoria          ON peca(id_categoria);
CREATE INDEX idx_peca_criado_por         ON peca(criado_por);
CREATE INDEX idx_historico_preco_item    ON historico_preco(tipo_item, id_item);
CREATE INDEX idx_historico_preco_func    ON historico_preco(id_funcionario);
CREATE INDEX idx_compra_funcionario      ON compra(id_funcionario);
CREATE INDEX idx_compra_item_peca        ON compra_item(id_peca);
CREATE INDEX idx_movimento_compra_item   ON movimento_estoque(id_compra_item);
CREATE INDEX idx_movimento_os_peca       ON movimento_estoque(id_os_peca);
CREATE INDEX idx_movimento_funcionario   ON movimento_estoque(id_funcionario);
CREATE INDEX idx_status_transicao_dest   ON status_transicao(id_destino);
CREATE INDEX idx_os_cliente              ON ordem_servico(id_cliente);
CREATE INDEX idx_os_equipamento          ON ordem_servico(id_equipamento);
CREATE INDEX idx_os_atendente            ON ordem_servico(id_atendente);
CREATE INDEX idx_os_atualizado_por       ON ordem_servico(atualizado_por);
CREATE INDEX idx_os_historico_os         ON os_historico_status(id_os, id);
CREATE INDEX idx_os_historico_func       ON os_historico_status(id_funcionario);
CREATE INDEX idx_os_historico_anterior   ON os_historico_status(id_status_anterior);
CREATE INDEX idx_os_historico_novo       ON os_historico_status(id_status_novo);
CREATE INDEX idx_os_orcamento_criado     ON os_orcamento(criado_por);
CREATE INDEX idx_os_servico_os           ON os_servico(id_os);
CREATE INDEX idx_os_servico_servico      ON os_servico(id_servico);
CREATE INDEX idx_os_servico_tecnico      ON os_servico(id_tecnico);
CREATE INDEX idx_os_peca_os              ON os_peca(id_os);
CREATE INDEX idx_os_peca_peca            ON os_peca(id_peca);
CREATE INDEX idx_os_peca_tecnico         ON os_peca(id_tecnico);
CREATE INDEX idx_os_pagamento_os         ON os_pagamento(id_os);
CREATE INDEX idx_os_pagamento_forma      ON os_pagamento(id_forma_pagamento);
CREATE INDEX idx_os_pagamento_func       ON os_pagamento(id_funcionario);
CREATE INDEX idx_auditoria_funcionario   ON auditoria(id_funcionario);

-- #############################################################################
-- SECAO 2. REGRAS DE NEGOCIO (permissoes, Luhn, kardex, maquina de estados, pagamentos)   (origem: 02_regras.sql)
-- #############################################################################

-- =============================================================================
-- TechFix - Banco Upgrade
-- 02_regras.sql : triggers de negocio (permissoes, Luhn, kardex, maquina de
-- estados da OS, orcamento, precos congelados, estorno, pagamentos)
-- Fonte de verdade: upgrade/docs/especificacao_upgrade.md
--
-- Padrao de permissao (secao 2.1) - funcionario inativo nao executa nada:
--   NOT EXISTS (SELECT 1 FROM funcionario f
--               JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
--               JOIN permissao p ON p.id = cp.id_permissao
--               WHERE f.id = <responsavel> AND f.ativo = 1 AND p.codigo = '<CODIGO>')
--
-- Convencoes:
--  * Triggers nao alteram NEW: quando a ordem das validacoes importa, ha UM
--    trigger por evento com varios "SELECT RAISE(...) WHERE ..." em sequencia.
--  * recursive_triggers = OFF (padrao do SQLite).
--  * Mensagens: RAISE(ABORT, 'CODIGO: mensagem').
--
-- Decisoes/desvios (ver upgrade/README.md):
--  * os_peca.custo_unitario deve ser igual a peca.custo_medio (snapshot enviado
--    pela aplicacao; divergencia rejeitada, como no preco congelado).
--  * Estorno de peca devolve o estoque ao custo medio vigente (custo medio nao
--    muda em saidas/estornos, conforme 2.6) - movimento do estorno usa
--    os_peca.id_tecnico como responsavel.
--  * Orcamento: criar/alterar exige OS_ALTERAR_STATUS do criado_por (a
--    especificacao nao define permissao propria).
--  * CANCELADO exige que nao haja pecas lancadas ativas (estornar antes).
--  * Pagamento so e aceito com a OS em PRONTO (status >= PRONTO e nao final);
--    estorno de pagamento so em OS nao final.
--  * Subtotais da OS so aceitam o valor recalculado (guard BEFORE UPDATE); o
--    recalculo reduz o desconto ao novo teto quando um item e cancelado/estornado.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 2.1 Funcionario / usuario
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_funcionario_bi_permissao BEFORE INSERT ON funcionario
WHEN EXISTS (SELECT 1 FROM funcionario) AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'FUNCIONARIO_GERENCIAR')
BEGIN
    -- o primeiro funcionario da base (bootstrap do gerente) e liberado
    SELECT RAISE(ABORT, 'PERM: FUNCIONARIO_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_funcionario_bu_permissao
BEFORE UPDATE OF nome, cpf, email, telefone, id_cargo, data_admissao, data_demissao, ativo ON funcionario
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'FUNCIONARIO_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: FUNCIONARIO_GERENCIAR necessária (ou funcionário inativo)');
END;

-- Demitido/inativado: o usuario de acesso tambem e desativado
CREATE TRIGGER trg_funcionario_au_desativa_usuario
AFTER UPDATE OF ativo ON funcionario
WHEN NEW.ativo = 0 AND OLD.ativo = 1
BEGIN
    UPDATE usuario SET ativo = 0 WHERE id_funcionario = NEW.id AND ativo = 1;
END;

CREATE TRIGGER trg_usuario_bi_regras BEFORE INSERT ON usuario
BEGIN
    SELECT RAISE(ABORT, 'USR: só funcionário ativo pode ter usuário')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario WHERE id = NEW.id_funcionario AND ativo = 1);
    SELECT RAISE(ABORT, 'USR: senha_hash deve ser um hash (bcrypt/argon2), nunca a senha em texto')
     WHERE NEW.senha_hash NOT LIKE '$%$%';
END;

-- ---------------------------------------------------------------------------
-- 2.2 Clientes (RF02)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_cliente_bi_permissao BEFORE INSERT ON cliente
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_cliente_bu_permissao
BEFORE UPDATE OF tipo_pessoa, nome, documento, data_nascimento, aceita_comunicacao, ativo ON cliente
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_cliente_contato_bi_permissao BEFORE INSERT ON cliente_contato
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_cliente_contato_bu_permissao
BEFORE UPDATE OF id_cliente, tipo, valor, principal, ativo ON cliente_contato
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_cliente_endereco_bi_permissao BEFORE INSERT ON cliente_endereco
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_cliente_endereco_bu_permissao
BEFORE UPDATE OF id_cliente, cep, logradouro, numero, complemento, bairro, cidade, uf, principal, ativo ON cliente_endereco
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'CLIENTE_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: CLIENTE_GERENCIAR necessária (ou funcionário inativo)');
END;

-- ---------------------------------------------------------------------------
-- 2.3 Equipamentos (RF03): permissao, IMEI obrigatorio e Luhn (CTE recursiva)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_equipamento_bi_permissao BEFORE INSERT ON equipamento
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'EQUIPAMENTO_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: EQUIPAMENTO_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_equipamento_bu_permissao
BEFORE UPDATE OF id_cliente, id_modelo, numero_serie, imei, cor, observacao, ativo ON equipamento
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'EQUIPAMENTO_GERENCIAR')
BEGIN
    SELECT RAISE(ABORT, 'PERM: EQUIPAMENTO_GERENCIAR necessária (ou funcionário inativo)');
END;

CREATE TRIGGER trg_equipamento_bi_imei BEFORE INSERT ON equipamento
BEGIN
    SELECT RAISE(ABORT, 'RF03: o tipo de equipamento exige IMEI')
     WHERE NEW.imei IS NULL
       AND EXISTS (SELECT 1 FROM modelo m JOIN tipo_equipamento t ON t.id = m.id_tipo_equipamento
                    WHERE m.id = NEW.id_modelo AND t.exige_imei = 1);
    SELECT RAISE(ABORT, 'RF03: IMEI inválido (dígito verificador, algoritmo de Luhn)')
     WHERE NEW.imei IS NOT NULL
       AND (WITH RECURSIVE d(i, s) AS (
                SELECT 1, 0
                UNION ALL
                SELECT i + 1,
                       s + CASE WHEN i % 2 = 0
                                THEN (CAST(substr(NEW.imei, i, 1) AS INTEGER) * 2) / 10
                                   + (CAST(substr(NEW.imei, i, 1) AS INTEGER) * 2) % 10
                                ELSE CAST(substr(NEW.imei, i, 1) AS INTEGER) END
                  FROM d WHERE i <= 15)
            SELECT s % 10 FROM d WHERE i = 16) <> 0;
END;

CREATE TRIGGER trg_equipamento_bu_imei BEFORE UPDATE OF imei, id_modelo ON equipamento
BEGIN
    SELECT RAISE(ABORT, 'RF03: o tipo de equipamento exige IMEI')
     WHERE NEW.imei IS NULL
       AND EXISTS (SELECT 1 FROM modelo m JOIN tipo_equipamento t ON t.id = m.id_tipo_equipamento
                    WHERE m.id = NEW.id_modelo AND t.exige_imei = 1);
    SELECT RAISE(ABORT, 'RF03: IMEI inválido (dígito verificador, algoritmo de Luhn)')
     WHERE NEW.imei IS NOT NULL
       AND (WITH RECURSIVE d(i, s) AS (
                SELECT 1, 0
                UNION ALL
                SELECT i + 1,
                       s + CASE WHEN i % 2 = 0
                                THEN (CAST(substr(NEW.imei, i, 1) AS INTEGER) * 2) / 10
                                   + (CAST(substr(NEW.imei, i, 1) AS INTEGER) * 2) % 10
                                ELSE CAST(substr(NEW.imei, i, 1) AS INTEGER) END
                  FROM d WHERE i <= 15)
            SELECT s % 10 FROM d WHERE i = 16) <> 0;
END;

-- ---------------------------------------------------------------------------
-- 2.4 Catalogo (RF05): permissao, categoria compativel, historico de precos
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_servico_bi_regras BEFORE INSERT ON servico
BEGIN
    SELECT RAISE(ABORT, 'PERM: CATALOGO_GERENCIAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'CATALOGO_GERENCIAR');
    SELECT RAISE(ABORT, 'CAT: a categoria não se aplica a serviços')
     WHERE NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.id_categoria AND aplica_a IN ('SERVICO','AMBOS') AND ativo = 1);
END;

CREATE TRIGGER trg_servico_bu_regras
BEFORE UPDATE OF codigo, nome, id_categoria, preco_base, tempo_estimado_min, garantia_dias, ativo ON servico
BEGIN
    SELECT RAISE(ABORT, 'PERM: CATALOGO_GERENCIAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'CATALOGO_GERENCIAR');
    SELECT RAISE(ABORT, 'CAT: a categoria não se aplica a serviços')
     WHERE NEW.id_categoria <> OLD.id_categoria
       AND NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.id_categoria AND aplica_a IN ('SERVICO','AMBOS') AND ativo = 1);
END;

CREATE TRIGGER trg_servico_au_historico_preco
AFTER UPDATE OF preco_base ON servico
WHEN NEW.preco_base <> OLD.preco_base
BEGIN
    INSERT INTO historico_preco (tipo_item, id_item, preco_anterior, preco_novo, id_funcionario)
    VALUES ('SERVICO', NEW.id, OLD.preco_base, NEW.preco_base, NEW.atualizado_por);
END;

CREATE TRIGGER trg_peca_bi_regras BEFORE INSERT ON peca
BEGIN
    SELECT RAISE(ABORT, 'PERM: CATALOGO_GERENCIAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'CATALOGO_GERENCIAR');
    SELECT RAISE(ABORT, 'KDX: estoque e custo médio só nascem de movimento (compra); crie a peça zerada')
     WHERE NEW.estoque_atual <> 0 OR NEW.custo_medio <> 0;
    SELECT RAISE(ABORT, 'CAT: a categoria não se aplica a peças')
     WHERE NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.id_categoria AND aplica_a IN ('PECA','AMBOS') AND ativo = 1);
END;

-- Atualizacao de cadastro/preco: exige CATALOGO_GERENCIAR (estoque e custo ficam fora: so pelo kardex)
CREATE TRIGGER trg_peca_bu_regras
BEFORE UPDATE OF sku, nome, id_categoria, unidade, preco_venda, estoque_minimo, localizacao, garantia_dias, ativo ON peca
BEGIN
    SELECT RAISE(ABORT, 'PERM: CATALOGO_GERENCIAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'CATALOGO_GERENCIAR');
    SELECT RAISE(ABORT, 'CAT: a categoria não se aplica a peças')
     WHERE NEW.id_categoria <> OLD.id_categoria
       AND NOT EXISTS (SELECT 1 FROM categoria WHERE id = NEW.id_categoria AND aplica_a IN ('PECA','AMBOS') AND ativo = 1);
END;

-- estoque_atual e custo_medio SO mudam pela razao de estoque (comparacao com o ultimo movimento)
CREATE TRIGGER trg_peca_bu_estoque_somente_kardex
BEFORE UPDATE OF estoque_atual, custo_medio ON peca
WHEN NEW.estoque_atual <> COALESCE((SELECT saldo_posterior FROM movimento_estoque
                                     WHERE id_peca = NEW.id ORDER BY id DESC LIMIT 1), 0)
  OR NEW.custo_medio <> COALESCE((SELECT custo_medio_posterior FROM movimento_estoque
                                   WHERE id_peca = NEW.id ORDER BY id DESC LIMIT 1), 0)
BEGIN
    SELECT RAISE(ABORT, 'KDX: estoque_atual/custo_medio só podem mudar por movimento_estoque');
END;

CREATE TRIGGER trg_peca_au_historico_preco
AFTER UPDATE OF preco_venda ON peca
WHEN NEW.preco_venda <> OLD.preco_venda
BEGIN
    INSERT INTO historico_preco (tipo_item, id_item, preco_anterior, preco_novo, id_funcionario)
    VALUES ('PECA', NEW.id, OLD.preco_venda, NEW.preco_venda, NEW.atualizado_por);
END;

-- ---------------------------------------------------------------------------
-- 2.5 Compras (RF09) e entrada de estoque
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_compra_bi_regras BEFORE INSERT ON compra
BEGIN
    SELECT RAISE(ABORT, 'PERM: ESTOQUE_ENTRADA necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'ESTOQUE_ENTRADA');
    SELECT RAISE(ABORT, 'CMP: valor_total é mantido pelos itens da compra')
     WHERE NEW.valor_total <> 0;
    SELECT RAISE(ABORT, 'CMP: fornecedor inativo')
     WHERE NOT EXISTS (SELECT 1 FROM fornecedor WHERE id = NEW.id_fornecedor AND ativo = 1);
END;

CREATE TRIGGER trg_compra_bu_regras BEFORE UPDATE ON compra
WHEN NEW.id_fornecedor <> OLD.id_fornecedor OR NEW.numero_nf <> OLD.numero_nf OR NEW.data_compra <> OLD.data_compra
  OR NEW.id_funcionario <> OLD.id_funcionario OR NEW.criado_em <> OLD.criado_em
  OR NEW.valor_total <> (SELECT COALESCE(SUM(quantidade * custo_unitario), 0) FROM compra_item WHERE id_compra = NEW.id)
BEGIN
    SELECT RAISE(ABORT, 'CMP: compra só admite atualização do valor_total pelos itens');
END;

CREATE TRIGGER trg_compra_item_bi_regras BEFORE INSERT ON compra_item
BEGIN
    SELECT RAISE(ABORT, 'CMP: peça inativa')
     WHERE NOT EXISTS (SELECT 1 FROM peca WHERE id = NEW.id_peca AND ativo = 1);
END;

-- Gera o movimento ENTRADA (custo medio ponderado) e recalcula o total da compra
CREATE TRIGGER trg_compra_item_ai_entrada AFTER INSERT ON compra_item
BEGIN
    INSERT INTO movimento_estoque
        (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
         custo_medio_anterior, custo_medio_posterior, id_compra_item, id_funcionario)
    SELECT p.id, 'ENTRADA', NEW.quantidade, NEW.custo_unitario,
           p.estoque_atual, p.estoque_atual + NEW.quantidade,
           p.custo_medio,
           CAST(ROUND((p.estoque_atual * p.custo_medio + NEW.quantidade * NEW.custo_unitario) * 1.0
                      / (p.estoque_atual + NEW.quantidade)) AS INTEGER),
           NEW.id,
           (SELECT id_funcionario FROM compra WHERE id = NEW.id_compra)
      FROM peca p WHERE p.id = NEW.id_peca;
    UPDATE compra
       SET valor_total = (SELECT COALESCE(SUM(quantidade * custo_unitario), 0) FROM compra_item WHERE id_compra = NEW.id_compra)
     WHERE id = NEW.id_compra;
END;

CREATE TRIGGER trg_compra_item_bu_imutavel BEFORE UPDATE ON compra_item
BEGIN
    SELECT RAISE(ABORT, 'IMUT: compra_item é imutável (lançamento de entrada)');
END;

-- ---------------------------------------------------------------------------
-- 2.6 Razao de estoque (kardex) - RF08, RF10, RF11, RN03
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_movimento_estoque_bi_regras BEFORE INSERT ON movimento_estoque
BEGIN
    SELECT RAISE(ABORT, 'RN03: estoque insuficiente')
     WHERE NEW.tipo IN ('SAIDA_OS','DESCARTE','AJUSTE_SAIDA')
       AND NEW.quantidade > (SELECT estoque_atual FROM peca WHERE id = NEW.id_peca);
    SELECT RAISE(ABORT, 'KDX: saldo/custo médio anterior não conferem com a peça')
     WHERE NEW.saldo_anterior <> (SELECT estoque_atual FROM peca WHERE id = NEW.id_peca)
        OR NEW.custo_medio_anterior <> (SELECT custo_medio FROM peca WHERE id = NEW.id_peca);
    SELECT RAISE(ABORT, 'PERM: funcionário inativo ou inexistente')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario WHERE id = NEW.id_funcionario AND ativo = 1);
    SELECT RAISE(ABORT, 'PERM: ESTOQUE_ENTRADA necessária')
     WHERE NEW.tipo = 'ENTRADA' AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'ESTOQUE_ENTRADA');
    SELECT RAISE(ABORT, 'PERM: ESTOQUE_BAIXA necessária para descarte')
     WHERE NEW.tipo = 'DESCARTE' AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'ESTOQUE_BAIXA');
    SELECT RAISE(ABORT, 'PERM: ESTOQUE_AJUSTE necessária para ajuste de inventário')
     WHERE NEW.tipo IN ('AJUSTE_ENTRADA','AJUSTE_SAIDA') AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'ESTOQUE_AJUSTE');
    SELECT RAISE(ABORT, 'PERM: OS_EXECUTAR necessária para baixa de peça em OS')
     WHERE NEW.tipo = 'SAIDA_OS' AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'OS_EXECUTAR');
    SELECT RAISE(ABORT, 'KDX: custo médio posterior incorreto (ponderado só em ENTRADA; demais tipos não alteram)')
     WHERE NEW.custo_medio_posterior <>
           CASE WHEN NEW.tipo = 'ENTRADA'
                THEN CAST(ROUND((NEW.saldo_anterior * NEW.custo_medio_anterior + NEW.quantidade * NEW.custo_unitario) * 1.0
                                / (NEW.saldo_anterior + NEW.quantidade)) AS INTEGER)
                ELSE NEW.custo_medio_anterior END;
END;

CREATE TRIGGER trg_movimento_estoque_ai_aplica AFTER INSERT ON movimento_estoque
BEGIN
    UPDATE peca
       SET estoque_atual  = NEW.saldo_posterior,
           custo_medio    = NEW.custo_medio_posterior,
           atualizado_por = NEW.id_funcionario
     WHERE id = NEW.id_peca;
END;

CREATE TRIGGER trg_movimento_estoque_bu_imutavel BEFORE UPDATE ON movimento_estoque
BEGIN
    SELECT RAISE(ABORT, 'IMUT: movimento_estoque é imutável (razão de estoque)');
END;

-- ---------------------------------------------------------------------------
-- 2.7 Ordem de servico
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_ordem_servico_bi_regras BEFORE INSERT ON ordem_servico
BEGIN
    SELECT RAISE(ABORT, 'PERM: OS_ABRIR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_atendente AND f.ativo = 1 AND p.codigo = 'OS_ABRIR');
    SELECT RAISE(ABORT, 'PERM: OS_EXECUTAR necessária para o técnico (ou funcionário inativo)')
     WHERE NEW.id_tecnico IS NOT NULL AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_tecnico AND f.ativo = 1 AND p.codigo = 'OS_EXECUTAR');
    SELECT RAISE(ABORT, 'OS: a OS deve ser aberta no status ABERTO')
     WHERE NEW.id_status <> (SELECT id FROM status_os WHERE codigo = 'ABERTO');
    SELECT RAISE(ABORT, 'OS: subtotais e desconto iniciam zerados')
     WHERE NEW.subtotal_servicos <> 0 OR NEW.subtotal_pecas <> 0 OR NEW.desconto <> 0;
    SELECT RAISE(ABORT, 'RF02: cliente inativo')
     WHERE NOT EXISTS (SELECT 1 FROM cliente WHERE id = NEW.id_cliente AND ativo = 1);
    SELECT RAISE(ABORT, 'RF03: equipamento inativo ou não pertence ao cliente da OS')
     WHERE NOT EXISTS (SELECT 1 FROM equipamento WHERE id = NEW.id_equipamento AND id_cliente = NEW.id_cliente AND ativo = 1);
    SELECT RAISE(ABORT, 'RF02: o cliente precisa de ao menos um contato ativo para abrir OS')
     WHERE NOT EXISTS (SELECT 1 FROM cliente_contato WHERE id_cliente = NEW.id_cliente AND ativo = 1);
END;

-- Numero gerado + primeiro registro do historico (origem NULL)
CREATE TRIGGER trg_ordem_servico_ai_abertura AFTER INSERT ON ordem_servico
BEGIN
    UPDATE ordem_servico
       SET numero = 'OS-' || strftime('%Y', NEW.data_abertura) || '-' || printf('%06d', NEW.id)
     WHERE id = NEW.id;
    INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
    VALUES (NEW.id, NULL, NEW.id_status, NEW.id_atendente, 'Abertura da OS');
END;

CREATE TRIGGER trg_ordem_servico_bu_imutaveis
BEFORE UPDATE OF numero, id_cliente, id_equipamento, id_atendente ON ordem_servico
WHEN OLD.numero IS NOT NULL
 AND (NEW.numero IS NOT OLD.numero OR NEW.id_cliente <> OLD.id_cliente
      OR NEW.id_equipamento <> OLD.id_equipamento OR NEW.id_atendente <> OLD.id_atendente)
BEGIN
    SELECT RAISE(ABORT, 'OS: número, cliente, equipamento e atendente não podem ser alterados');
END;

CREATE TRIGGER trg_ordem_servico_bu_status BEFORE UPDATE OF id_status ON ordem_servico
WHEN NEW.id_status <> COALESCE((SELECT id_status_novo FROM os_historico_status
                                 WHERE id_os = NEW.id ORDER BY id DESC LIMIT 1), -1)
BEGIN
    SELECT RAISE(ABORT, 'OS: o status só muda por INSERT em os_historico_status');
END;

CREATE TRIGGER trg_ordem_servico_bu_fechamento BEFORE UPDATE OF data_fechamento, garantia_ate ON ordem_servico
WHEN NEW.id_status = OLD.id_status
 AND (NEW.data_fechamento IS NOT OLD.data_fechamento OR NEW.garantia_ate IS NOT OLD.garantia_ate)
BEGIN
    SELECT RAISE(ABORT, 'OS: data_fechamento e garantia_ate são definidas pela mudança de status');
END;

CREATE TRIGGER trg_ordem_servico_bu_tecnico BEFORE UPDATE OF id_tecnico ON ordem_servico
WHEN NEW.id_tecnico IS NOT OLD.id_tecnico
BEGIN
    SELECT RAISE(ABORT, 'OS: OS finalizada não aceita troca de técnico')
     WHERE OLD.id_status IN (6,7);
    SELECT RAISE(ABORT, 'PERM: OS_EXECUTAR necessária para o técnico (ou funcionário inativo)')
     WHERE NEW.id_tecnico IS NOT NULL AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_tecnico AND f.ativo = 1 AND p.codigo = 'OS_EXECUTAR');
    SELECT RAISE(ABORT, 'OS: o técnico é obrigatório depois da abertura do diagnóstico')
     WHERE NEW.id_tecnico IS NULL AND OLD.id_status <> 1;
END;

CREATE TRIGGER trg_ordem_servico_bu_desconto BEFORE UPDATE OF desconto ON ordem_servico
WHEN NEW.desconto <> OLD.desconto
BEGIN
    SELECT RAISE(ABORT, 'OS: OS finalizada não aceita alteração de desconto')
     WHERE OLD.id_status IN (6,7);
    SELECT RAISE(ABORT, 'PERM: DESCONTO_CONCEDER necessária para conceder desconto (ou funcionário inativo)')
     WHERE NEW.desconto > OLD.desconto AND NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.atualizado_por AND f.ativo = 1 AND p.codigo = 'DESCONTO_CONCEDER');
END;

CREATE TRIGGER trg_ordem_servico_bu_subtotais BEFORE UPDATE OF subtotal_servicos, subtotal_pecas ON ordem_servico
WHEN NEW.subtotal_servicos <> (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id AND cancelado = 0) OR NEW.subtotal_pecas <> (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id AND estornado = 0)
BEGIN
    SELECT RAISE(ABORT, 'RN02: subtotais só podem ser definidos pelo recálculo dos itens da OS');
END;

CREATE TRIGGER trg_ordem_servico_bu_total_pago
BEFORE UPDATE OF desconto, subtotal_servicos, subtotal_pecas ON ordem_servico
WHEN EXISTS (SELECT 1 FROM os_pagamento WHERE id_os = NEW.id AND estornado = 0)
 AND NEW.subtotal_servicos + NEW.subtotal_pecas - NEW.desconto
     < (SELECT COALESCE(SUM(valor), 0) FROM os_pagamento WHERE id_os = NEW.id AND estornado = 0)
BEGIN
    SELECT RAISE(ABORT, 'RN04: o novo valor total ficaria abaixo do já pago; estorne pagamentos antes');
END;

-- Historico de status: unico caminho para mudar o status (RF07)
CREATE TRIGGER trg_os_historico_status_bi_regras BEFORE INSERT ON os_historico_status
BEGIN
    SELECT RAISE(ABORT, 'PERM: OS_ALTERAR_STATUS necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'OS_ALTERAR_STATUS');
    SELECT RAISE(ABORT, 'OS: o primeiro registro do histórico deve ser ABERTO')
     WHERE NEW.id_status_anterior IS NULL
       AND (NEW.id_status_novo <> (SELECT id FROM status_os WHERE codigo = 'ABERTO')
            OR EXISTS (SELECT 1 FROM os_historico_status WHERE id_os = NEW.id_os));
    SELECT RAISE(ABORT, 'OS: o status anterior informado não é o status atual da OS')
     WHERE NEW.id_status_anterior IS NOT NULL
       AND NEW.id_status_anterior IS NOT (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os);
    SELECT RAISE(ABORT, 'OS: transição de status inválida')
     WHERE NEW.id_status_anterior IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM status_transicao
                        WHERE id_origem = NEW.id_status_anterior AND id_destino = NEW.id_status_novo);
    SELECT RAISE(ABORT, 'OS: EM_DIAGNOSTICO exige técnico definido')
     WHERE NEW.id_status_novo = (SELECT id FROM status_os WHERE codigo = 'EM_DIAGNOSTICO')
       AND (SELECT id_tecnico FROM ordem_servico WHERE id = NEW.id_os) IS NULL;
    SELECT RAISE(ABORT, 'OS: ORCAMENTO_APROVADO/EM_REPARO exigem orçamento APROVADO vigente')
     WHERE NEW.id_status_novo IN ((SELECT id FROM status_os WHERE codigo = 'ORCAMENTO_APROVADO'), (SELECT id FROM status_os WHERE codigo = 'EM_REPARO'))
       AND NOT EXISTS (SELECT 1 FROM os_orcamento WHERE id_os = NEW.id_os AND situacao = 'APROVADO');
    SELECT RAISE(ABORT, 'RN04: ENTREGUE exige pagamentos válidos somando exatamente o valor total da OS')
     WHERE NEW.id_status_novo = (SELECT id FROM status_os WHERE codigo = 'ENTREGUE')
       AND (SELECT COALESCE(SUM(valor), 0) FROM os_pagamento WHERE id_os = NEW.id_os AND estornado = 0)
           <> (SELECT valor_total FROM ordem_servico WHERE id = NEW.id_os);
    SELECT RAISE(ABORT, 'OS: estorne as peças lançadas antes de cancelar a OS')
     WHERE NEW.id_status_novo = (SELECT id FROM status_os WHERE codigo = 'CANCELADO')
       AND EXISTS (SELECT 1 FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0);
END;

CREATE TRIGGER trg_os_historico_status_ai_aplica AFTER INSERT ON os_historico_status
WHEN NEW.id_status_anterior IS NOT NULL
BEGIN
    UPDATE ordem_servico
       SET id_status       = NEW.id_status_novo,
           data_fechamento = CASE WHEN NEW.id_status_novo IN (6,7) THEN NEW.data_hora ELSE data_fechamento END,
           garantia_ate    = CASE WHEN NEW.id_status_novo = 6
                                  THEN (SELECT date(NEW.data_hora, '+' || MAX(g) || ' days')
                                          FROM (SELECT s.garantia_dias AS g
                                                  FROM os_servico x JOIN servico s ON s.id = x.id_servico
                                                 WHERE x.id_os = NEW.id_os AND x.cancelado = 0
                                                UNION ALL
                                                SELECT p.garantia_dias
                                                  FROM os_peca y JOIN peca p ON p.id = y.id_peca
                                                 WHERE y.id_os = NEW.id_os AND y.estornado = 0))
                                  ELSE garantia_ate END,
           atualizado_por  = NEW.id_funcionario
     WHERE id = NEW.id_os;
END;

CREATE TRIGGER trg_os_historico_status_bu_imutavel BEFORE UPDATE ON os_historico_status
BEGIN
    SELECT RAISE(ABORT, 'IMUT: os_historico_status é imutável');
END;

-- Orcamento
CREATE TRIGGER trg_os_orcamento_bi_regras BEFORE INSERT ON os_orcamento
BEGIN
    SELECT RAISE(ABORT, 'PERM: OS_ALTERAR_STATUS necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.criado_por AND f.ativo = 1 AND p.codigo = 'OS_ALTERAR_STATUS');
    SELECT RAISE(ABORT, 'ORC: OS finalizada não aceita orçamento')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
    SELECT RAISE(ABORT, 'ORC: o orçamento nasce PENDENTE')
     WHERE NEW.situacao <> 'PENDENTE' OR NEW.aprovado_em IS NOT NULL OR NEW.forma_aprovacao IS NOT NULL;
END;

CREATE TRIGGER trg_os_orcamento_bu_regras BEFORE UPDATE ON os_orcamento
BEGIN
    SELECT RAISE(ABORT, 'ORC: OS, criador e data de criação não podem mudar')
     WHERE NEW.id_os <> OLD.id_os OR NEW.criado_por <> OLD.criado_por OR NEW.criado_em <> OLD.criado_em;
    SELECT RAISE(ABORT, 'ORC: orçamento encerrado (só APROVADO pode virar EXPIRADO)')
     WHERE OLD.situacao <> 'PENDENTE'
       AND NOT (OLD.situacao = 'APROVADO' AND NEW.situacao = 'EXPIRADO'
                AND NEW.valor_previsto = OLD.valor_previsto AND NEW.validade = OLD.validade);
    SELECT RAISE(ABORT, 'ORC: OS finalizada não aceita alteração de orçamento')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
    SELECT RAISE(ABORT, 'ORC: orçamento vencido não pode ser aprovado')
     WHERE NEW.situacao = 'APROVADO' AND NEW.validade < date('now','localtime');
END;

-- os_servico (RF06, RN02)
CREATE TRIGGER trg_os_servico_bi_regras BEFORE INSERT ON os_servico
BEGIN
    SELECT RAISE(ABORT, 'RF06: o status atual da OS não permite lançar serviço')
     WHERE NOT EXISTS (SELECT 1 FROM ordem_servico o JOIN status_os s ON s.id = o.id_status
                        WHERE o.id = NEW.id_os AND s.permite_lancar_servico = 1);
    SELECT RAISE(ABORT, 'RF06: o técnico do serviço deve ser o técnico da OS')
     WHERE NEW.id_tecnico IS NOT (SELECT id_tecnico FROM ordem_servico WHERE id = NEW.id_os);
    SELECT RAISE(ABORT, 'PERM: OS_EXECUTAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_tecnico AND f.ativo = 1 AND p.codigo = 'OS_EXECUTAR');
    SELECT RAISE(ABORT, 'RF06: serviço inativo')
     WHERE NOT EXISTS (SELECT 1 FROM servico WHERE id = NEW.id_servico AND ativo = 1);
    SELECT RAISE(ABORT, 'RN02: preco_unitario deve ser o preço atual do catálogo (use desconto_item para abater)')
     WHERE NEW.preco_unitario <> (SELECT preco_base FROM servico WHERE id = NEW.id_servico);
END;

CREATE TRIGGER trg_os_servico_ai_recalcula AFTER INSERT ON os_servico
BEGIN
    UPDATE ordem_servico
       SET subtotal_servicos = (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0),
           subtotal_pecas    = (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0),
           desconto          = MIN(desconto, (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0) + (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0))
     WHERE id = NEW.id_os;
END;

CREATE TRIGGER trg_os_servico_bu_regras BEFORE UPDATE ON os_servico
BEGIN
    SELECT RAISE(ABORT, 'RN02: item de serviço é congelado; só é permitido cancelar (cancelado 0→1)')
     WHERE NEW.id_os <> OLD.id_os OR NEW.id_servico <> OLD.id_servico OR NEW.id_tecnico <> OLD.id_tecnico
        OR NEW.quantidade <> OLD.quantidade OR NEW.preco_unitario <> OLD.preco_unitario
        OR NEW.desconto_item <> OLD.desconto_item OR NEW.data_execucao <> OLD.data_execucao
        OR OLD.cancelado = 1 OR NEW.cancelado = 0;
    SELECT RAISE(ABORT, 'RF06: OS finalizada não aceita cancelamento de serviço')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
    SELECT RAISE(ABORT, 'RF06: informe o motivo do cancelamento (mínimo 5 caracteres)')
     WHERE NEW.motivo_cancelamento IS NULL OR length(trim(NEW.motivo_cancelamento)) < 5;
END;

CREATE TRIGGER trg_os_servico_au_recalcula AFTER UPDATE ON os_servico
BEGIN
    UPDATE ordem_servico
       SET subtotal_servicos = (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0),
           subtotal_pecas    = (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0),
           desconto          = MIN(desconto, (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0) + (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0))
     WHERE id = NEW.id_os;
END;

-- os_peca (RF11, RN01, RN03)
CREATE TRIGGER trg_os_peca_bi_regras BEFORE INSERT ON os_peca
BEGIN
    SELECT RAISE(ABORT, 'RN01: o status atual da OS não permite baixa de peças')
     WHERE NOT EXISTS (SELECT 1 FROM ordem_servico o JOIN status_os s ON s.id = o.id_status
                        WHERE o.id = NEW.id_os AND s.permite_baixa_peca = 1);
    SELECT RAISE(ABORT, 'RF11: o técnico da peça deve ser o técnico da OS')
     WHERE NEW.id_tecnico IS NOT (SELECT id_tecnico FROM ordem_servico WHERE id = NEW.id_os);
    SELECT RAISE(ABORT, 'PERM: OS_EXECUTAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_tecnico AND f.ativo = 1 AND p.codigo = 'OS_EXECUTAR');
    SELECT RAISE(ABORT, 'RF11: peça inativa')
     WHERE NOT EXISTS (SELECT 1 FROM peca WHERE id = NEW.id_peca AND ativo = 1);
    SELECT RAISE(ABORT, 'RN03: estoque insuficiente')
     WHERE NEW.quantidade > (SELECT estoque_atual FROM peca WHERE id = NEW.id_peca);
    SELECT RAISE(ABORT, 'RN02: preco_unitario deve ser o preço de venda atual da peça')
     WHERE NEW.preco_unitario <> (SELECT preco_venda FROM peca WHERE id = NEW.id_peca);
    SELECT RAISE(ABORT, 'RN02: custo_unitario deve ser o custo médio atual da peça')
     WHERE NEW.custo_unitario <> (SELECT custo_medio FROM peca WHERE id = NEW.id_peca);
    SELECT RAISE(ABORT, 'RF11: uma peça nova nasce não estornada')
     WHERE NEW.estornado <> 0;
END;

CREATE TRIGGER trg_os_peca_ai_baixa AFTER INSERT ON os_peca
BEGIN
    INSERT INTO movimento_estoque
        (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
         custo_medio_anterior, custo_medio_posterior, id_os_peca, id_funcionario)
    SELECT p.id, 'SAIDA_OS', NEW.quantidade, NEW.custo_unitario,
           p.estoque_atual, p.estoque_atual - NEW.quantidade,
           p.custo_medio, p.custo_medio, NEW.id, NEW.id_tecnico
      FROM peca p WHERE p.id = NEW.id_peca;
    UPDATE ordem_servico
       SET subtotal_servicos = (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0),
           subtotal_pecas    = (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0),
           desconto          = MIN(desconto, (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0) + (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0))
     WHERE id = NEW.id_os;
END;

CREATE TRIGGER trg_os_peca_bu_regras BEFORE UPDATE ON os_peca
BEGIN
    SELECT RAISE(ABORT, 'RN02: item de peça é congelado; só é permitido o estorno (estornado 0→1)')
     WHERE NEW.id_os <> OLD.id_os OR NEW.id_peca <> OLD.id_peca OR NEW.id_tecnico <> OLD.id_tecnico
        OR NEW.quantidade <> OLD.quantidade OR NEW.preco_unitario <> OLD.preco_unitario
        OR NEW.custo_unitario <> OLD.custo_unitario OR NEW.data_uso <> OLD.data_uso
        OR OLD.estornado = 1 OR NEW.estornado = 0;
    SELECT RAISE(ABORT, 'RF11: OS finalizada não aceita estorno de peça')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
    SELECT RAISE(ABORT, 'RF11: informe o motivo do estorno (mínimo 5 caracteres)')
     WHERE NEW.motivo_estorno IS NULL OR length(trim(NEW.motivo_estorno)) < 5;
END;

-- Estorno devolve o estoque (movimento ESTORNO_OS) e recalcula a OS
CREATE TRIGGER trg_os_peca_au_estorno AFTER UPDATE ON os_peca
WHEN NEW.estornado = 1 AND OLD.estornado = 0
BEGIN
    INSERT INTO movimento_estoque
        (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
         custo_medio_anterior, custo_medio_posterior, id_os_peca, id_funcionario)
    SELECT p.id, 'ESTORNO_OS', NEW.quantidade, NEW.custo_unitario,
           p.estoque_atual, p.estoque_atual + NEW.quantidade,
           p.custo_medio, p.custo_medio, NEW.id, NEW.id_tecnico
      FROM peca p WHERE p.id = NEW.id_peca;
    UPDATE ordem_servico
       SET subtotal_servicos = (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0),
           subtotal_pecas    = (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0),
           desconto          = MIN(desconto, (SELECT COALESCE(SUM(quantidade * preco_unitario - desconto_item), 0) FROM os_servico WHERE id_os = NEW.id_os AND cancelado = 0) + (SELECT COALESCE(SUM(quantidade * preco_unitario), 0) FROM os_peca WHERE id_os = NEW.id_os AND estornado = 0))
     WHERE id = NEW.id_os;
END;

-- Pagamentos (RN04)
CREATE TRIGGER trg_os_pagamento_bi_regras BEFORE INSERT ON os_pagamento
BEGIN
    SELECT RAISE(ABORT, 'PERM: PAGAMENTO_REGISTRAR necessária (ou funcionário inativo)')
     WHERE NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.id_funcionario AND f.ativo = 1 AND p.codigo = 'PAGAMENTO_REGISTRAR');
    SELECT RAISE(ABORT, 'PAG: pagamento nasce não estornado')
     WHERE NEW.estornado <> 0;
    SELECT RAISE(ABORT, 'PAG: OS finalizada não aceita pagamento')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
    SELECT RAISE(ABORT, 'PAG: pagamento só é aceito com a OS PRONTA (entrega/fechamento)')
     WHERE (SELECT s.ordem_exibicao FROM ordem_servico o JOIN status_os s ON s.id = o.id_status WHERE o.id = NEW.id_os)
           < (SELECT ordem_exibicao FROM status_os WHERE codigo = 'PRONTO');
    SELECT RAISE(ABORT, 'PAG: forma de pagamento inativa')
     WHERE NOT EXISTS (SELECT 1 FROM forma_pagamento WHERE id = NEW.id_forma_pagamento AND ativo = 1);
    SELECT RAISE(ABORT, 'PAG: número de parcelas acima do máximo da forma de pagamento')
     WHERE NEW.parcelas > (SELECT max_parcelas FROM forma_pagamento WHERE id = NEW.id_forma_pagamento);
    SELECT RAISE(ABORT, 'RN04: pagamento acima do valor total da OS')
     WHERE (SELECT COALESCE(SUM(valor), 0) FROM os_pagamento WHERE id_os = NEW.id_os AND estornado = 0) + NEW.valor
           > (SELECT valor_total FROM ordem_servico WHERE id = NEW.id_os);
END;

CREATE TRIGGER trg_os_pagamento_bu_regras BEFORE UPDATE ON os_pagamento
BEGIN
    SELECT RAISE(ABORT, 'PAG: pagamento é imutável; só é permitido o estorno (uma única vez)')
     WHERE NEW.id_os <> OLD.id_os OR NEW.id_forma_pagamento <> OLD.id_forma_pagamento
        OR NEW.valor <> OLD.valor OR NEW.parcelas <> OLD.parcelas
        OR NEW.data_pagamento <> OLD.data_pagamento OR NEW.id_funcionario <> OLD.id_funcionario
        OR OLD.estornado = 1 OR NEW.estornado = 0;
    SELECT RAISE(ABORT, 'PAG: OS finalizada não aceita estorno de pagamento')
     WHERE (SELECT id_status FROM ordem_servico WHERE id = NEW.id_os) IN (6,7);
END;

-- #############################################################################
-- SECAO 3. AUDITORIA, VERSIONAMENTO E BLOQUEIO DE EXCLUSAO   (origem: 03_auditoria.sql)
-- #############################################################################

-- =============================================================================
-- TechFix - Banco Upgrade
-- 03_auditoria.sql : auditoria JSON, versionamento (versao/atualizado_em),
-- imutabilidade de logs e bloqueio de DELETE fisico
-- Fonte de verdade: upgrade/docs/especificacao_upgrade.md (2.8, 1)
--
-- Notas de projeto:
--  * Versionamento: um trigger AFTER UPDATE por tabela versionada incrementa
--    versao e atualiza atualizado_em quando o UPDATE de origem NAO alterou
--    versao (WHEN NEW.versao = OLD.versao). O UPDATE interno do proprio trigger
--    altera versao e por isso nao dispara auditoria nem novo incremento
--    (recursive_triggers = OFF). A aplicacao NAO deve gravar versao; o lock
--    otimista e feito com "UPDATE ... WHERE id = ? AND versao = ?" e checando
--    changes().
--  * Auditoria de UPDATE em tabela versionada registra, em dados_depois, a
--    versao ja incrementada (NEW.versao + 1) e atualizado_em corrente.
--  * ordem_servico: a atribuicao do numero (UPDATE interno do trigger de
--    abertura, OLD.numero IS NULL) nao conta como alteracao/versao; o INSERT
--    auditado ja traz o numero calculado.
--  * usuario: senha_hash NUNCA entra na auditoria; dados_depois traz apenas o
--    indicador senha_alterada.
--  * Bloqueio de DELETE: trg_<tabela>_bd_bloqueia em todas as tabelas, exceto
--    cargo_permissao (configuracao) e schema_versao (metadado).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Versionamento / atualizado_em
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_cliente_au_versao AFTER UPDATE ON cliente
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE cliente SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_equipamento_au_versao AFTER UPDATE ON equipamento
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE equipamento SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_ordem_servico_au_versao AFTER UPDATE ON ordem_servico
WHEN NEW.versao = OLD.versao AND OLD.numero IS NOT NULL
BEGIN
    UPDATE ordem_servico SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_peca_au_versao AFTER UPDATE ON peca
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE peca SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_servico_au_versao AFTER UPDATE ON servico
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE servico SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

-- ---------------------------------------------------------------------------
-- Auditoria (json_object das colunas; senha_hash excluido)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_funcionario_ai_auditoria AFTER INSERT ON funcionario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('funcionario', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'cpf', NEW.cpf,
                      'email', NEW.email,
                      'telefone', NEW.telefone,
                      'id_cargo', NEW.id_cargo,
                      'data_admissao', NEW.data_admissao,
                      'data_demissao', NEW.data_demissao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_por', NEW.atualizado_por),
            NEW.criado_por);
END;

CREATE TRIGGER trg_funcionario_au_auditoria AFTER UPDATE ON funcionario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('funcionario', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'nome', OLD.nome,
                      'cpf', OLD.cpf,
                      'email', OLD.email,
                      'telefone', OLD.telefone,
                      'id_cargo', OLD.id_cargo,
                      'data_admissao', OLD.data_admissao,
                      'data_demissao', OLD.data_demissao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_por', OLD.atualizado_por),
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'cpf', NEW.cpf,
                      'email', NEW.email,
                      'telefone', NEW.telefone,
                      'id_cargo', NEW.id_cargo,
                      'data_admissao', NEW.data_admissao,
                      'data_demissao', NEW.data_demissao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_por', NEW.atualizado_por),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_usuario_ai_auditoria AFTER INSERT ON usuario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('usuario', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_funcionario', NEW.id_funcionario,
                      'login', NEW.login,
                      'tentativas_falhas', NEW.tentativas_falhas,
                      'bloqueado_ate', NEW.bloqueado_ate,
                      'ultimo_login', NEW.ultimo_login,
                      'ativo', NEW.ativo,
                      'senha_alterada', 0),
            NULL);
END;

CREATE TRIGGER trg_usuario_au_auditoria AFTER UPDATE ON usuario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('usuario', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_funcionario', OLD.id_funcionario,
                      'login', OLD.login,
                      'tentativas_falhas', OLD.tentativas_falhas,
                      'bloqueado_ate', OLD.bloqueado_ate,
                      'ultimo_login', OLD.ultimo_login,
                      'ativo', OLD.ativo),
            json_object('id', NEW.id,
                      'id_funcionario', NEW.id_funcionario,
                      'login', NEW.login,
                      'tentativas_falhas', NEW.tentativas_falhas,
                      'bloqueado_ate', NEW.bloqueado_ate,
                      'ultimo_login', NEW.ultimo_login,
                      'ativo', NEW.ativo,
                      'senha_alterada', CASE WHEN NEW.senha_hash <> OLD.senha_hash THEN 1 ELSE 0 END),
            NULL);
END;

CREATE TRIGGER trg_cliente_ai_auditoria AFTER INSERT ON cliente
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('cliente', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'tipo_pessoa', NEW.tipo_pessoa,
                      'nome', NEW.nome,
                      'documento', NEW.documento,
                      'data_nascimento', NEW.data_nascimento,
                      'aceita_comunicacao', NEW.aceita_comunicacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_cliente_au_auditoria AFTER UPDATE ON cliente
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('cliente', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'tipo_pessoa', OLD.tipo_pessoa,
                      'nome', OLD.nome,
                      'documento', OLD.documento,
                      'data_nascimento', OLD.data_nascimento,
                      'aceita_comunicacao', OLD.aceita_comunicacao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'tipo_pessoa', NEW.tipo_pessoa,
                      'nome', NEW.nome,
                      'documento', NEW.documento,
                      'data_nascimento', NEW.data_nascimento,
                      'aceita_comunicacao', NEW.aceita_comunicacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_equipamento_ai_auditoria AFTER INSERT ON equipamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('equipamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_cliente', NEW.id_cliente,
                      'id_modelo', NEW.id_modelo,
                      'numero_serie', NEW.numero_serie,
                      'imei', NEW.imei,
                      'cor', NEW.cor,
                      'observacao', NEW.observacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_equipamento_au_auditoria AFTER UPDATE ON equipamento
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('equipamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_cliente', OLD.id_cliente,
                      'id_modelo', OLD.id_modelo,
                      'numero_serie', OLD.numero_serie,
                      'imei', OLD.imei,
                      'cor', OLD.cor,
                      'observacao', OLD.observacao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'id_cliente', NEW.id_cliente,
                      'id_modelo', NEW.id_modelo,
                      'numero_serie', NEW.numero_serie,
                      'imei', NEW.imei,
                      'cor', NEW.cor,
                      'observacao', NEW.observacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_servico_ai_auditoria AFTER INSERT ON servico
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('servico', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'codigo', NEW.codigo,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'preco_base', NEW.preco_base,
                      'tempo_estimado_min', NEW.tempo_estimado_min,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_servico_au_auditoria AFTER UPDATE ON servico
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('servico', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'codigo', OLD.codigo,
                      'nome', OLD.nome,
                      'id_categoria', OLD.id_categoria,
                      'preco_base', OLD.preco_base,
                      'tempo_estimado_min', OLD.tempo_estimado_min,
                      'garantia_dias', OLD.garantia_dias,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'codigo', NEW.codigo,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'preco_base', NEW.preco_base,
                      'tempo_estimado_min', NEW.tempo_estimado_min,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_peca_ai_auditoria AFTER INSERT ON peca
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('peca', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'sku', NEW.sku,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'unidade', NEW.unidade,
                      'preco_venda', NEW.preco_venda,
                      'custo_medio', NEW.custo_medio,
                      'estoque_atual', NEW.estoque_atual,
                      'estoque_minimo', NEW.estoque_minimo,
                      'localizacao', NEW.localizacao,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_peca_au_auditoria AFTER UPDATE ON peca
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('peca', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'sku', OLD.sku,
                      'nome', OLD.nome,
                      'id_categoria', OLD.id_categoria,
                      'unidade', OLD.unidade,
                      'preco_venda', OLD.preco_venda,
                      'custo_medio', OLD.custo_medio,
                      'estoque_atual', OLD.estoque_atual,
                      'estoque_minimo', OLD.estoque_minimo,
                      'localizacao', OLD.localizacao,
                      'garantia_dias', OLD.garantia_dias,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'sku', NEW.sku,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'unidade', NEW.unidade,
                      'preco_venda', NEW.preco_venda,
                      'custo_medio', NEW.custo_medio,
                      'estoque_atual', NEW.estoque_atual,
                      'estoque_minimo', NEW.estoque_minimo,
                      'localizacao', NEW.localizacao,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_ordem_servico_ai_auditoria AFTER INSERT ON ordem_servico
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('ordem_servico', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'numero', COALESCE(NEW.numero, 'OS-' || strftime('%Y', NEW.data_abertura) || '-' || printf('%06d', NEW.id)),
                      'id_cliente', NEW.id_cliente,
                      'id_equipamento', NEW.id_equipamento,
                      'id_atendente', NEW.id_atendente,
                      'id_tecnico', NEW.id_tecnico,
                      'id_status', NEW.id_status,
                      'prioridade', NEW.prioridade,
                      'defeito_relatado', NEW.defeito_relatado,
                      'defeito_constatado', NEW.defeito_constatado,
                      'acessorios_recebidos', NEW.acessorios_recebidos,
                      'data_abertura', NEW.data_abertura,
                      'previsao_entrega', NEW.previsao_entrega,
                      'data_fechamento', NEW.data_fechamento,
                      'subtotal_servicos', NEW.subtotal_servicos,
                      'subtotal_pecas', NEW.subtotal_pecas,
                      'desconto', NEW.desconto,
                      'valor_total', NEW.valor_total,
                      'garantia_ate', NEW.garantia_ate,
                      'criado_em', NEW.criado_em,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.id_atendente);
END;

CREATE TRIGGER trg_ordem_servico_au_auditoria AFTER UPDATE ON ordem_servico
WHEN NEW.versao = OLD.versao AND OLD.numero IS NOT NULL
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('ordem_servico', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'numero', OLD.numero,
                      'id_cliente', OLD.id_cliente,
                      'id_equipamento', OLD.id_equipamento,
                      'id_atendente', OLD.id_atendente,
                      'id_tecnico', OLD.id_tecnico,
                      'id_status', OLD.id_status,
                      'prioridade', OLD.prioridade,
                      'defeito_relatado', OLD.defeito_relatado,
                      'defeito_constatado', OLD.defeito_constatado,
                      'acessorios_recebidos', OLD.acessorios_recebidos,
                      'data_abertura', OLD.data_abertura,
                      'previsao_entrega', OLD.previsao_entrega,
                      'data_fechamento', OLD.data_fechamento,
                      'subtotal_servicos', OLD.subtotal_servicos,
                      'subtotal_pecas', OLD.subtotal_pecas,
                      'desconto', OLD.desconto,
                      'valor_total', OLD.valor_total,
                      'garantia_ate', OLD.garantia_ate,
                      'criado_em', OLD.criado_em,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'numero', COALESCE(NEW.numero, 'OS-' || strftime('%Y', NEW.data_abertura) || '-' || printf('%06d', NEW.id)),
                      'id_cliente', NEW.id_cliente,
                      'id_equipamento', NEW.id_equipamento,
                      'id_atendente', NEW.id_atendente,
                      'id_tecnico', NEW.id_tecnico,
                      'id_status', NEW.id_status,
                      'prioridade', NEW.prioridade,
                      'defeito_relatado', NEW.defeito_relatado,
                      'defeito_constatado', NEW.defeito_constatado,
                      'acessorios_recebidos', NEW.acessorios_recebidos,
                      'data_abertura', NEW.data_abertura,
                      'previsao_entrega', NEW.previsao_entrega,
                      'data_fechamento', NEW.data_fechamento,
                      'subtotal_servicos', NEW.subtotal_servicos,
                      'subtotal_pecas', NEW.subtotal_pecas,
                      'desconto', NEW.desconto,
                      'valor_total', NEW.valor_total,
                      'garantia_ate', NEW.garantia_ate,
                      'criado_em', NEW.criado_em,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.id_atendente));
END;

CREATE TRIGGER trg_os_pagamento_ai_auditoria AFTER INSERT ON os_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('os_pagamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_os', NEW.id_os,
                      'id_forma_pagamento', NEW.id_forma_pagamento,
                      'valor', NEW.valor,
                      'parcelas', NEW.parcelas,
                      'data_pagamento', NEW.data_pagamento,
                      'id_funcionario', NEW.id_funcionario,
                      'estornado', NEW.estornado,
                      'estornado_em', NEW.estornado_em,
                      'motivo_estorno', NEW.motivo_estorno),
            NEW.id_funcionario);
END;

CREATE TRIGGER trg_os_pagamento_au_auditoria AFTER UPDATE ON os_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('os_pagamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_os', OLD.id_os,
                      'id_forma_pagamento', OLD.id_forma_pagamento,
                      'valor', OLD.valor,
                      'parcelas', OLD.parcelas,
                      'data_pagamento', OLD.data_pagamento,
                      'id_funcionario', OLD.id_funcionario,
                      'estornado', OLD.estornado,
                      'estornado_em', OLD.estornado_em,
                      'motivo_estorno', OLD.motivo_estorno),
            json_object('id', NEW.id,
                      'id_os', NEW.id_os,
                      'id_forma_pagamento', NEW.id_forma_pagamento,
                      'valor', NEW.valor,
                      'parcelas', NEW.parcelas,
                      'data_pagamento', NEW.data_pagamento,
                      'id_funcionario', NEW.id_funcionario,
                      'estornado', NEW.estornado,
                      'estornado_em', NEW.estornado_em,
                      'motivo_estorno', NEW.motivo_estorno),
            NEW.id_funcionario);
END;

CREATE TRIGGER trg_forma_pagamento_ai_auditoria AFTER INSERT ON forma_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('forma_pagamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'permite_parcelamento', NEW.permite_parcelamento,
                      'max_parcelas', NEW.max_parcelas,
                      'taxa_bp', NEW.taxa_bp,
                      'ativo', NEW.ativo),
            NULL);
END;

CREATE TRIGGER trg_forma_pagamento_au_auditoria AFTER UPDATE ON forma_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('forma_pagamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'nome', OLD.nome,
                      'permite_parcelamento', OLD.permite_parcelamento,
                      'max_parcelas', OLD.max_parcelas,
                      'taxa_bp', OLD.taxa_bp,
                      'ativo', OLD.ativo),
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'permite_parcelamento', NEW.permite_parcelamento,
                      'max_parcelas', NEW.max_parcelas,
                      'taxa_bp', NEW.taxa_bp,
                      'ativo', NEW.ativo),
            NULL);
END;

-- ---------------------------------------------------------------------------
-- Logs imutaveis
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_auditoria_bu_imutavel BEFORE UPDATE ON auditoria
BEGIN
    SELECT RAISE(ABORT, 'IMUT: auditoria é imutável');
END;

CREATE TRIGGER trg_historico_preco_bu_imutavel BEFORE UPDATE ON historico_preco
BEGIN
    SELECT RAISE(ABORT, 'IMUT: historico_preco é imutável');
END;

-- ---------------------------------------------------------------------------
-- Bloqueio de DELETE fisico (exclusao e logica: ativo = 0)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_cargo_bd_bloqueia BEFORE DELETE ON cargo
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_permissao_bd_bloqueia BEFORE DELETE ON permissao
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_funcionario_bd_bloqueia BEFORE DELETE ON funcionario
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_usuario_bd_bloqueia BEFORE DELETE ON usuario
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_bd_bloqueia BEFORE DELETE ON cliente
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_contato_bd_bloqueia BEFORE DELETE ON cliente_contato
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_endereco_bd_bloqueia BEFORE DELETE ON cliente_endereco
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_marca_bd_bloqueia BEFORE DELETE ON marca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_tipo_equipamento_bd_bloqueia BEFORE DELETE ON tipo_equipamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_modelo_bd_bloqueia BEFORE DELETE ON modelo
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_equipamento_bd_bloqueia BEFORE DELETE ON equipamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_categoria_bd_bloqueia BEFORE DELETE ON categoria
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_servico_bd_bloqueia BEFORE DELETE ON servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_peca_bd_bloqueia BEFORE DELETE ON peca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_historico_preco_bd_bloqueia BEFORE DELETE ON historico_preco
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_fornecedor_bd_bloqueia BEFORE DELETE ON fornecedor
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_compra_bd_bloqueia BEFORE DELETE ON compra
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_compra_item_bd_bloqueia BEFORE DELETE ON compra_item
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_status_os_bd_bloqueia BEFORE DELETE ON status_os
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_status_transicao_bd_bloqueia BEFORE DELETE ON status_transicao
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_ordem_servico_bd_bloqueia BEFORE DELETE ON ordem_servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_historico_status_bd_bloqueia BEFORE DELETE ON os_historico_status
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_orcamento_bd_bloqueia BEFORE DELETE ON os_orcamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_servico_bd_bloqueia BEFORE DELETE ON os_servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_peca_bd_bloqueia BEFORE DELETE ON os_peca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_movimento_estoque_bd_bloqueia BEFORE DELETE ON movimento_estoque
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_forma_pagamento_bd_bloqueia BEFORE DELETE ON forma_pagamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_pagamento_bd_bloqueia BEFORE DELETE ON os_pagamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_auditoria_bd_bloqueia BEFORE DELETE ON auditoria
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

-- #############################################################################
-- SECAO 4. VIEWS GERENCIAIS   (origem: 04_views.sql)
-- #############################################################################

-- =============================================================================
-- TechFix - Banco Upgrade
-- 04_views.sql : 8 views gerenciais (secao 4 da especificacao)
-- Valores monetarios em centavos; datas em horario local.
-- =============================================================================

-- Painel operacional das OS
CREATE VIEW vw_os_painel AS
SELECT o.id                                   AS id_os,
       o.numero,
       c.nome                                 AS cliente,
       (SELECT cc.valor FROM cliente_contato cc
         WHERE cc.id_cliente = c.id AND cc.principal = 1 AND cc.ativo = 1
         ORDER BY cc.id LIMIT 1)              AS contato_principal,
       te.nome                                AS tipo_equipamento,
       ma.nome                                AS marca,
       mo.nome                                AS modelo,
       s.codigo                               AS status,
       o.prioridade,
       tec.nome                               AS tecnico,
       CAST(julianday(COALESCE(o.data_fechamento, datetime('now','localtime'))) - julianday(o.data_abertura) AS INTEGER)
                                              AS dias_em_aberto,
       o.subtotal_servicos,
       o.subtotal_pecas,
       o.desconto,
       o.valor_total,
       COALESCE(pg.pago, 0)                   AS total_pago,
       o.valor_total - COALESCE(pg.pago, 0)   AS saldo_a_pagar
  FROM ordem_servico o
  JOIN cliente c            ON c.id  = o.id_cliente
  JOIN equipamento e        ON e.id  = o.id_equipamento
  JOIN modelo mo            ON mo.id = e.id_modelo
  JOIN marca ma             ON ma.id = mo.id_marca
  JOIN tipo_equipamento te  ON te.id = mo.id_tipo_equipamento
  JOIN status_os s          ON s.id  = o.id_status
  LEFT JOIN funcionario tec ON tec.id = o.id_tecnico
  LEFT JOIN (SELECT id_os, SUM(valor) AS pago FROM os_pagamento WHERE estornado = 0 GROUP BY id_os) pg
         ON pg.id_os = o.id;

-- Itens da OS (servicos e pecas nao cancelados/estornados)
CREATE VIEW vw_os_extrato AS
SELECT o.id AS id_os, o.numero,
       'SERVICO' AS tipo_item,
       sv.codigo AS codigo_item,
       sv.nome   AS descricao,
       x.quantidade,
       x.preco_unitario,
       x.desconto_item AS desconto,
       x.quantidade * x.preco_unitario - x.desconto_item AS total
  FROM os_servico x
  JOIN ordem_servico o ON o.id = x.id_os
  JOIN servico sv      ON sv.id = x.id_servico
 WHERE x.cancelado = 0
UNION ALL
SELECT o.id, o.numero,
       'PECA',
       p.sku,
       p.nome,
       y.quantidade,
       y.preco_unitario,
       0,
       y.quantidade * y.preco_unitario
  FROM os_peca y
  JOIN ordem_servico o ON o.id = y.id_os
  JOIN peca p          ON p.id = y.id_peca
 WHERE y.estornado = 0;

-- Pecas ativas no ou abaixo do estoque minimo, com sugestao de compra (repor ate 2x o minimo)
CREATE VIEW vw_estoque_reposicao AS
SELECT p.id AS id_peca, p.sku, p.nome, c.nome AS categoria, p.localizacao,
       p.estoque_atual, p.estoque_minimo,
       MAX(p.estoque_minimo * 2 - p.estoque_atual, 1) AS sugestao_compra,
       p.custo_medio,
       MAX(p.estoque_minimo * 2 - p.estoque_atual, 1) * p.custo_medio AS custo_estimado_compra
  FROM peca p
  JOIN categoria c ON c.id = p.id_categoria
 WHERE p.ativo = 1 AND p.estoque_atual <= p.estoque_minimo;

-- Razao de estoque legivel
CREATE VIEW vw_kardex AS
SELECT m.id AS id_movimento, m.data_hora,
       p.sku, p.nome AS peca,
       m.tipo,
       CASE WHEN m.tipo IN ('ENTRADA','AJUSTE_ENTRADA','ESTORNO_OS') THEN m.quantidade ELSE 0 END AS entrada,
       CASE WHEN m.tipo IN ('SAIDA_OS','DESCARTE','AJUSTE_SAIDA')    THEN m.quantidade ELSE 0 END AS saida,
       m.saldo_anterior, m.saldo_posterior,
       m.custo_unitario,
       m.custo_medio_anterior, m.custo_medio_posterior,
       m.motivo,
       f.nome AS responsavel
  FROM movimento_estoque m
  JOIN peca p        ON p.id = m.id_peca
  JOIN funcionario f ON f.id = m.id_funcionario;

-- Faturamento mensal (OS entregues, por mes de fechamento)
CREATE VIEW vw_faturamento_mensal AS
SELECT strftime('%Y-%m', o.data_fechamento)                 AS mes,
       COUNT(*)                                             AS os_entregues,
       SUM(o.subtotal_servicos)                             AS receita_servicos,
       SUM(o.subtotal_pecas)                                AS receita_pecas,
       SUM(COALESCE(cp.custo, 0))                           AS custo_pecas,
       SUM(o.desconto)                                      AS descontos,
       SUM(o.valor_total)                                   AS receita_liquida,
       SUM(o.valor_total - COALESCE(cp.custo, 0))           AS margem_bruta
  FROM ordem_servico o
  LEFT JOIN (SELECT id_os, SUM(quantidade * custo_unitario) AS custo
               FROM os_peca WHERE estornado = 0 GROUP BY id_os) cp ON cp.id_os = o.id
 WHERE o.id_status = (SELECT id FROM status_os WHERE codigo = 'ENTREGUE')
 GROUP BY strftime('%Y-%m', o.data_fechamento);

-- Produtividade por tecnico
CREATE VIEW vw_produtividade_tecnico AS
SELECT f.id AS id_tecnico, f.nome AS tecnico,
       COUNT(o.id)                                                   AS os_atendidas,
       SUM(CASE WHEN o.id_status = 6 THEN 1 ELSE 0 END)              AS os_entregues,
       ROUND(AVG(CASE WHEN o.id_status = 6
                      THEN (julianday(o.data_fechamento) - julianday(o.data_abertura)) * 24 END), 2)
                                                                     AS tempo_medio_horas,
       COALESCE(SUM(CASE WHEN o.id_status = 6 THEN o.valor_total END), 0) AS receita
  FROM funcionario f
  JOIN ordem_servico o ON o.id_tecnico = f.id
 GROUP BY f.id, f.nome;

-- Garantias vigentes
CREATE VIEW vw_garantias_ativas AS
SELECT o.id AS id_os, o.numero, c.nome AS cliente,
       mo.nome AS modelo, o.data_fechamento AS data_entrega, o.garantia_ate,
       CAST(julianday(o.garantia_ate) - julianday(date('now','localtime')) AS INTEGER) AS dias_restantes
  FROM ordem_servico o
  JOIN cliente c     ON c.id  = o.id_cliente
  JOIN equipamento e ON e.id  = o.id_equipamento
  JOIN modelo mo     ON mo.id = e.id_modelo
 WHERE o.id_status = (SELECT id FROM status_os WHERE codigo = 'ENTREGUE')
   AND o.garantia_ate >= date('now','localtime');

-- Auditoria com o nome do funcionario
CREATE VIEW vw_auditoria AS
SELECT a.id, a.data_hora, a.tabela, a.id_registro, a.operacao,
       a.id_funcionario, f.nome AS funcionario,
       a.dados_antes, a.dados_depois
  FROM auditoria a
  LEFT JOIN funcionario f ON f.id = a.id_funcionario;

-- #############################################################################
-- SECAO 5. DADOS INICIAIS   (origem: 05_dados.sql)
-- #############################################################################

-- =============================================================================
-- TechFix - Banco Upgrade
-- 05_dados.sql : dados iniciais (seed)
-- Fonte: upgrade/docs/especificacao_upgrade.md (secao 5) e tabela de pecas e servicos
--
-- ATENCAO (uso real): os senha_hash abaixo sao PLACEHOLDERS fictícios no formato
-- bcrypt. TROQUE por hashes reais (bcrypt/argon2) gerados pela aplicacao antes
-- de usar o banco; nunca grave senha em texto.
--
-- O seed passa pelos MESMOS triggers do sistema: estoque inicial entra por
-- compras (movimentos ENTRADA), OS percorrem a maquina de estados, pagamentos
-- e descontos exigem permissao. Ids sao deterministicos (banco recem-criado).
-- Dinheiro em centavos.
-- =============================================================================

-- Versao do esquema
INSERT INTO schema_versao (versao, descricao) VALUES
    (1, 'Modelo base RF01-RF11 / RN01-RN04'),
    (2, 'Permissoes por cargo, kardex com custo medio, maquina de estados da OS'),
    (3, 'Upgrade: auditoria JSON, versionamento, orcamento, pagamentos multiplos, garantia, indices e views');

-- Cargos e permissoes
INSERT INTO cargo (id, nome, descricao) VALUES
    (1, 'Gerente',   'Administra a loja: catalogo, estoque, descontos e equipe'),
    (2, 'Atendente', 'Recepciona clientes, abre OS e recebe pagamentos'),
    (3, 'Técnico',   'Diagnostica, executa o reparo e baixa peças');

INSERT INTO permissao (id, codigo, descricao) VALUES
    (1,  'FUNCIONARIO_GERENCIAR', 'Cadastrar e alterar funcionários'),
    (2,  'CLIENTE_GERENCIAR',     'Cadastrar e alterar clientes, contatos e endereços'),
    (3,  'EQUIPAMENTO_GERENCIAR', 'Cadastrar e alterar equipamentos'),
    (4,  'OS_ABRIR',              'Abrir ordem de serviço'),
    (5,  'OS_EXECUTAR',           'Executar serviços e baixar peças em OS'),
    (6,  'OS_ALTERAR_STATUS',     'Alterar o status da OS e gerir orçamentos'),
    (7,  'CATALOGO_GERENCIAR',    'Gerir catálogo de serviços e peças e seus preços'),
    (8,  'ESTOQUE_ENTRADA',       'Registrar compras / entrada de estoque'),
    (9,  'ESTOQUE_BAIXA',         'Descartar peças'),
    (10, 'ESTOQUE_AJUSTE',        'Ajustar o inventário'),
    (11, 'PAGAMENTO_REGISTRAR',   'Registrar pagamentos'),
    (12, 'DESCONTO_CONCEDER',     'Conceder desconto na OS');

-- Matriz da especificacao 2.1: Gerente (1) tudo menos OS_EXECUTAR | Atendente (2) | Tecnico (3)
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (1,1),(1,2),(1,3),(1,4),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11),(1,12);
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (2,2),(2,3),(2,4),(2,6),(2,11);
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (3,5),(3,6),(3,9);

-- Status da OS (seed fixo) e transicoes
INSERT INTO status_os (id, codigo, nome, ordem_exibicao, permite_baixa_peca, permite_lancar_servico, final) VALUES
    (1, 'ABERTO',             'Aberto',               1, 0, 0, 0),
    (2, 'EM_DIAGNOSTICO',     'Em diagnóstico',       2, 0, 1, 0),
    (3, 'ORCAMENTO_APROVADO', 'Orçamento aprovado',   3, 1, 1, 0),
    (4, 'EM_REPARO',          'Em reparo',            4, 1, 1, 0),
    (5, 'PRONTO',             'Pronto para retirada', 5, 0, 0, 0),
    (6, 'ENTREGUE',           'Entregue',             6, 0, 0, 1),
    (7, 'CANCELADO',          'Cancelado',            7, 0, 0, 1);

INSERT INTO status_transicao (id_origem, id_destino) VALUES
    (1,2),(1,7),(2,3),(2,7),(3,4),(3,7),(4,5),(4,3),(5,6),(5,4);

-- Formas de pagamento (taxa em pontos-base)
INSERT INTO forma_pagamento (id, nome, permite_parcelamento, max_parcelas, taxa_bp) VALUES
    (1, 'Dinheiro', 0, 1, 0),
    (2, 'Pix',      0, 1, 0),
    (3, 'Débito',   0, 1, 150),
    (4, 'Crédito',  1, 12, 349),
    (5, 'Boleto',   0, 1, 200);

-- Equipe: 1 gerente, 2 atendentes, 3 tecnicos (o primeiro funcionario e o bootstrap do gerente)
INSERT INTO funcionario (id, nome, cpf, email, telefone, id_cargo, data_admissao, criado_por) VALUES
    (1, 'Marcos Andrade',     '12345678909', 'marcos.andrade@techfix.com.br',  '11991110001', 1, '2024-01-08', NULL);
INSERT INTO funcionario (id, nome, cpf, email, telefone, id_cargo, data_admissao, criado_por) VALUES
    (2, 'Juliana Prado',      '98765432100', 'juliana.prado@techfix.com.br',   '11991110002', 2, '2024-02-05', 1),
    (3, 'Rafael Teixeira',    '45678912300', 'rafael.teixeira@techfix.com.br', '11991110003', 2, '2024-03-11', 1),
    (4, 'Carlos Menezes',     '86288366757', 'carlos.menezes@techfix.com.br',  '11991110004', 3, '2024-02-19', 1),
    (5, 'Beatriz Souza',      '71428793860', 'beatriz.souza@techfix.com.br',   '11991110005', 3, '2024-04-01', 1),
    (6, 'Diego Fontes',       '41763058907', 'diego.fontes@techfix.com.br',    '11991110006', 3, '2024-05-13', 1);

-- Usuarios (senha_hash = PLACEHOLDER bcrypt ficticio: TROCAR antes de producao)
INSERT INTO usuario (id_funcionario, login, senha_hash) VALUES
    (1, 'marcos.andrade',  '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (2, 'juliana.prado',   '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (3, 'rafael.teixeira', '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (4, 'carlos.menezes',  '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (5, 'beatriz.souza',   '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (6, 'diego.fontes',    '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx');

-- Categorias hierarquicas (raizes: Servicos=1, Pecas=2)
INSERT INTO categoria (id, nome, id_categoria_pai, aplica_a) VALUES
    (1, 'Serviços', NULL, 'SERVICO'),
    (2, 'Peças',    NULL, 'PECA');
INSERT INTO categoria (id, nome, id_categoria_pai, aplica_a) VALUES
    (3,  'Computadores',         1, 'SERVICO'),
    (4,  'Celulares',            1, 'SERVICO'),
    (5,  'Smart TVs',            1, 'SERVICO'),
    (6,  'Redes',                1, 'SERVICO'),
    (7,  'Videogames',           1, 'SERVICO'),
    (8,  'Áudio',                1, 'SERVICO'),
    (9,  'Recuperação de Dados', 1, 'SERVICO'),
    (10, 'Eletrônica Avançada',  1, 'SERVICO'),
    (11, 'Informática',          2, 'PECA'),
    (12, 'Insumos',              2, 'PECA'),
    (13, 'Acessórios',           2, 'PECA'),
    (14, 'Telas',                2, 'PECA'),
    (15, 'Baterias',             2, 'PECA'),
    (16, 'Componentes',          2, 'PECA'),
    (17, 'Carcaças',             2, 'PECA'),
    (18, 'TVs',                  2, 'PECA');

-- Marcas, tipos e modelos
INSERT INTO marca (id, nome) VALUES
    (1,'Apple'),(2,'Samsung'),(3,'Motorola'),(4,'Xiaomi'),(5,'LG'),
    (6,'Dell'),(7,'Lenovo'),(8,'Sony'),(9,'Microsoft'),(10,'JBL');
INSERT INTO tipo_equipamento (id, nome, exige_imei) VALUES
    (1,'Celular',1),(2,'Notebook',0),(3,'Desktop',0),(4,'Smart TV',0),
    (5,'Videogame',0),(6,'Caixa de Som',0),(7,'Headset',0);
INSERT INTO modelo (id, id_marca, id_tipo_equipamento, nome) VALUES
    (1, 1, 1, 'iPhone 11'),
    (2, 2, 1, 'Galaxy A54'),
    (3, 3, 1, 'Moto G84'),
    (4, 4, 1, 'Redmi Note 11'),
    (5, 6, 2, 'Inspiron 15 3520'),
    (6, 7, 2, 'IdeaPad 3'),
    (7, 2, 4, 'UN50TU8000'),
    (8, 5, 4, '43UP7500'),
    (9, 8, 5, 'PlayStation 5'),
    (10, 9, 5, 'Xbox Series S'),
    (11, 10, 6, 'Flip 6');

-- Fornecedores
INSERT INTO fornecedor (id, razao_social, cnpj, email, telefone) VALUES
    (1, 'InfoParts Distribuidora Ltda',      '11222333000181', 'vendas@infoparts.example.com', '1133334444'),
    (2, 'Mobile & TV Componentes Eireli',    '27865757000102', 'comercial@mobiletv.example.com', '1144445555');

-- Catalogo de SERVICOS (23): codigo SRV-001.., preco em centavos, tempo em minutos
INSERT INTO servico (codigo, nome, id_categoria, preco_base, tempo_estimado_min, garantia_dias, criado_por) VALUES
    ('SRV-001', 'Formatação e Instalação de Sistema Operacional', 3, 12000, 120, 30, 1),
    ('SRV-002', 'Limpeza Interna e Troca de Pasta Térmica', 3, 15000, 90, 90, 1),
    ('SRV-003', 'Upgrade de Hardware (RAM/SSD)', 3, 8000, 60, 90, 1),
    ('SRV-004', 'Remoção de Vírus e Malwares', 3, 10000, 90, 30, 1),
    ('SRV-005', 'Troca de Tela de Notebook', 3, 18000, 90, 90, 1),
    ('SRV-006', 'Troca de Display/Frontal de Celular', 4, 15000, 60, 90, 1),
    ('SRV-007', 'Troca de Bateria de Smartphone', 4, 9000, 30, 90, 1),
    ('SRV-008', 'Desoxidação após Contato com Líquido', 4, 20000, 180, 90, 1),
    ('SRV-009', 'Reparo em Conector de Carga (Micro USB / Type-C)', 4, 11000, 90, 90, 1),
    ('SRV-010', 'Troca de Barra de LED de Smart TV', 5, 35000, 180, 90, 1),
    ('SRV-011', 'Reparo na Placa Principal de Smart TV', 5, 28000, 150, 90, 1),
    ('SRV-012', 'Conserto de Fonte de Alimentação Interna (TV)', 5, 22000, 120, 90, 1),
    ('SRV-013', 'Configuração de Rede e Roteador Wi-Fi', 6, 9000, 60, 30, 1),
    ('SRV-014', 'Higienização e Troca de Metal Líquido / Pasta Térmica (Console)', 7, 22000, 120, 90, 1),
    ('SRV-015', 'Reparo de Drift em Analógico de Controle (Joy-Con / DualSense / Xbox)', 7, 8000, 60, 90, 1),
    ('SRV-016', 'Substituição de HDMI / Conector de Vídeo (Console)', 7, 25000, 150, 90, 1),
    ('SRV-017', 'Troca de Bateria de Caixa de Som Portátil (Bluetooth)', 8, 12000, 90, 90, 1),
    ('SRV-018', 'Troca de Almofadas / Reparo de Cabo de Headset Gamer', 8, 7000, 60, 90, 1),
    ('SRV-019', 'Recuperação de Dados de HD / SSD / Pendrive Danificado', 9, 30000, 240, 30, 1),
    ('SRV-020', 'Rebaling / Reparo de BGA em Placa Mãe ou Placa de Vídeo', 10, 45000, 300, 180, 1),
    ('SRV-021', 'Gravação e Reprogramação de BIOS Eprom (Notebook / Desktop)', 10, 16000, 120, 90, 1),
    ('SRV-022', 'Troca de Vidro Traseiro de Smartphone a Laser / Manual', 4, 18000, 150, 90, 1),
    ('SRV-023', 'Reparo e Solda de Conector Jack P2/P10 de Mesa de Som ou Amplificador', 8, 9500, 60, 90, 1);

-- Catalogo de PECAS (34): nascem com estoque 0; o estoque inicial entra por compras (ENTRADA)
INSERT INTO peca (sku, nome, id_categoria, unidade, preco_venda, estoque_minimo, localizacao, garantia_dias, criado_por) VALUES
    ('PEC-001', 'SSD NVMe 512GB M.2', 11, 'UN', 26000, 4, 'EST-A-01', 90, 1),
    ('PEC-002', 'SSD SATA III 480GB 2.5"', 11, 'UN', 21000, 5, 'EST-A-02', 90, 1),
    ('PEC-003', 'Memória RAM DDR4 8GB 2666MHz (Notebook)', 11, 'UN', 17000, 3, 'EST-A-03', 90, 1),
    ('PEC-004', 'Memória RAM DDR4 16GB 3200MHz (Desktop)', 11, 'UN', 32000, 2, 'EST-A-04', 90, 1),
    ('PEC-005', 'Pasta Térmica de Alta Performance (Bisnaga 4g)', 12, 'UN', 6000, 6, 'EST-B-05', 30, 1),
    ('PEC-006', 'Fonte ATX 500W 80 Plus Bronze', 11, 'UN', 34000, 2, 'EST-A-06', 90, 1),
    ('PEC-007', 'Bateria Célula Moeda CR2032 (Cartela c/ 5)', 12, 'PCT', 2500, 8, 'EST-B-07', 30, 1),
    ('PEC-008', 'Cooler para Processador Socket Universal', 11, 'UN', 9500, 2, 'EST-A-08', 90, 1),
    ('PEC-009', 'Cabo SATA III 6Gbps 50cm', 13, 'UN', 1500, 12, 'EST-C-09', 90, 1),
    ('PEC-010', 'Tela LED 15.6" Slim 30 Pinos Full HD', 14, 'UN', 48000, 1, 'EST-D-10', 90, 1),
    ('PEC-011', 'Display Frontal Completo iPhone 11', 14, 'UN', 35000, 1, 'EST-D-11', 90, 1),
    ('PEC-012', 'Display Frontal Completo Samsung Galaxy A54', 14, 'UN', 31000, 2, 'EST-D-12', 90, 1),
    ('PEC-013', 'Display Frontal Completo Motorola Moto G84', 14, 'UN', 28000, 1, 'EST-D-13', 90, 1),
    ('PEC-014', 'Bateria Compatível iPhone 11 (3110mAh)', 15, 'UN', 16000, 2, 'EST-E-14', 90, 1),
    ('PEC-015', 'Bateria Compatível Samsung Galaxy A32', 15, 'UN', 13000, 2, 'EST-E-15', 90, 1),
    ('PEC-016', 'Bateria Compatível Moto G30', 15, 'UN', 12000, 2, 'EST-E-16', 90, 1),
    ('PEC-017', 'Conector de Carga Type-C Universal (Unidade)', 16, 'UN', 2000, 25, 'EST-F-17', 90, 1),
    ('PEC-018', 'Conector de Carga Micro USB V8', 16, 'UN', 1500, 25, 'EST-F-18', 90, 1),
    ('PEC-019', 'Flex de Carga e Microfone Moto G9 Play', 16, 'UN', 5500, 2, 'EST-F-19', 90, 1),
    ('PEC-020', 'Tampa Traseira de Vidro iPhone 12', 17, 'UN', 11000, 1, 'EST-G-20', 90, 1),
    ('PEC-021', 'Câmera Traseira Principal Redmi Note 11', 16, 'UN', 14000, 3, 'EST-F-21', 90, 1),
    ('PEC-022', 'Alto-Falante Auricular Universal', 16, 'UN', 2500, 10, 'EST-F-22', 90, 1),
    ('PEC-023', 'Barra de LED TV Samsung 50" (Kit com 3 barras)', 18, 'KIT', 23000, 1, 'EST-H-23', 90, 1),
    ('PEC-024', 'Barra de LED TV LG 43" (Kit com 3 barras)', 18, 'KIT', 19500, 1, 'EST-H-24', 90, 1),
    ('PEC-025', 'Placa Fonte TV Samsung UN50TU8000', 18, 'UN', 31000, 2, 'EST-H-25', 90, 1),
    ('PEC-026', 'Placa Principal TV LG 43UP7500', 18, 'UN', 42000, 2, 'EST-H-26', 90, 1),
    ('PEC-027', 'Cabo Flat T-Con para Display TV 55"', 18, 'UN', 6500, 2, 'EST-H-27', 90, 1),
    ('PEC-028', 'Receptor Infravermelho para Controle Remoto TV', 16, 'UN', 2000, 4, 'EST-F-28', 90, 1),
    ('PEC-029', 'Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)', 12, 'UN', 15000, 3, 'EST-B-29', 30, 1),
    ('PEC-030', 'Álcool Isopropílico 99.8% 1 Litro', 12, 'L', 4500, 3, 'EST-B-30', 30, 1),
    ('PEC-031', 'Fita Kapton Térmica 10mm x 33m', 12, 'UN', 3000, 4, 'EST-B-31', 30, 1),
    ('PEC-032', 'Fita Dupla Face Fixação de Telas (3mm x 50m)', 12, 'UN', 3500, 2, 'EST-B-32', 30, 1),
    ('PEC-033', 'Fusível de Louça 5A 250V (Pacote c/ 10)', 16, 'PCT', 1800, 5, 'EST-F-33', 90, 1),
    ('PEC-034', 'Capacitor Eletrolítico 1000uF x 25V', 16, 'UN', 500, 38, 'EST-F-34', 90, 1);

-- Compras com NF: cada item gera um movimento ENTRADA (custo medio ponderado)
INSERT INTO compra (id, id_fornecedor, numero_nf, data_compra, id_funcionario)
VALUES (1, 1, 'NF-000451', date('now','localtime','-30 days'), 1);
INSERT INTO compra_item (id_compra, id_peca, quantidade, custo_unitario, preco_venda_sugerido) VALUES
    (1, (SELECT id FROM peca WHERE sku = 'PEC-001'), 15, 14000, 26000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-002'), 20, 11000, 21000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-003'), 12, 9000, 17000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-004'), 8, 18000, 32000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-005'), 25, 2500, 6000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-006'), 6, 19000, 34000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-007'), 30, 800, 2500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-008'), 10, 4500, 9500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-009'), 50, 300, 1500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-010'), 5, 28000, 48000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-029'), 3, 8500, 15000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-030'), 12, 2200, 4500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-031'), 15, 1200, 3000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-032'), 10, 1500, 3500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-033'), 20, 500, 1800),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-034'), 150, 80, 500);

INSERT INTO compra (id, id_fornecedor, numero_nf, data_compra, id_funcionario)
VALUES (2, 2, 'NF-008812', date('now','localtime','-20 days'), 1);
INSERT INTO compra_item (id_compra, id_peca, quantidade, custo_unitario, preco_venda_sugerido) VALUES
    (2, (SELECT id FROM peca WHERE sku = 'PEC-011'), 4, 18000, 35000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-012'), 6, 16000, 31000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-013'), 5, 14000, 28000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-014'), 8, 7500, 16000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-015'), 7, 6000, 13000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-016'), 6, 5500, 12000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-017'), 100, 250, 2000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-018'), 100, 150, 1500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-019'), 10, 1800, 5500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-020'), 4, 4000, 11000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-021'), 3, 6500, 14000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-022'), 40, 500, 2500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-023'), 4, 11000, 23000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-024'), 5, 9500, 19500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-025'), 2, 16000, 31000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-026'), 2, 21000, 42000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-027'), 8, 2200, 6500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-028'), 15, 400, 2000);

-- Clientes PF e PJ (criados pela atendente Juliana, id 2)
INSERT INTO cliente (id, tipo_pessoa, nome, documento, data_nascimento, aceita_comunicacao, criado_por) VALUES
    (1, 'PF', 'Ana Paula Ribeiro',            '52998224725', '1988-03-14', 1, 2),
    (2, 'PF', 'Bruno Henrique Lima',          '11144477735', '1995-11-02', 1, 2),
    (3, 'PF', 'Carla Mendes Oliveira',        '39053344705', '1979-07-27', 0, 2),
    (4, 'PJ', 'Padaria Pão Quente Ltda',      '11222333000181', NULL,      1, 2),
    (5, 'PJ', 'Contábil Alfa Serviços ME',    '45723174000110', NULL,      1, 3);

INSERT INTO cliente_contato (id_cliente, tipo, valor, principal, criado_por) VALUES
    (1, 'CELULAR',  '11988880001', 1, 2),
    (1, 'EMAIL',    'ana.ribeiro@example.com', 1, 2),
    (1, 'WHATSAPP', '11988880001', 1, 2),
    (2, 'CELULAR',  '11988880002', 1, 2),
    (2, 'EMAIL',    'bruno.lima@example.com', 1, 2),
    (3, 'CELULAR',  '11988880003', 1, 2),
    (3, 'TELEFONE', '1133220003',  1, 2),
    (4, 'TELEFONE', '1133220004',  1, 2),
    (4, 'EMAIL',    'contato@paoquente.example.com', 1, 2),
    (5, 'CELULAR',  '11988880005', 1, 3),
    (5, 'EMAIL',    'financeiro@contabilalfa.example.com', 1, 3);

INSERT INTO cliente_endereco (id_cliente, cep, logradouro, numero, complemento, bairro, cidade, uf, principal, criado_por) VALUES
    (1, '01310100', 'Avenida Paulista',     '1000', 'Apto 52', 'Bela Vista',  'São Paulo',      'SP', 1, 2),
    (2, '30140071', 'Rua da Bahia',         '250',  NULL,      'Centro',      'Belo Horizonte', 'MG', 1, 2),
    (3, '80010000', 'Rua XV de Novembro',   '88',   'Sala 3',  'Centro',      'Curitiba',       'PR', 1, 2),
    (4, '20040020', 'Rua da Assembleia',    '45',   NULL,      'Centro',      'Rio de Janeiro', 'RJ', 1, 2),
    (5, '40020000', 'Avenida Sete de Setembro', '900', 'Conj. 12', 'Comércio', 'Salvador',      'BA', 1, 3);

-- Equipamentos (celulares com IMEI valido pelo algoritmo de Luhn)
INSERT INTO equipamento (id, id_cliente, id_modelo, numero_serie, imei, cor, observacao, criado_por) VALUES
    (1, 1, 1, 'F2LXK1ABC123',  '353321101234568', 'Preto',   'Tela trincada',                 2),
    (2, 2, 2, NULL,            '356945087654329', 'Azul',    NULL,                            2),
    (3, 3, 3, 'ZY22-MG84-0192', '351209076543216', 'Grafite', NULL,                           2),
    (4, 4, 5, 'DL15-7788221',  NULL,         'Prata',   'Notebook do caixa',             3),
    (5, 1, 7, 'TVSAM50-001928', NULL,        'Preto',   NULL,                            2),
    (6, 2, 9, 'PS5-0099321',   NULL,         'Branco',  'Edição com leitor de disco',    2),
    (7, 5, 4, NULL,            '864523041122330', 'Cinza',   NULL,                            3),
    (8, 5, 6, 'LNV-IP3-55120', NULL,         'Cinza',   'Notebook do escritório',        3);

-- =============================================================================
-- ORDENS DE SERVICO (percorrem a maquina de estados pelos triggers)
-- =============================================================================

-- OS 1: ENTREGUE, pagamento dividido (Pix + Credito 3x), com garantia
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (1, 1, 1, 2, 4, 'ALTA', 'Tela quebrada após queda; touch sem resposta', 'Capa e carregador', datetime('now','localtime','-5 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 1, 2, 4, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (1, 50000, date('now','localtime','+7 days'), 2);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'WHATSAPP'
 WHERE id_os = 1 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 2, 3, 2, 'Orçamento aprovado pelo cliente via WhatsApp');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 3, 4, 4, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 1, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-006';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 1, id, 4, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-011';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 4, 5, 4, 'Reparo concluído');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (1, 2, 20000, 1, 2);
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (1, 4, 30000, 3, 2);
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 5, 6, 2, 'Entregue ao cliente');

-- OS 2: EM_REPARO, com peca lancada por engano e ESTORNADA (estoque devolvido)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (2, 2, 2, 3, 5, 'NORMAL', 'Tela trincada e bateria viciada', 'Sem acessórios', datetime('now','localtime','-3 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 1, 2, 5, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (2, 46000, date('now','localtime','+7 days'), 3);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'TELEFONE'
 WHERE id_os = 2 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 2, 3, 3, 'Orçamento aprovado por telefone');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 3, 4, 5, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 2, id, 5, 1, preco_base FROM servico WHERE codigo = 'SRV-006';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 2, id, 5, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-012';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 2, id, 5, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-015';
UPDATE os_peca SET estornado = 1, motivo_estorno = 'Peça lançada por engano (bateria de outro modelo)'
 WHERE id_os = 2 AND id_peca = (SELECT id FROM peca WHERE sku = 'PEC-015');

-- OS 3: aguardando ORCAMENTO (em diagnostico, orcamento PENDENTE)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (3, 3, 3, 2, 6, 'NORMAL', 'Não carrega; conector de carga parece danificado', NULL, datetime('now','localtime','-1 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (3, 1, 2, 6, 'Diagnóstico iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 3, id, 6, 1, preco_base FROM servico WHERE codigo = 'SRV-009';
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (3, 13000, date('now','localtime','+7 days'), 2);

-- OS 4: ABERTA (sem tecnico)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (4, 4, 4, 3, NULL, 'URGENTE', 'Notebook muito lento e superaquecendo no caixa', 'Carregador', datetime('now','localtime','-0 days'), date('now','localtime','+1 days'));

-- OS 5: CANCELADA
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (5, 5, 7, 2, NULL, 'BAIXA', 'Câmera traseira com foco falhando', NULL, datetime('now','localtime','-6 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (5, 1, 7, 2, 'Cliente desistiu do reparo');

-- OS 6: PRONTA, com DESCONTO concedido pelo gerente (id 1) e pagamento parcial
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (6, 1, 5, 2, 6, 'ALTA', 'TV sem imagem (som normal); suspeita de barras de LED', NULL, datetime('now','localtime','-7 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 1, 2, 6, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (6, 58000, date('now','localtime','+7 days'), 2);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'PRESENCIAL'
 WHERE id_os = 6 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 2, 3, 2, 'Orçamento aprovado presencialmente');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 3, 4, 6, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 6, id, 6, 1, preco_base FROM servico WHERE codigo = 'SRV-010';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 6, id, 6, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-023';
UPDATE ordem_servico SET desconto = 3000, atualizado_por = 1 WHERE id = 6;
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 4, 5, 6, 'Reparo concluído; aguardando retirada e pagamento');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (6, 1, 20000, 1, 3);

-- OS 7: ENTREGUE (2 servicos + 1 peca), pagamento no debito, com garantia
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (7, 5, 8, 3, 4, 'NORMAL', 'Windows corrompido e notebook muito lento', 'Carregador de fábrica', datetime('now','localtime','-4 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 1, 2, 4, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (7, 41000, date('now','localtime','+7 days'), 3);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'EMAIL'
 WHERE id_os = 7 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 2, 3, 3, 'Orçamento aprovado por e-mail');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 3, 4, 4, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 7, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-001';
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 7, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-003';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 7, id, 4, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-002';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 4, 5, 4, 'Reparo concluído');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (7, 3, 41000, 1, 3);
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 5, 6, 3, 'Entregue ao cliente');

-- Descarte e ajuste de inventario (kardex)
INSERT INTO movimento_estoque
    (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
     custo_medio_anterior, custo_medio_posterior, motivo, id_funcionario)
SELECT id, 'DESCARTE', 2, custo_medio, estoque_atual, estoque_atual - 2, custo_medio, custo_medio,
       'Cabos SATA com defeito de fábrica descartados', 1
  FROM peca WHERE sku = 'PEC-009';

INSERT INTO movimento_estoque
    (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
     custo_medio_anterior, custo_medio_posterior, motivo, id_funcionario)
SELECT id, 'AJUSTE_ENTRADA', 3, custo_medio, estoque_atual, estoque_atual + 3, custo_medio, custo_medio,
       'Inventário: capacitores encontrados na prateleira B', 1
  FROM peca WHERE sku = 'PEC-034';

PRAGMA user_version = 3;
