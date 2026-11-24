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
