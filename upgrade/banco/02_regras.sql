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
