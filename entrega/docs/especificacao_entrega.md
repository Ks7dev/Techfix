# TechFix — Especificação do Banco de Entrega

> Banco relacional SQLite da assistência técnica TechFix: 18 tabelas, FK composta de cargo, tabela de situações com histórico e tabelas de marca, modelo e tipo. As regras RN01–RN04 são garantidas pelo próprio banco (CHECKs e triggers). Pasta: `entrega/`.

## 1. Princípios do modelo
- FK composta `(id_funcionario, id_funcionario_cargo) → funcionario(id, id_cargo)` com `CHECK` de cargo. Ela garante que o cargo gravado é o real e restringe quem pode cadastrar.
- Cargos fixos: 1 Gerente, 2 Atendente e 3 Técnico.
- Tabelas de apoio: `marca`, `modelo`, `tipo`, `categoria`, `situacao`, `forma_pagamento`; tabelas de movimento: `ordem_situacao`, `ordem_servico`, `ordem_peca`, `entrada_peca` e `saida_peca`.
- Preço congelado por cópia, valores em centavos (`INTEGER`), `STRICT`, `NOCASE` e `status` para exclusão lógica.

## 2. Decisões de modelagem e garantias

| # | Decisão | Por quê / risco evitado |
|---|---|---|
| 1 | Triggers mantêm o estoque: entrada soma; uso em OS e descarte subtraem | O estoque reflete as movimentações sem lançamento manual |
| 2 | `CHECK (estoque_atual >= 0)` mais trigger com mensagem clara (RN03) | Impede estoque negativo e explica o motivo da recusa |
| 3 | Trigger em `ordem_peca` exige a OS em "Orçamento Aprovado" (3) ou "Em Reparo" (4) (RN01) | Peça não é consumida antes da aprovação do orçamento |
| 4 | `valor_total NOT NULL DEFAULT 0`, recalculado (serviços + peças) após cada inserção | O total nunca fica NULL nem desatualizado |
| 5 | `id_forma_pagamento` e `id_tecnico` opcionais na abertura; "Entregue" exige forma de pagamento (RN04) | A OS pode ser aberta sem dados que só existem depois |
| 6 | Coluna `ordem.id_situacao` atualizada pelo histórico; OS encerrada (6/7) não muda mais | Situação atual consultável direto e transições controladas |
| 7 | `data_fechamento` preenchida por trigger ao entrar em "Entregue" ou "Cancelado" | Data de fechamento coerente com a situação |
| 8 | `saida_peca`: técnico ou gerente (`CHECK IN (1,3)`) | RF10: quem manuseia a peça registra o descarte |
| 9 | `ordem_peca` = uso em OS e baixa o estoque; `saida_peca` = somente descarte | Evita contar o uso de peça em dobro |
| 10 | `situacao` contém só os 7 status do RF07, com os nomes corretos | Motivos de saída não se misturam com status de OS |
| 11 | `entrada_peca.preco_venda_sugerido` | RF09: preço sugerido de venda registrado na entrada |
| 12 | `CHECK (quantidade > 0)` em todas as tabelas de movimento e itens | Impede quantidades nulas ou negativas |
| 13 | `modelo.id_marca` FK + `UNIQUE (id_marca, nome_modelo)` | Todo modelo pertence a uma marca; sem modelos duplicados ou associados à marca errada |
| 14 | `numero_serie UNIQUE`; `CHECK (numero_serie IS NOT NULL OR imei IS NOT NULL)`; IMEI com 15 dígitos | Todo equipamento é identificável e sem duplicidade |
| 15 | `cliente.telefone NOT NULL` | RF02: dados para notificação do cliente |
| 16 | Sem `ON DELETE CASCADE` em cargo (padrão RESTRICT) | Apagar um cargo não apaga funcionários |
| 17 | `cargo.nome_cargo` UNIQUE; todas as tabelas `STRICT` | Tipos rígidos e nomes sem duplicidade |
| 18 | Triggers bloqueiam UPDATE/DELETE em `ordem_servico`, `ordem_peca`, `entrada_peca`, `saida_peca` e `ordem_situacao`, e novos itens em OS encerrada (RN02) | Itens e movimentos formam um histórico imutável |
| 19 | Scripts testados, que rodam do início ao fim e podem ser reexecutados | Sem erros de sintaxe, objetos duplicados ou colunas inexistentes |
| 20 | `ordem_peca.id_tecnico` precisa ser o técnico da OS | A peça é lançada pelo técnico responsável pelo reparo |

## 3. Tabelas (18)

Colunas de auditoria padrão nas tabelas de cadastro: `id_funcionario`, `id_funcionario_cargo` (com CHECK conforme a regra), `status INTEGER NOT NULL DEFAULT 1 CHECK (status IN (0,1))`, `data_cadastro TEXT NOT NULL DEFAULT (datetime('now','localtime'))` e a FK composta.

| Tabela | Colunas principais | Quem cadastra (CHECK de cargo) |
|---|---|---|
| cargo | id, nome_cargo UQ, status | — |
| funcionario | id, nome_funcionario, id_cargo FK, status, data_cadastro, UNIQUE(id, id_cargo) | — |
| cliente | id, nome_cliente, cpf UQ (11 dígitos), telefone NN, email UQ | IN (1,2) |
| categoria | id, nome UQ | = 1 |
| servico | id, nome UQ, id_categoria FK, preco ≥ 0, horas_trabalho > 0 | = 1 |
| marca | id, nome_marca UQ | IN (1,2) |
| tipo | id, nome_tipo UQ | IN (1,2) |
| modelo | id, id_marca FK, nome_modelo, UQ(id_marca, nome_modelo) | IN (1,2) |
| equipamento | id, id_cliente FK, id_modelo FK, id_tipo FK, numero_serie UQ, imei UQ (15 dígitos), CHECK série ou IMEI | IN (1,2) |
| peca | id, nome UQ, id_categoria FK, preco_compra ≥ 0, preco_venda ≥ 0, estoque_atual ≥ 0 | = 1 |
| situacao | id, nome UQ — os 7 status fixos (1 Aberto … 7 Cancelado) | — |
| forma_pagamento | id, nome UQ | = 1 |
| ordem | id, id_equipamento FK, defeito_relatado NN, defeito_constatado, id_situacao FK DEF 1, data_abertura, data_fechamento, valor_total NN DEF 0, id_forma_pagamento FK NULL, id_funcionario_abertura + cargo IN (1,2), id_tecnico + id_tecnico_cargo (= 3) NULL; CHECK (id_situacao <> 6 OR id_forma_pagamento IS NOT NULL) | IN (1,2) |
| ordem_situacao | id, id_ordem FK, id_nova_situacao FK, id_funcionario FK, data_situacao | — |
| ordem_servico | id, id_ordem FK, id_servico FK, preco_praticado ≥ 0, quantidade > 0, data_execucao | — |
| ordem_peca | id, id_ordem FK, id_peca FK, preco ≥ 0, quantidade > 0, id_tecnico + id_tecnico_cargo (= 3), data_saida | técnico |
| entrada_peca | id, id_peca FK, preco_compra ≥ 0, preco_venda_sugerido ≥ 0, quantidade > 0 | = 1 |
| saida_peca | id, id_peca FK, preco ≥ 0, quantidade > 0, motivo NN (texto do descarte) | IN (1,3) |

## 4. Triggers

| Trigger | Regra |
|---|---|
| `trg_entrada_peca_estoque` | AFTER INSERT entrada_peca: soma o estoque |
| `trg_ordem_peca_valida` | BEFORE INSERT ordem_peca: RN01 (situação 3 ou 4), técnico = técnico da OS, RN03 (estoque suficiente) |
| `trg_ordem_peca_estoque_total` | AFTER INSERT ordem_peca: subtrai o estoque e recalcula o total |
| `trg_saida_peca_valida` | BEFORE INSERT saida_peca: RN03 |
| `trg_saida_peca_estoque` | AFTER INSERT saida_peca: subtrai o estoque |
| `trg_ordem_servico_valida` | BEFORE INSERT ordem_servico: OS não encerrada |
| `trg_ordem_servico_total` | AFTER INSERT ordem_servico: recalcula o total |
| `trg_ordem_historico_inicial` | AFTER INSERT ordem: grava "Aberto" em ordem_situacao |
| `trg_ordem_situacao_valida` | BEFORE INSERT ordem_situacao: OS encerrada não muda; "Entregue" exige forma de pagamento (RN04) |
| `trg_ordem_situacao_atualiza` | AFTER INSERT ordem_situacao: atualiza `ordem.id_situacao` e preenche `data_fechamento` se a situação for 6 ou 7 |
| `trg_*_imutavel` | BEFORE UPDATE/DELETE em ordem_servico, ordem_peca, entrada_peca, saida_peca e ordem_situacao: bloqueia (RN02) |

Total: 22 triggers.

## 5. Views
- `vw_ordem_resumo`: OS, cliente, equipamento, situação atual, técnico, total e pagamento.
- `vw_estoque_baixo`: peças com estoque ≤ 5.
- `vw_preco_venda_maior_100`: peças com preço de venda acima de R$ 100,00.

## 6. Dados
- 7 funcionários (3 técnicos, 2 atendentes, 2 gerentes);
- 23 serviços e 34 peças do catálogo;
- marcas, modelos e tipos coerentes;
- clientes com telefone;
- 4 OS de exemplo, criadas pelo fluxo correto, de modo que o total e o estoque são calculados pelos triggers;
- entradas de peça (estoque inicial e reposições);
- 1 descarte.

## 7. Entregáveis (`entrega/banco/`)
`01_tabelas.sql`, `02_regras.sql`, `03_views.sql`, `04_dados.sql`, `techfix_entrega_completo.sql` (reúne as quatro partes, roda sozinho e pode ser executado de novo), `techfix_entrega.sqlite` (banco pronto) e `README.md`.
