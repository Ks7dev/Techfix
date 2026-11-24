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
