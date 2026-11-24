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
