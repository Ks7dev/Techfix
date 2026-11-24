-- =====================================================================
-- TechFix - Banco de Entrega - script completo
-- Este arquivo reúne 01_tabelas.sql, 02_regras.sql, 03_views.sql e
-- 04_dados.sql em um único script.
--
-- COMO EXECUTAR
--   DB Browser for SQLite: crie um banco novo (File > New Database), cancele o
--     assistente de tabela, abra a aba "Execute SQL", cole/abra este arquivo,
--     execute tudo (Ctrl+Enter) e grave (Ctrl+S).
--   SQLiteStudio: crie um banco, abra o Editor SQL, carregue este arquivo e
--     execute (F9).
--   sqlite3:  sqlite3 techfix.sqlite < techfix_entrega_completo.sql
--
-- O script apaga e recria tudo (bloco de limpeza), então pode rodar de novo.
-- Valores monetários são INTEIROS em CENTAVOS (R$ 150,00 = 15000).
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------
-- Limpeza (permite executar o script mais de uma vez)
-- ---------------------------------------------------------------
PRAGMA foreign_keys = OFF;
DROP VIEW IF EXISTS vw_preco_venda_maior_100;
DROP VIEW IF EXISTS vw_estoque_baixo;
DROP VIEW IF EXISTS vw_ordem_resumo;
DROP TRIGGER IF EXISTS trg_ordem_situacao_imutavel_delete;
DROP TRIGGER IF EXISTS trg_ordem_situacao_imutavel_update;
DROP TRIGGER IF EXISTS trg_saida_peca_imutavel_delete;
DROP TRIGGER IF EXISTS trg_saida_peca_imutavel_update;
DROP TRIGGER IF EXISTS trg_entrada_peca_imutavel_delete;
DROP TRIGGER IF EXISTS trg_entrada_peca_imutavel_update;
DROP TRIGGER IF EXISTS trg_ordem_peca_imutavel_delete;
DROP TRIGGER IF EXISTS trg_ordem_peca_imutavel_update;
DROP TRIGGER IF EXISTS trg_ordem_servico_imutavel_delete;
DROP TRIGGER IF EXISTS trg_ordem_servico_imutavel_update;
DROP TRIGGER IF EXISTS trg_ordem_situacao_atualiza;
DROP TRIGGER IF EXISTS trg_ordem_situacao_valida;
DROP TRIGGER IF EXISTS trg_ordem_encerrada_imutavel;
DROP TRIGGER IF EXISTS trg_ordem_historico_inicial;
DROP TRIGGER IF EXISTS trg_ordem_nova_valida;
DROP TRIGGER IF EXISTS trg_ordem_servico_total;
DROP TRIGGER IF EXISTS trg_ordem_servico_valida;
DROP TRIGGER IF EXISTS trg_saida_peca_estoque;
DROP TRIGGER IF EXISTS trg_saida_peca_valida;
DROP TRIGGER IF EXISTS trg_ordem_peca_estoque_total;
DROP TRIGGER IF EXISTS trg_ordem_peca_valida;
DROP TRIGGER IF EXISTS trg_entrada_peca_estoque;
DROP TABLE IF EXISTS saida_peca;
DROP TABLE IF EXISTS entrada_peca;
DROP TABLE IF EXISTS ordem_peca;
DROP TABLE IF EXISTS ordem_servico;
DROP TABLE IF EXISTS ordem_situacao;
DROP TABLE IF EXISTS ordem;
DROP TABLE IF EXISTS forma_pagamento;
DROP TABLE IF EXISTS situacao;
DROP TABLE IF EXISTS peca;
DROP TABLE IF EXISTS equipamento;
DROP TABLE IF EXISTS modelo;
DROP TABLE IF EXISTS tipo;
DROP TABLE IF EXISTS marca;
DROP TABLE IF EXISTS servico;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS funcionario;
DROP TABLE IF EXISTS cargo;
PRAGMA foreign_keys = ON;

-- =====================================================================
-- 1. TABELAS
-- =====================================================================
-- TechFix - Banco de Entrega
-- Parte 1: tabelas (18, todas STRICT). Valores monetários em CENTAVOS (INTEGER).

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

-- =====================================================================
-- 2. REGRAS (TRIGGERS)
-- =====================================================================
-- TechFix - Banco de Entrega
-- Parte 2: regras de negócio (triggers). Mensagens de erro em português.

-- ===============================================================
-- Estoque: entrada soma
-- ===============================================================
CREATE TRIGGER trg_entrada_peca_estoque
AFTER INSERT ON entrada_peca
BEGIN
    UPDATE peca SET estoque_atual = estoque_atual + NEW.quantidade WHERE id = NEW.id_peca;
END;

-- ===============================================================
-- Uso de peça na OS: RN01, técnico da OS e RN03
-- ===============================================================
CREATE TRIGGER trg_ordem_peca_valida
BEFORE INSERT ON ordem_peca
BEGIN
    SELECT RAISE(ABORT, 'RN01: peça só pode ser usada em OS "Orçamento Aprovado" ou "Em Reparo"')
    WHERE COALESCE((SELECT id_situacao FROM ordem WHERE id = NEW.id_ordem), 0) NOT IN (3, 4);

    SELECT RAISE(ABORT, 'O técnico da peça deve ser o técnico responsável pela OS')
    WHERE (SELECT id_tecnico FROM ordem WHERE id = NEW.id_ordem) IS NOT NEW.id_tecnico;

    SELECT RAISE(ABORT, 'RN03: estoque insuficiente para esta peça')
    WHERE COALESCE((SELECT estoque_atual FROM peca WHERE id = NEW.id_peca), 0) < NEW.quantidade;
END;

CREATE TRIGGER trg_ordem_peca_estoque_total
AFTER INSERT ON ordem_peca
BEGIN
    UPDATE peca SET estoque_atual = estoque_atual - NEW.quantidade WHERE id = NEW.id_peca;
    UPDATE ordem SET valor_total =
          COALESCE((SELECT SUM(preco_praticado * quantidade) FROM ordem_servico WHERE id_ordem = NEW.id_ordem), 0)
        + COALESCE((SELECT SUM(preco * quantidade) FROM ordem_peca WHERE id_ordem = NEW.id_ordem), 0)
    WHERE id = NEW.id_ordem;
END;

-- ===============================================================
-- Descarte (saida_peca): RN03 e baixa do estoque
-- ===============================================================
CREATE TRIGGER trg_saida_peca_valida
BEFORE INSERT ON saida_peca
BEGIN
    SELECT RAISE(ABORT, 'RN03: estoque insuficiente para o descarte')
    WHERE COALESCE((SELECT estoque_atual FROM peca WHERE id = NEW.id_peca), 0) < NEW.quantidade;
END;

CREATE TRIGGER trg_saida_peca_estoque
AFTER INSERT ON saida_peca
BEGIN
    UPDATE peca SET estoque_atual = estoque_atual - NEW.quantidade WHERE id = NEW.id_peca;
END;

-- ===============================================================
-- Serviços da OS: OS aberta e total recalculado
-- ===============================================================
CREATE TRIGGER trg_ordem_servico_valida
BEFORE INSERT ON ordem_servico
BEGIN
    SELECT RAISE(ABORT, 'OS encerrada (Entregue ou Cancelado) não aceita novos serviços')
    WHERE COALESCE((SELECT id_situacao FROM ordem WHERE id = NEW.id_ordem), 0) IN (0, 6, 7);
END;

CREATE TRIGGER trg_ordem_servico_total
AFTER INSERT ON ordem_servico
BEGIN
    UPDATE ordem SET valor_total =
          COALESCE((SELECT SUM(preco_praticado * quantidade) FROM ordem_servico WHERE id_ordem = NEW.id_ordem), 0)
        + COALESCE((SELECT SUM(preco * quantidade) FROM ordem_peca WHERE id_ordem = NEW.id_ordem), 0)
    WHERE id = NEW.id_ordem;
END;

-- ===============================================================
-- Ordem: nasce Aberta, histórico inicial, OS encerrada não muda
-- ===============================================================
CREATE TRIGGER trg_ordem_nova_valida
BEFORE INSERT ON ordem
BEGIN
    SELECT RAISE(ABORT, 'Toda OS nova deve nascer "Aberto", sem data de fechamento')
    WHERE NEW.id_situacao <> 1 OR NEW.data_fechamento IS NOT NULL;
END;

CREATE TRIGGER trg_ordem_historico_inicial
AFTER INSERT ON ordem
BEGIN
    INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao)
    VALUES (NEW.id, 1, NEW.id_funcionario_abertura, NEW.data_abertura);
END;

CREATE TRIGGER trg_ordem_encerrada_imutavel
BEFORE UPDATE ON ordem
WHEN OLD.id_situacao IN (6, 7)
BEGIN
    SELECT RAISE(ABORT, 'OS encerrada (Entregue ou Cancelado) não pode mais ser alterada');
END;

CREATE TRIGGER trg_ordem_situacao_valida
BEFORE INSERT ON ordem_situacao
BEGIN
    SELECT RAISE(ABORT, 'OS encerrada (Entregue ou Cancelado) não pode mudar de situação')
    WHERE COALESCE((SELECT id_situacao FROM ordem WHERE id = NEW.id_ordem), 0) IN (6, 7);

    SELECT RAISE(ABORT, 'RN04: para marcar "Entregue" a OS precisa ter forma de pagamento')
    WHERE NEW.id_nova_situacao = 6
      AND (SELECT id_forma_pagamento FROM ordem WHERE id = NEW.id_ordem) IS NULL;
END;

CREATE TRIGGER trg_ordem_situacao_atualiza
AFTER INSERT ON ordem_situacao
BEGIN
    UPDATE ordem
       SET id_situacao     = NEW.id_nova_situacao,
           data_fechamento = CASE WHEN NEW.id_nova_situacao IN (6, 7) THEN NEW.data_situacao END
     WHERE id = NEW.id_ordem;
END;

-- ===============================================================
-- RN02: itens, movimentos e histórico são imutáveis
-- ===============================================================
CREATE TRIGGER trg_ordem_servico_imutavel_update BEFORE UPDATE ON ordem_servico
BEGIN SELECT RAISE(ABORT, 'RN02: serviços da OS não podem ser alterados'); END;
CREATE TRIGGER trg_ordem_servico_imutavel_delete BEFORE DELETE ON ordem_servico
BEGIN SELECT RAISE(ABORT, 'RN02: serviços da OS não podem ser excluídos'); END;

CREATE TRIGGER trg_ordem_peca_imutavel_update BEFORE UPDATE ON ordem_peca
BEGIN SELECT RAISE(ABORT, 'RN02: peças da OS não podem ser alteradas'); END;
CREATE TRIGGER trg_ordem_peca_imutavel_delete BEFORE DELETE ON ordem_peca
BEGIN SELECT RAISE(ABORT, 'RN02: peças da OS não podem ser excluídas'); END;

CREATE TRIGGER trg_entrada_peca_imutavel_update BEFORE UPDATE ON entrada_peca
BEGIN SELECT RAISE(ABORT, 'RN02: entradas de peça não podem ser alteradas'); END;
CREATE TRIGGER trg_entrada_peca_imutavel_delete BEFORE DELETE ON entrada_peca
BEGIN SELECT RAISE(ABORT, 'RN02: entradas de peça não podem ser excluídas'); END;

CREATE TRIGGER trg_saida_peca_imutavel_update BEFORE UPDATE ON saida_peca
BEGIN SELECT RAISE(ABORT, 'RN02: descartes não podem ser alterados'); END;
CREATE TRIGGER trg_saida_peca_imutavel_delete BEFORE DELETE ON saida_peca
BEGIN SELECT RAISE(ABORT, 'RN02: descartes não podem ser excluídos'); END;

CREATE TRIGGER trg_ordem_situacao_imutavel_update BEFORE UPDATE ON ordem_situacao
BEGIN SELECT RAISE(ABORT, 'RN02: o histórico de situações não pode ser alterado'); END;
CREATE TRIGGER trg_ordem_situacao_imutavel_delete BEFORE DELETE ON ordem_situacao
BEGIN SELECT RAISE(ABORT, 'RN02: o histórico de situações não pode ser excluído'); END;

-- =====================================================================
-- 3. VIEWS
-- =====================================================================
-- TechFix - Banco de Entrega
-- Parte 3: views

CREATE VIEW vw_ordem_resumo AS
SELECT o.id                  AS id_ordem,
       c.nome_cliente        AS cliente,
       t.nome_tipo           AS tipo,
       ma.nome_marca         AS marca,
       m.nome_modelo         AS modelo,
       s.nome                AS situacao,
       tec.nome_funcionario  AS tecnico,
       o.valor_total         AS valor_total,
       fp.nome               AS forma_pagamento,
       o.data_abertura       AS data_abertura,
       o.data_fechamento     AS data_fechamento
FROM ordem o
JOIN equipamento e ON e.id = o.id_equipamento
JOIN cliente c     ON c.id = e.id_cliente
JOIN modelo m      ON m.id = e.id_modelo
JOIN marca ma      ON ma.id = m.id_marca
JOIN tipo t        ON t.id = e.id_tipo
JOIN situacao s    ON s.id = o.id_situacao
LEFT JOIN funcionario tec    ON tec.id = o.id_tecnico
LEFT JOIN forma_pagamento fp ON fp.id = o.id_forma_pagamento;

CREATE VIEW vw_estoque_baixo AS
SELECT id, nome, estoque_atual
FROM peca
WHERE estoque_atual <= 5
ORDER BY estoque_atual, nome;

CREATE VIEW vw_preco_venda_maior_100 AS
SELECT id, nome, preco_venda, estoque_atual
FROM peca
WHERE preco_venda > 10000;   -- valores em centavos: acima de R$ 100,00

-- =====================================================================
-- 4. DADOS INICIAIS
-- =====================================================================
-- TechFix - Banco de Entrega
-- Parte 4: dados iniciais.
-- Valores em centavos. NÃO se escreve valor_total, estoque_atual nem data_fechamento:
-- os triggers calculam. Funcionários: 1-3 Técnicos, 4-5 Atendentes, 6-7 Gerentes.

-- ---------------------------------------------------------------
-- Cargos e funcionários
-- ---------------------------------------------------------------
INSERT INTO cargo (nome_cargo) VALUES ('Gerente'), ('Atendente'), ('Técnico');

INSERT INTO funcionario (nome_funcionario, id_cargo) VALUES
    ('Carlos Almeida',  3),   -- 1 Técnico
    ('Marcos Oliveira', 3),   -- 2 Técnico
    ('Rafael Santos',   3),   -- 3 Técnico
    ('Ana Paula Silva', 2),   -- 4 Atendente
    ('Juliana Costa',   2),   -- 5 Atendente
    ('Roberto Martins', 1),   -- 6 Gerente
    ('Silas Camus',     1);   -- 7 Gerente

-- ---------------------------------------------------------------
-- Situações (os 7 status do RF07, nomes padronizados)
-- ---------------------------------------------------------------
INSERT INTO situacao (nome) VALUES
    ('Aberto'), ('Em Diagnóstico'), ('Orçamento Aprovado'), ('Em Reparo'),
    ('Pronto'), ('Entregue'), ('Cancelado');

-- ---------------------------------------------------------------
-- Formas de pagamento (Gerente)
-- ---------------------------------------------------------------
INSERT INTO forma_pagamento (nome, id_funcionario, id_funcionario_cargo) VALUES
    ('Dinheiro', 6, 1),
    ('PIX', 6, 1),
    ('Cartão de Débito', 6, 1),
    ('Cartão de Crédito - À Vista', 6, 1),
    ('Cartão de Crédito - Parcelado', 6, 1),
    ('Boleto Bancário', 6, 1);

-- ---------------------------------------------------------------
-- Clientes (Atendente ou Gerente). CPF só dígitos; telefone obrigatório
-- ---------------------------------------------------------------
INSERT INTO cliente (nome_cliente, cpf, telefone, email, id_funcionario, id_funcionario_cargo) VALUES
    ('João',                     '78264359754', '11987650001', 'joao@gmail.com',              4, 2),
    ('Marcos Vinicius Souza',    '00000000001', '11987650002', 'marcos.souza@email.com',      6, 1),
    ('Fernanda Maria Oliveira',  '00000000002', '11987650003', 'fernanda.oliveira@email.com', 6, 1),
    ('Roberto Carlos Andrade',   '00000000003', '11987650004', 'roberto.andrade@email.com',   6, 1),
    ('Camila de Cassia Martins', '00000000004', '11987650005', 'camila.martins@email.com',    6, 1),
    ('Patricia Ferreira Lima',   '00000000005', '11987650006', 'patricia.lima@email.com',     6, 1),
    ('Lucas Gabriel Barbosa',    '00000000006', '11987650007', 'lucas.barbosa@email.com',     6, 1);

-- ---------------------------------------------------------------
-- Categorias (Gerente)
-- ---------------------------------------------------------------
INSERT INTO categoria (nome, id_funcionario, id_funcionario_cargo) VALUES
    ('Computadores', 6, 1), ('Celulares', 7, 1), ('Smart TVs', 7, 1), ('Redes', 6, 1),
    ('Videogames', 6, 1), ('Áudio', 6, 1), ('Recuperação de Dados', 6, 1), ('Eletrônica Avançada', 7, 1),
    ('Informática', 7, 1), ('Insumos', 7, 1), ('Acessórios', 6, 1), ('Telas', 6, 1),
    ('Baterias', 7, 1), ('Componentes', 6, 1), ('Carcaças', 7, 1), ('TVs', 6, 1);

-- ---------------------------------------------------------------
-- Serviços do catálogo (23). Gerente cadastra.
-- ---------------------------------------------------------------
INSERT INTO servico (nome, id_categoria, preco, horas_trabalho, id_funcionario, id_funcionario_cargo) VALUES
    ('Formatação e Instalação de Sistema Operacional', (SELECT id FROM categoria WHERE nome = 'Computadores'), 12000, 2.0, 6, 1),
    ('Limpeza Interna e Troca de Pasta Térmica', (SELECT id FROM categoria WHERE nome = 'Computadores'), 15000, 1.5, 6, 1),
    ('Upgrade de Hardware (RAM/SSD)', (SELECT id FROM categoria WHERE nome = 'Computadores'), 8000, 1.0, 6, 1),
    ('Remoção de Vírus e Malwares', (SELECT id FROM categoria WHERE nome = 'Computadores'), 10000, 1.5, 6, 1),
    ('Troca de Tela de Notebook', (SELECT id FROM categoria WHERE nome = 'Computadores'), 18000, 1.5, 6, 1),
    ('Troca de Display/Frontal de Celular', (SELECT id FROM categoria WHERE nome = 'Celulares'), 15000, 1.0, 6, 1),
    ('Troca de Bateria de Smartphone', (SELECT id FROM categoria WHERE nome = 'Celulares'), 9000, 0.5, 6, 1),
    ('Desoxidação após Contato com Líquido', (SELECT id FROM categoria WHERE nome = 'Celulares'), 20000, 3.0, 6, 1),
    ('Reparo em Conector de Carga (Micro USB / Type-C)', (SELECT id FROM categoria WHERE nome = 'Celulares'), 11000, 1.5, 6, 1),
    ('Troca de Barra de LED de Smart TV', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 35000, 3.0, 6, 1),
    ('Reparo na Placa Principal de Smart TV', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 28000, 2.5, 6, 1),
    ('Conserto de Fonte de Alimentação Interna (TV)', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 22000, 2.0, 6, 1),
    ('Configuração de Rede e Roteador Wi-Fi', (SELECT id FROM categoria WHERE nome = 'Redes'), 9000, 1.0, 6, 1),
    ('Higienização e Troca de Metal Líquido / Pasta Térmica (Console)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 22000, 2.0, 6, 1),
    ('Reparo de Drift em Analógico de Controle (Joy-Con / DualSense / Xbox)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 8000, 1.0, 6, 1),
    ('Substituição de HDMI / Conector de Vídeo (Console)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 25000, 2.5, 6, 1),
    ('Troca de Bateria de Caixa de Som Portátil (Bluetooth)', (SELECT id FROM categoria WHERE nome = 'Áudio'), 12000, 1.5, 6, 1),
    ('Troca de Almofadas / Reparo de Cabo de Headset Gamer', (SELECT id FROM categoria WHERE nome = 'Áudio'), 7000, 1.0, 6, 1),
    ('Recuperação de Dados de HD / SSD / Pendrive Danificado', (SELECT id FROM categoria WHERE nome = 'Recuperação de Dados'), 30000, 4.0, 6, 1),
    ('Rebaling / Reparo de BGA em Placa Mãe ou Placa de Vídeo', (SELECT id FROM categoria WHERE nome = 'Eletrônica Avançada'), 45000, 5.0, 6, 1),
    ('Gravação e Reprogramação de BIOS Eprom (Notebook / Desktop)', (SELECT id FROM categoria WHERE nome = 'Eletrônica Avançada'), 16000, 2.0, 6, 1),
    ('Troca de Vidro Traseiro de Smartphone a Laser / Manual', (SELECT id FROM categoria WHERE nome = 'Celulares'), 18000, 2.5, 6, 1),
    ('Reparo e Solda de Conector Jack P2/P10 de Mesa de Som ou Amplificador', (SELECT id FROM categoria WHERE nome = 'Áudio'), 9500, 1.0, 6, 1);

-- ---------------------------------------------------------------
-- Marcas, tipos e modelos (cada modelo pertence a uma marca)
-- ---------------------------------------------------------------
INSERT INTO marca (nome_marca, id_funcionario, id_funcionario_cargo) VALUES
    ('Apple', 6, 1), ('Samsung', 7, 1), ('Motorola', 7, 1), ('Xiaomi', 6, 1),
    ('Dell', 6, 1), ('Lenovo', 7, 1), ('LG', 7, 1), ('Sony', 6, 1);

INSERT INTO tipo (nome_tipo, id_funcionario, id_funcionario_cargo) VALUES
    ('Smartphone', 6, 1),             -- 1
    ('Notebook', 4, 2),               -- 2
    ('Desktop', 5, 2),                -- 3
    ('Smart TV', 5, 2),               -- 4
    ('Console de Videogame', 5, 2),   -- 5
    ('Caixa de Som Bluetooth', 5, 2); -- 6

INSERT INTO modelo (id_marca, nome_modelo, id_funcionario, id_funcionario_cargo) VALUES
    ((SELECT id FROM marca WHERE nome_marca = 'Apple'),    'iPhone 11',              6, 1),  -- 1
    ((SELECT id FROM marca WHERE nome_marca = 'Apple'),    'iPhone 12',              6, 1),  -- 2
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Galaxy A54',             6, 1),  -- 3
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Galaxy A32',             7, 1),  -- 4
    ((SELECT id FROM marca WHERE nome_marca = 'Motorola'), 'Moto G84',               7, 1),  -- 5
    ((SELECT id FROM marca WHERE nome_marca = 'Motorola'), 'Moto G30',               4, 2),  -- 6
    ((SELECT id FROM marca WHERE nome_marca = 'Xiaomi'),   'Redmi Note 11',          4, 2),  -- 7
    ((SELECT id FROM marca WHERE nome_marca = 'Dell'),     'Inspiron 15 3000',       6, 1),  -- 8
    ((SELECT id FROM marca WHERE nome_marca = 'Lenovo'),   'IdeaPad 3',              6, 1),  -- 9
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Smart TV 50 UN50TU8000', 7, 1),  -- 10
    ((SELECT id FROM marca WHERE nome_marca = 'LG'),       'Smart TV 43 43UP7500',   4, 2),  -- 11 (era cadastrado como Samsung/LG trocado)
    ((SELECT id FROM marca WHERE nome_marca = 'Sony'),     'PlayStation 5',          7, 1);  -- 12

-- ---------------------------------------------------------------
-- Equipamentos: série ou IMEI (15 dígitos)
-- ---------------------------------------------------------------
INSERT INTO equipamento (id_cliente, id_modelo, id_tipo, numero_serie, imei, id_funcionario, id_funcionario_cargo) VALUES
    (1, 1,  1, NULL,                  '356789012345671', 6, 1),  -- 1 iPhone 11
    (2, 3,  1, NULL,                  '356789012345672', 6, 1),  -- 2 Galaxy A54
    (3, 8,  2, 'DELL-INSP-2023-998',  NULL,              6, 1),  -- 3 Notebook Dell
    (4, 11, 4, 'LG-TV43-77612',       NULL,              6, 1),  -- 4 Smart TV LG 43
    (5, 12, 5, 'PS5-SONY-009182',     NULL,              6, 1),  -- 5 PlayStation 5
    (6, 5,  1, NULL,                  '356789012345673', 6, 1);  -- 6 Moto G84

-- ---------------------------------------------------------------
-- Peças do catálogo (34), cadastradas com estoque 0. Gerente cadastra.
-- O estoque inicial entra pelas entradas abaixo (trigger soma).
-- ---------------------------------------------------------------
INSERT INTO peca (nome, id_categoria, preco_compra, preco_venda, id_funcionario, id_funcionario_cargo) VALUES
    ('SSD NVMe 512GB M.2', (SELECT id FROM categoria WHERE nome = 'Informática'), 14000, 26000, 7, 1),  -- 1
    ('SSD SATA III 480GB 2.5"', (SELECT id FROM categoria WHERE nome = 'Informática'), 11000, 21000, 7, 1),  -- 2
    ('Memória RAM DDR4 8GB 2666MHz (Notebook)', (SELECT id FROM categoria WHERE nome = 'Informática'), 9000, 17000, 7, 1),  -- 3
    ('Memória RAM DDR4 16GB 3200MHz (Desktop)', (SELECT id FROM categoria WHERE nome = 'Informática'), 18000, 32000, 7, 1),  -- 4
    ('Pasta Térmica de Alta Performance (Bisnaga 4g)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 2500, 6000, 7, 1),  -- 5
    ('Fonte ATX 500W 80 Plus Bronze', (SELECT id FROM categoria WHERE nome = 'Informática'), 19000, 34000, 7, 1),  -- 6
    ('Bateria Célula Moeda CR2032 (Cartela c/ 5)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 800, 2500, 7, 1),  -- 7
    ('Cooler para Processador Socket Universal', (SELECT id FROM categoria WHERE nome = 'Informática'), 4500, 9500, 7, 1),  -- 8
    ('Cabo SATA III 6Gbps 50cm', (SELECT id FROM categoria WHERE nome = 'Acessórios'), 300, 1500, 7, 1),  -- 9
    ('Tela LED 15.6" Slim 30 Pinos Full HD', (SELECT id FROM categoria WHERE nome = 'Telas'), 28000, 48000, 7, 1),  -- 10
    ('Display Frontal Completo iPhone 11', (SELECT id FROM categoria WHERE nome = 'Telas'), 18000, 35000, 7, 1),  -- 11
    ('Display Frontal Completo Samsung Galaxy A54', (SELECT id FROM categoria WHERE nome = 'Telas'), 16000, 31000, 7, 1),  -- 12
    ('Display Frontal Completo Motorola Moto G84', (SELECT id FROM categoria WHERE nome = 'Telas'), 14000, 28000, 7, 1),  -- 13
    ('Bateria Compatível iPhone 11 (3110mAh)', (SELECT id FROM categoria WHERE nome = 'Baterias'), 7500, 16000, 7, 1),  -- 14
    ('Bateria Compatível Samsung Galaxy A32', (SELECT id FROM categoria WHERE nome = 'Baterias'), 6000, 13000, 7, 1),  -- 15
    ('Bateria Compatível Moto G30', (SELECT id FROM categoria WHERE nome = 'Baterias'), 5500, 12000, 7, 1),  -- 16
    ('Conector de Carga Type-C Universal (Unidade)', (SELECT id FROM categoria WHERE nome = 'Componentes'), 250, 2000, 7, 1),  -- 17
    ('Conector de Carga Micro USB V8', (SELECT id FROM categoria WHERE nome = 'Componentes'), 150, 1500, 7, 1),  -- 18
    ('Flex de Carga e Microfone Moto G9 Play', (SELECT id FROM categoria WHERE nome = 'Componentes'), 1800, 5500, 7, 1),  -- 19
    ('Tampa Traseira de Vidro iPhone 12', (SELECT id FROM categoria WHERE nome = 'Carcaças'), 4000, 11000, 7, 1),  -- 20
    ('Câmera Traseira Principal Redmi Note 11', (SELECT id FROM categoria WHERE nome = 'Componentes'), 6500, 14000, 7, 1),  -- 21
    ('Alto-Falante Auricular Universal', (SELECT id FROM categoria WHERE nome = 'Componentes'), 500, 2500, 7, 1),  -- 22
    ('Barra de LED TV Samsung 50" (Kit com 3 barras)', (SELECT id FROM categoria WHERE nome = 'TVs'), 11000, 23000, 7, 1),  -- 23
    ('Barra de LED TV LG 43" (Kit com 3 barras)', (SELECT id FROM categoria WHERE nome = 'TVs'), 9500, 19500, 7, 1),  -- 24
    ('Placa Fonte TV Samsung UN50TU8000', (SELECT id FROM categoria WHERE nome = 'TVs'), 16000, 31000, 7, 1),  -- 25
    ('Placa Principal TV LG 43UP7500', (SELECT id FROM categoria WHERE nome = 'TVs'), 21000, 42000, 7, 1),  -- 26
    ('Cabo Flat T-Con para Display TV 55"', (SELECT id FROM categoria WHERE nome = 'TVs'), 2200, 6500, 7, 1),  -- 27
    ('Receptor Infravermelho para Controle Remoto TV', (SELECT id FROM categoria WHERE nome = 'Componentes'), 400, 2000, 7, 1),  -- 28
    ('Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 8500, 15000, 7, 1),  -- 29
    ('Álcool Isopropílico 99.8% 1 Litro', (SELECT id FROM categoria WHERE nome = 'Insumos'), 2200, 4500, 7, 1),  -- 30
    ('Fita Kapton Térmica 10mm x 33m', (SELECT id FROM categoria WHERE nome = 'Insumos'), 1200, 3000, 7, 1),  -- 31
    ('Fita Dupla Face Fixação de Telas (3mm x 50m)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 1500, 3500, 7, 1),  -- 32
    ('Fusível de Louça 5A 250V (Pacote c/ 10)', (SELECT id FROM categoria WHERE nome = 'Componentes'), 500, 1800, 7, 1),  -- 33
    ('Capacitor Eletrolítico 1000uF x 25V', (SELECT id FROM categoria WHERE nome = 'Componentes'), 80, 500, 7, 1);  -- 34

-- ---------------------------------------------------------------
-- Entradas de peça: estoque inicial do catálogo (quantidade = estoque do catálogo)
-- ---------------------------------------------------------------
INSERT INTO entrada_peca (id_peca, preco_compra, preco_venda_sugerido, quantidade, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (1, 14000, 26000, 15, 7, 1, '2026-08-25 08:00:00'),  -- SSD NVMe 512GB M.2
    (2, 11000, 21000, 20, 7, 1, '2026-08-25 08:00:00'),  -- SSD SATA III 480GB 2.5"
    (3, 9000, 17000, 12, 7, 1, '2026-08-25 08:00:00'),  -- Memória RAM DDR4 8GB 2666MHz (Notebook)
    (4, 18000, 32000, 8, 7, 1, '2026-08-25 08:00:00'),  -- Memória RAM DDR4 16GB 3200MHz (Desktop)
    (5, 2500, 6000, 25, 7, 1, '2026-08-25 08:00:00'),  -- Pasta Térmica de Alta Performance (Bisnaga 4g)
    (6, 19000, 34000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Fonte ATX 500W 80 Plus Bronze
    (7, 800, 2500, 30, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Célula Moeda CR2032 (Cartela c/ 5)
    (8, 4500, 9500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Cooler para Processador Socket Universal
    (9, 300, 1500, 50, 7, 1, '2026-08-25 08:00:00'),  -- Cabo SATA III 6Gbps 50cm
    (10, 28000, 48000, 5, 7, 1, '2026-08-25 08:00:00'),  -- Tela LED 15.6" Slim 30 Pinos Full HD
    (11, 18000, 35000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo iPhone 11
    (12, 16000, 31000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo Samsung Galaxy A54
    (13, 14000, 28000, 5, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo Motorola Moto G84
    (14, 7500, 16000, 8, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível iPhone 11 (3110mAh)
    (15, 6000, 13000, 7, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível Samsung Galaxy A32
    (16, 5500, 12000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível Moto G30
    (17, 250, 2000, 100, 7, 1, '2026-08-25 08:00:00'),  -- Conector de Carga Type-C Universal (Unidade)
    (18, 150, 1500, 100, 7, 1, '2026-08-25 08:00:00'),  -- Conector de Carga Micro USB V8
    (19, 1800, 5500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Flex de Carga e Microfone Moto G9 Play
    (20, 4000, 11000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Tampa Traseira de Vidro iPhone 12
    (21, 6500, 14000, 3, 7, 1, '2026-08-25 08:00:00'),  -- Câmera Traseira Principal Redmi Note 11
    (22, 500, 2500, 40, 7, 1, '2026-08-25 08:00:00'),  -- Alto-Falante Auricular Universal
    (23, 11000, 23000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Barra de LED TV Samsung 50" (Kit com 3 barras)
    (24, 9500, 19500, 5, 7, 1, '2026-08-25 08:00:00'),  -- Barra de LED TV LG 43" (Kit com 3 barras)
    (25, 16000, 31000, 2, 7, 1, '2026-08-25 08:00:00'),  -- Placa Fonte TV Samsung UN50TU8000
    (26, 21000, 42000, 2, 7, 1, '2026-08-25 08:00:00'),  -- Placa Principal TV LG 43UP7500
    (27, 2200, 6500, 8, 7, 1, '2026-08-25 08:00:00'),  -- Cabo Flat T-Con para Display TV 55"
    (28, 400, 2000, 15, 7, 1, '2026-08-25 08:00:00'),  -- Receptor Infravermelho para Controle Remoto TV
    (29, 8500, 15000, 3, 7, 1, '2026-08-25 08:00:00'),  -- Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)
    (30, 2200, 4500, 12, 7, 1, '2026-08-25 08:00:00'),  -- Álcool Isopropílico 99.8% 1 Litro
    (31, 1200, 3000, 15, 7, 1, '2026-08-25 08:00:00'),  -- Fita Kapton Térmica 10mm x 33m
    (32, 1500, 3500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Fita Dupla Face Fixação de Telas (3mm x 50m)
    (33, 500, 1800, 20, 7, 1, '2026-08-25 08:00:00'),  -- Fusível de Louça 5A 250V (Pacote c/ 10)
    (34, 80, 500, 150, 7, 1, '2026-08-25 08:00:00');  -- Capacitor Eletrolítico 1000uF x 25V

-- Entradas de reposição (preço sugerido = preço de venda atual da peça)
INSERT INTO entrada_peca (id_peca, preco_compra, preco_venda_sugerido, quantidade, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (1,  18000, (SELECT preco_venda FROM peca WHERE id = 1),  20, 7, 1, '2026-08-28 09:00:00'),  -- SSD NVMe
    (3,  11000, (SELECT preco_venda FROM peca WHERE id = 3),  15, 6, 1, '2026-08-28 09:10:00'),  -- RAM DDR4 8GB
    (11, 22000, (SELECT preco_venda FROM peca WHERE id = 11), 10, 6, 1, '2026-08-28 09:20:00'),  -- Display iPhone 11
    (14,  9000, (SELECT preco_venda FROM peca WHERE id = 14), 12, 7, 1, '2026-08-28 09:30:00'),  -- Bateria iPhone 11
    (23, 14000, (SELECT preco_venda FROM peca WHERE id = 23),  8, 6, 1, '2026-08-28 09:40:00');  -- Barra LED Samsung 50

-- ---------------------------------------------------------------
-- Ordens de serviço, refeitas pelo fluxo correto:
-- abrir OS (histórico "Aberto" é automático) -> situações -> serviços (preço do catálogo)
-- -> peças (só em situação 3/4) -> forma de pagamento -> Entregue.
-- Técnico de todas: Rafael Santos (3). Aberta por Roberto Martins (6, Gerente).
-- ---------------------------------------------------------------
INSERT INTO ordem (id_equipamento, defeito_relatado, defeito_constatado, data_abertura,
                   id_funcionario_abertura, id_funcionario_cargo_abertura, id_tecnico, id_tecnico_cargo) VALUES
    (1, 'Tela quebrada após queda.',                'Display frontal danificado, toque não responde.',                 '2026-09-01 09:30:00', 6, 1, 3, 3),  -- OS 1 iPhone 11
    (3, 'Notebook muito lento para ligar.',         'Lentidão provocada por HD mecânico antigo.',                      '2026-09-10 10:15:00', 6, 1, 3, 3),  -- OS 2 Dell
    (4, 'TV com som, mas imagem não aparece.',      'Barra de LED queimada.',                                          '2026-09-15 11:00:00', 6, 1, 3, 3),  -- OS 3 Smart TV LG
    (5, 'Desligando por aquecimento.',              'Acúmulo severo de poeira e necessidade de troca de pasta térmica.', '2026-09-20 14:20:00', 6, 1, 3, 3);  -- OS 4 PS5

-- ===== OS 1: iPhone 11 -> Entregue =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 2, 7, '2026-09-01 10:00:00'),   -- Em Diagnóstico
    (1, 3, 6, '2026-09-01 11:30:00'),   -- Orçamento Aprovado
    (1, 4, 7, '2026-09-01 14:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (1, 6, (SELECT preco FROM servico WHERE id = 6), 1, '2026-09-01 15:00:00');       -- Troca de Display/Frontal de Celular
INSERT INTO ordem_peca (id_ordem, id_peca, preco, quantidade, id_tecnico, id_tecnico_cargo, data_saida) VALUES
    (1, 11, (SELECT preco_venda FROM peca WHERE id = 11), 1, 3, 3, '2026-09-01 14:30:00');  -- Display iPhone 11
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 5, 6, '2026-09-02 15:30:00');   -- Pronto
UPDATE ordem SET id_forma_pagamento = 2 WHERE id = 1;                                  -- PIX
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 6, 6, '2026-09-02 16:00:00');   -- Entregue (data_fechamento automática)

-- ===== OS 2: Notebook Dell -> Pronto (ainda não entregue) =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (2, 3, 7, '2026-09-10 10:45:00'),   -- Orçamento Aprovado
    (2, 4, 6, '2026-09-10 11:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (2, 1, (SELECT preco FROM servico WHERE id = 1), 1, '2026-09-10 13:00:00');       -- Formatação e Instalação de SO
INSERT INTO ordem_peca (id_ordem, id_peca, preco, quantidade, id_tecnico, id_tecnico_cargo, data_saida) VALUES
    (2, 1, (SELECT preco_venda FROM peca WHERE id = 1), 1, 3, 3, '2026-09-10 11:30:00');    -- SSD NVMe 512GB
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (2, 5, 6, '2026-09-11 14:30:00');   -- Pronto
UPDATE ordem SET id_forma_pagamento = 1 WHERE id = 2;                                  -- Dinheiro (a pagar na retirada)

-- ===== OS 3: Smart TV LG -> Em Diagnóstico (sem peças: ainda não há orçamento aprovado) =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (3, 2, 6, '2026-09-15 15:00:00');   -- Em Diagnóstico
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (3, 10, (SELECT preco FROM servico WHERE id = 10), 1, '2026-09-15 16:00:00');     -- Troca de Barra de LED de Smart TV

-- ===== OS 4: PlayStation 5 -> Em Reparo =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (4, 3, 6, '2026-09-20 15:00:00'),   -- Orçamento Aprovado
    (4, 4, 7, '2026-09-20 16:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (4, 14, (SELECT preco FROM servico WHERE id = 14), 1, '2026-09-20 16:30:00');     -- Higienização / Metal Líquido (Console)
UPDATE ordem SET id_forma_pagamento = 4 WHERE id = 4;                                  -- Cartão de Crédito - À Vista

-- ---------------------------------------------------------------
-- Descarte (saida_peca = somente descarte; técnico pode descartar)
-- ---------------------------------------------------------------
INSERT INTO saida_peca (id_peca, preco, quantidade, motivo, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (5, 6000, 1, 'Descarte por defeito/avaria: bisnaga ressecada', 2, 3, '2026-09-05 10:00:00');
