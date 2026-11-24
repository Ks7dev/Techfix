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
