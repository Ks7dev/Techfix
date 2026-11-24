-- TechFix - Banco de Entrega
-- Parte 1: tabelas (18, todas STRICT). Valores monetários em CENTAVOS (INTEGER).
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------
-- 1. cargo
-- ---------------------------------------------------------------
CREATE TABLE cargo (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_cargo TEXT    NOT NULL COLLATE NOCASE UNIQUE,                 -- nome de cargo único
    status     INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1))
) STRICT;

-- ---------------------------------------------------------------
-- 2. funcionario
-- ---------------------------------------------------------------
CREATE TABLE funcionario (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_funcionario TEXT    NOT NULL COLLATE NOCASE,
    id_cargo         INTEGER NOT NULL,
    status           INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    -- sem ON DELETE CASCADE: apagar cargo não apaga funcionários
    FOREIGN KEY (id_cargo) REFERENCES cargo (id) ON UPDATE CASCADE,
    UNIQUE (id, id_cargo)   -- alvo da FK composta usada pelas demais tabelas
) STRICT;

-- ---------------------------------------------------------------
-- 3. cliente (cadastrado por Gerente ou Atendente)
-- ---------------------------------------------------------------
CREATE TABLE cliente (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_cliente         TEXT    NOT NULL COLLATE NOCASE,
    cpf                  TEXT    NOT NULL UNIQUE
                         CHECK (length(cpf) = 11 AND cpf NOT GLOB '*[^0-9]*'),  -- 11 dígitos
    telefone             TEXT    NOT NULL CHECK (length(trim(telefone)) > 0),   -- RF02: contato para notificação
    email                TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,2)),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 4. categoria (somente Gerente)
-- ---------------------------------------------------------------
CREATE TABLE categoria (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome                 TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo = 1),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 5. servico (singular; somente Gerente)
-- ---------------------------------------------------------------
CREATE TABLE servico (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome                 TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_categoria         INTEGER NOT NULL,
    preco                INTEGER NOT NULL CHECK (preco >= 0),
    horas_trabalho       REAL    NOT NULL CHECK (horas_trabalho > 0),
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo = 1),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 6. marca
-- ---------------------------------------------------------------
CREATE TABLE marca (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_marca           TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,2)),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 7. tipo
-- ---------------------------------------------------------------
CREATE TABLE tipo (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome_tipo            TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,2)),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 8. modelo
-- ---------------------------------------------------------------
CREATE TABLE modelo (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    id_marca             INTEGER NOT NULL,                              -- modelo pertence a uma marca
    nome_modelo          TEXT    NOT NULL COLLATE NOCASE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,2)),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_marca) REFERENCES marca (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo),
    UNIQUE (id_marca, nome_modelo)                                      -- modelo único por marca
) STRICT;

-- ---------------------------------------------------------------
-- 9. equipamento
-- ---------------------------------------------------------------
CREATE TABLE equipamento (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    id_cliente           INTEGER NOT NULL,
    id_modelo            INTEGER NOT NULL,   -- a marca vem do modelo (sem id_marca duplicado)
    id_tipo              INTEGER NOT NULL,
    numero_serie         TEXT    COLLATE NOCASE UNIQUE                  -- número de série único
                         CHECK (numero_serie IS NULL OR length(trim(numero_serie)) > 0),
    imei                 TEXT    UNIQUE
                         CHECK (imei IS NULL OR (length(imei) = 15 AND imei NOT GLOB '*[^0-9]*')),  -- IMEI: 15 dígitos
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,2)),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_cliente) REFERENCES cliente (id),
    FOREIGN KEY (id_modelo)  REFERENCES modelo (id),
    FOREIGN KEY (id_tipo)    REFERENCES tipo (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo),
    CHECK (numero_serie IS NOT NULL OR imei IS NOT NULL)                -- exige série ou IMEI
) STRICT;

-- ---------------------------------------------------------------
-- 10. peca (somente Gerente). O estoque só muda por triggers.
-- ---------------------------------------------------------------
CREATE TABLE peca (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome                 TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_categoria         INTEGER NOT NULL,
    preco_compra         INTEGER NOT NULL CHECK (preco_compra >= 0),
    preco_venda          INTEGER NOT NULL CHECK (preco_venda >= 0),
    estoque_atual        INTEGER NOT NULL DEFAULT 0 CHECK (estoque_atual >= 0),  -- RN03: estoque nunca negativo
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo = 1),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_categoria) REFERENCES categoria (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 11. situacao: somente os 7 status de OS (RF07)
-- ---------------------------------------------------------------
CREATE TABLE situacao (                                                 -- somente os 7 status do RF07
    id     INTEGER PRIMARY KEY AUTOINCREMENT CHECK (id BETWEEN 1 AND 7),
    nome   TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    status INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1))
) STRICT;

-- ---------------------------------------------------------------
-- 12. forma_pagamento (somente Gerente)
-- ---------------------------------------------------------------
CREATE TABLE forma_pagamento (                                          -- tabela STRICT
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome                 TEXT    NOT NULL COLLATE NOCASE UNIQUE,
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo = 1),
    status               INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1)),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 13. ordem (OS)
-- ---------------------------------------------------------------
CREATE TABLE ordem (
    id                            INTEGER PRIMARY KEY AUTOINCREMENT,
    id_equipamento                INTEGER NOT NULL,
    defeito_relatado              TEXT    NOT NULL COLLATE NOCASE,
    defeito_constatado            TEXT    DEFAULT '' COLLATE NOCASE,
    id_situacao                   INTEGER NOT NULL DEFAULT 1,            -- situação atual (mantida pelo histórico)
    data_abertura                 TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    data_fechamento               TEXT,                                  -- preenchida por trigger
    valor_total                   INTEGER NOT NULL DEFAULT 0 CHECK (valor_total >= 0),  -- nunca NULL, recalculado por trigger
    id_forma_pagamento            INTEGER,                               -- opcional até a entrega
    id_funcionario_abertura       INTEGER NOT NULL,
    id_funcionario_cargo_abertura INTEGER NOT NULL CHECK (id_funcionario_cargo_abertura IN (1,2)),
    id_tecnico                    INTEGER,                               -- opcional na abertura
    id_tecnico_cargo              INTEGER CHECK (id_tecnico_cargo = 3),
    FOREIGN KEY (id_equipamento)     REFERENCES equipamento (id),
    FOREIGN KEY (id_situacao)        REFERENCES situacao (id),
    FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento (id),
    FOREIGN KEY (id_funcionario_abertura, id_funcionario_cargo_abertura) REFERENCES funcionario (id, id_cargo),
    FOREIGN KEY (id_tecnico, id_tecnico_cargo) REFERENCES funcionario (id, id_cargo),
    CHECK ((id_tecnico IS NULL) = (id_tecnico_cargo IS NULL)),
    CHECK (id_situacao <> 6 OR id_forma_pagamento IS NOT NULL),          -- RN04: Entregue exige pagamento
    CHECK ((id_situacao IN (6,7)) = (data_fechamento IS NOT NULL))       -- fechamento coerente com a situação
) STRICT;

-- ---------------------------------------------------------------
-- 14. ordem_situacao (histórico de situações)
-- ---------------------------------------------------------------
CREATE TABLE ordem_situacao (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    id_ordem         INTEGER NOT NULL,
    id_nova_situacao INTEGER NOT NULL,
    id_funcionario   INTEGER NOT NULL,
    data_situacao    TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_ordem)         REFERENCES ordem (id),
    FOREIGN KEY (id_nova_situacao) REFERENCES situacao (id),
    FOREIGN KEY (id_funcionario)   REFERENCES funcionario (id)
) STRICT;

-- ---------------------------------------------------------------
-- 15. ordem_servico (serviços da OS, preço congelado)
-- ---------------------------------------------------------------
CREATE TABLE ordem_servico (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    id_ordem        INTEGER NOT NULL,
    id_servico      INTEGER NOT NULL,
    preco_praticado INTEGER NOT NULL CHECK (preco_praticado >= 0),
    quantidade      INTEGER NOT NULL CHECK (quantidade > 0),             -- quantidade positiva
    data_execucao   TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_ordem)   REFERENCES ordem (id),
    FOREIGN KEY (id_servico) REFERENCES servico (id)
) STRICT;

-- ---------------------------------------------------------------
-- 16. ordem_peca (peças usadas na OS; baixa o estoque)
-- ---------------------------------------------------------------
CREATE TABLE ordem_peca (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    id_ordem         INTEGER NOT NULL,
    id_peca          INTEGER NOT NULL,
    preco            INTEGER NOT NULL CHECK (preco >= 0),
    quantidade       INTEGER NOT NULL CHECK (quantidade > 0),            -- quantidade positiva
    id_tecnico       INTEGER NOT NULL,                                   -- validado contra o técnico da OS
    id_tecnico_cargo INTEGER NOT NULL CHECK (id_tecnico_cargo = 3),
    data_saida       TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_ordem) REFERENCES ordem (id),
    FOREIGN KEY (id_peca)  REFERENCES peca (id),
    FOREIGN KEY (id_tecnico, id_tecnico_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 17. entrada_peca (compra/reposição; soma o estoque)
-- ---------------------------------------------------------------
CREATE TABLE entrada_peca (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    id_peca              INTEGER NOT NULL,
    preco_compra         INTEGER NOT NULL CHECK (preco_compra >= 0),
    preco_venda_sugerido INTEGER NOT NULL CHECK (preco_venda_sugerido >= 0),  -- RF09: preço sugerido de venda
    quantidade           INTEGER NOT NULL CHECK (quantidade > 0),             -- quantidade positiva
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo = 1),
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_peca) REFERENCES peca (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;

-- ---------------------------------------------------------------
-- 18. saida_peca (SOMENTE descarte; subtrai o estoque)
-- ---------------------------------------------------------------
CREATE TABLE saida_peca (
    id                   INTEGER PRIMARY KEY AUTOINCREMENT,
    id_peca              INTEGER NOT NULL,
    preco                INTEGER NOT NULL CHECK (preco >= 0),
    quantidade           INTEGER NOT NULL CHECK (quantidade > 0),             -- quantidade positiva
    motivo               TEXT    NOT NULL CHECK (length(trim(motivo)) > 0),   -- motivo é texto livre, não situação
    id_funcionario       INTEGER NOT NULL,
    id_funcionario_cargo INTEGER NOT NULL CHECK (id_funcionario_cargo IN (1,3)),  -- técnico ou gerente
    data_cadastro        TEXT    NOT NULL DEFAULT (datetime('now','localtime')),
    FOREIGN KEY (id_peca) REFERENCES peca (id),
    FOREIGN KEY (id_funcionario, id_funcionario_cargo) REFERENCES funcionario (id, id_cargo)
) STRICT;
