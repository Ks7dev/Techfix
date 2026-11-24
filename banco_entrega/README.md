# TechFix — Banco de Entrega

Banco de dados SQLite da assistência técnica TechFix: 18 tabelas (todas `STRICT`), 22 triggers e 3 views. As regras de negócio RN01–RN04 são garantidas pelo próprio banco. Valores monetários em **centavos** (`INTEGER`). Especificação completa: `docs/especificacao_entrega.md`.

## Como criar o banco

Use o **script único** `techfix_entrega_completo.sql`, que reúne as quatro partes (`01` a `04`).

- **DB Browser for SQLite:** `File > New Database`, cancele o assistente de tabela, abra a aba **Execute SQL**, abra o arquivo, execute tudo (Ctrl+Enter) e grave (Ctrl+S).
- **SQLiteStudio:** crie um banco, abra o Editor SQL, carregue o arquivo e execute (F9).
- **sqlite3:**

```
sqlite3 techfix.sqlite < techfix_entrega_completo.sql
```

O script apaga e recria tudo, então pode ser executado de novo. Se preferir, abra direto o `techfix_entrega.sqlite`, que já vem pronto.

O estoque, o total da OS e a data de fechamento são calculados por triggers: não escreva esses valores à mão.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `01_tabelas.sql` | As 18 tabelas |
| `02_regras.sql` | Os 22 triggers (regras de negócio) |
| `03_views.sql` | As 3 views |
| `04_dados.sql` | Dados iniciais |
| `techfix_entrega_completo.sql` | Script único: limpeza + 01 a 04 |
| `techfix_entrega.sqlite` | Banco pronto |

## Módulos e tabelas

| Módulo | Tabelas |
|---|---|
| Acesso e cadastros de pessoas | `cargo`, `funcionario`, `cliente` |
| Catálogo | `categoria`, `servico`, `peca` |
| Equipamentos | `marca`, `tipo`, `modelo`, `equipamento` |
| Ordem de serviço | `situacao`, `forma_pagamento`, `ordem`, `ordem_situacao`, `ordem_servico`, `ordem_peca` |
| Estoque | `entrada_peca`, `saida_peca` |

Views: `vw_ordem_resumo`, `vw_estoque_baixo`, `vw_preco_venda_maior_100`.

## Requisitos atendidos

| Requisito | Onde é atendido |
|---|---|
| RF01 — Gestão de funcionários | `cargo`, `funcionario`; FK composta de cargo nas tabelas de cadastro (auditoria) |
| RF02 — Cadastro de clientes | `cliente` (CPF único, telefone obrigatório; só atendente ou gerente) |
| RF03 — Registro de equipamentos | `marca`, `tipo`, `modelo`, `equipamento` (série ou IMEI; só atendente ou gerente) |
| RF04 — Abertura de OS | `ordem` (data, defeito relatado, equipamento, atendente ou gerente) |
| RF05 — Catálogo de serviços | `categoria`, `servico` (só gerente) |
| RF06 — Associação de serviços | `ordem_servico` (preço congelado), `ordem.id_tecnico` (um técnico por OS) |
| RF07 — Status e histórico | `situacao` (7 status), `ordem.id_situacao`, `ordem_situacao` |
| RF08 — Catálogo de peças | `peca` com `estoque_atual` mantido pelos triggers |
| RF09 — Entrada de peças | `entrada_peca` (custo, `preco_venda_sugerido`, gerente) |
| RF10 — Baixa/saída de peças | `ordem_peca` (uso em reparo) e `saida_peca` (descarte), com técnico |
| RF11 — Vínculo de peças na OS | `ordem_peca` e `trg_ordem_peca_estoque_total` (baixa no estoque) |
| RN01 — Baixa só em OS aprovada ou em reparo | `trg_ordem_peca_valida` |
| RN02 — Histórico financeiro imutável | preço copiado em `ordem_servico`/`ordem_peca`; `trg_*_imutavel` |
| RN03 — Estoque nunca negativo | `CHECK (estoque_atual >= 0)`, `trg_ordem_peca_valida`, `trg_saida_peca_valida` |
| RN04 — Fechamento de OS | total calculado por `trg_ordem_servico_total` e `trg_ordem_peca_estoque_total`; "Entregue" exige forma de pagamento (`CHECK` em `ordem` e `trg_ordem_situacao_valida`) |

## Decisões de modelagem e garantias

| # | Decisão | Por quê / risco evitado |
|---|---|---|
| 1 | Triggers mantêm o estoque: entrada soma; uso em OS e descarte subtraem | O estoque reflete as movimentações sem lançamento manual |
| 2 | `CHECK (estoque_atual >= 0)` mais trigger com mensagem clara (RN03) | Impede estoque negativo e explica o motivo da recusa |
| 3 | Trigger em `ordem_peca` exige a OS em "Orçamento Aprovado" (3) ou "Em Reparo" (4) (RN01) | Peça não é consumida antes da aprovação do orçamento |
| 4 | `valor_total NOT NULL DEFAULT 0`, recalculado (serviços + peças) após cada inserção | O total nunca fica NULL nem desatualizado |
| 5 | `id_forma_pagamento` e `id_tecnico` opcionais na abertura; "Entregue" exige forma de pagamento (RN04) | A OS pode ser aberta sem dados que só existem depois |
| 6 | `ordem.id_situacao` atualizada pelo histórico; OS encerrada (6/7) não muda mais | Situação atual consultável direto e transições controladas |
| 7 | `data_fechamento` preenchida por trigger ao entrar em "Entregue" ou "Cancelado" | Data de fechamento coerente com a situação |
| 8 | `saida_peca`: técnico ou gerente (`CHECK IN (1,3)`) | RF10: quem manuseia a peça registra o descarte |
| 9 | `ordem_peca` = uso em OS e baixa o estoque; `saida_peca` = somente descarte | Evita contar o uso de peça em dobro |
| 10 | `situacao` só com os 7 status do RF07, com os nomes corretos | Motivos de saída não se misturam com status de OS |
| 11 | `entrada_peca.preco_venda_sugerido` | RF09: preço sugerido de venda registrado na entrada |
| 12 | `CHECK (quantidade > 0)` em todas as tabelas de movimento e itens | Impede quantidades nulas ou negativas |
| 13 | `modelo.id_marca` FK + `UNIQUE (id_marca, nome_modelo)` | Todo modelo pertence a uma marca; sem duplicidade nem marca errada |
| 14 | `numero_serie UNIQUE`; `CHECK (numero_serie IS NOT NULL OR imei IS NOT NULL)`; IMEI com 15 dígitos | Todo equipamento é identificável e sem duplicidade |
| 15 | `cliente.telefone NOT NULL` | RF02: dados para notificação do cliente |
| 16 | Sem `ON DELETE CASCADE` em cargo (padrão RESTRICT) | Apagar um cargo não apaga funcionários |
| 17 | `cargo.nome_cargo` UNIQUE; todas as tabelas `STRICT` | Tipos rígidos e nomes sem duplicidade |
| 18 | Triggers bloqueiam UPDATE/DELETE em `ordem_servico`, `ordem_peca`, `entrada_peca`, `saida_peca` e `ordem_situacao`, e novos itens em OS encerrada (RN02) | Itens e movimentos formam um histórico imutável |
| 19 | Scripts que rodam do início ao fim e podem ser reexecutados | Sem erros de sintaxe, objetos duplicados ou colunas inexistentes |
| 20 | `ordem_peca.id_tecnico` precisa ser o técnico da OS | A peça é lançada pelo técnico responsável pelo reparo |
