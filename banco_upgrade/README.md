# TechFix - Banco Upgrade (SQLite)

Banco Upgrade: a evolução do banco de entrega, completo e de alta complexidade, com recursos de nível produção, para a assistência técnica TechFix, derivado de
[`docs/especificacao_upgrade.md`](../docs/especificacao_upgrade.md). Atende RF01–RF11 e
RN01–RN04 e acrescenta controle de acesso por permissões, auditoria JSON, razão de estoque
(kardex) com custo médio ponderado, máquina de estados da OS, orçamento, pagamentos múltiplos e
parcelados, garantia, histórico de preços, compras com nota fiscal e índices.

- SGBD: SQLite ≥ 3.38 (tabelas `STRICT`, funções JSON, índices parciais, coluna gerada).
- Dinheiro em **centavos** (`INTEGER`); percentuais em pontos-base; datas ISO (`AAAA-MM-DD HH:MM:SS`).
- Exclusão **lógica** (`ativo = 0`); `DELETE` físico é bloqueado por trigger.
- Tamanho atual: 31 tabelas, 58 índices, 107 triggers, 8 views.

## Como criar o banco

`techfix_upgrade_completo.sql` é o script único: roda sozinho e pode ser executado várias vezes
(ele começa apagando views, triggers, índices e tabelas existentes na ordem certa).

| Ferramenta | Passos |
|---|---|
| **DB Browser for SQLite** | Novo banco > aba *Executar SQL* > *Abrir arquivo SQL* > `techfix_upgrade_completo.sql` > *Executar tudo* (Ctrl+Return) > *Gravar alterações* (Ctrl+S). |
| **SQLiteStudio** | Criar/abrir banco > *Ferramentas > Abrir editor SQL* > abrir o arquivo > *Executar* (F9). |
| **sqlite3 (CLI)** | `sqlite3 techfix_upgrade.sqlite < techfix_upgrade_completo.sql` |

O banco já pronto e populado também está em `techfix_upgrade.sqlite`.

### PRAGMAs de conexão recomendados

```sql
PRAGMA foreign_keys = ON;         -- obrigatório
PRAGMA journal_mode = WAL;        -- persistente no arquivo
PRAGMA busy_timeout = 5000;
PRAGMA recursive_triggers = OFF;  -- o projeto depende deste padrão
```

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `01_estrutura.sql` | Tabelas `STRICT` com CHECKs, FKs e todos os índices (inclusive parciais) |
| `02_regras.sql` | Triggers de negócio: permissões, Luhn, kardex, máquina de estados, orçamento, preços congelados, estorno, pagamentos |
| `03_auditoria.sql` | Auditoria JSON, `versao`/`atualizado_em`, logs imutáveis, bloqueio de `DELETE` |
| `04_views.sql` | 8 views gerenciais |
| `05_dados.sql` | Seed: cargos, permissões, status, equipe, catálogo (23 serviços e 34 peças), compras, clientes, equipamentos, 7 OS, descarte e ajuste |
| `techfix_upgrade_completo.sql` | Script único, reúne `01` a `05` com bloco de limpeza |
| `techfix_upgrade.sqlite` | Banco pronto, com `PRAGMA user_version = 3` |

## Módulos

1. **Acesso e pessoas** – `cargo`, `permissao`, `cargo_permissao`, `funcionario`, `usuario` (hash de senha; nunca a senha).
   A permissão é verificada por trigger com o padrão `NOT EXISTS (funcionario ativo + cargo_permissao + permissao)`;
   funcionário inativo não executa nada (e o usuário dele é desativado automaticamente).
2. **Clientes** – `cliente` (PF 11 / PJ 14 dígitos, LGPD), `cliente_contato` (principal único por tipo), `cliente_endereco`.
3. **Equipamentos** – `marca`, `tipo_equipamento` (`exige_imei`), `modelo`, `equipamento` (IMEI validado por **Luhn** com CTE recursiva em trigger).
4. **Catálogo** – `categoria` hierárquica, `servico`, `peca`, `historico_preco`.
5. **Compras** – `fornecedor`, `compra`, `compra_item` (gera movimento `ENTRADA`).
6. **Kardex** – `movimento_estoque` imutável, com saldo anterior/posterior e custo médio ponderado.
7. **Ordem de serviço** – `status_os`, `status_transicao`, `ordem_servico`, `os_historico_status`, `os_orcamento`, `os_servico`, `os_peca`.
8. **Pagamentos** – `forma_pagamento`, `os_pagamento` (múltiplos, parcelados, com estorno).
9. **Metadados** – `auditoria`, `schema_versao`.

## Mapa RF / RN → implementação

Numeração oficial dos requisitos do projeto.

| Requisito | Implementação |
|---|---|
| RF01 Gestão de funcionários (atendentes, técnicos, gerentes; acesso e auditoria) | `cargo`, `permissao`, `cargo_permissao`, `funcionario`, `usuario`; `trg_funcionario_*`, `trg_usuario_bi_regras`; auditoria JSON em `auditoria` (`03_auditoria.sql`, `trg_*_auditoria`) |
| RF02 Cadastro de clientes (só atendente/gerente) | `cliente`, `cliente_contato`, `cliente_endereco`; `trg_cliente_*_permissao` (CLIENTE_GERENCIAR); contato obrigatório na abertura da OS |
| RF03 Registro de equipamentos (marca, modelo, tipo, nº de série/IMEI; só atendente/gerente) | `marca`, `tipo_equipamento`, `modelo`, `equipamento`; `trg_equipamento_*_permissao` (EQUIPAMENTO_GERENCIAR), `trg_equipamento_bi_imei` / `bu_imei` (IMEI obrigatório + Luhn) |
| RF04 Abertura de OS (data, defeito, cliente, equipamento, atendente/gerente) | `ordem_servico`; `trg_ordem_servico_bi_regras` (OS_ABRIR, equipamento do cliente), `trg_ordem_servico_ai_abertura` (número `OS-AAAA-NNNNNN` + 1º histórico) |
| RF05 Catálogo de serviços (só gerente) | `servico`, `categoria`, `historico_preco`; `trg_servico_bi_regras` / `bu_regras` (CATALOGO_GERENCIAR), `trg_servico_au_historico_preco` |
| RF06 Associação de serviços (1+ por OS, preço congelado, técnico único) | `os_servico`, `ordem_servico.id_tecnico`; `trg_os_servico_bi_regras` (técnico da OS, preço do catálogo), `trg_os_servico_ai_recalcula`, `trg_ordem_servico_bu_tecnico` |
| RF07 Status e histórico (7 status; data/hora, novo status, técnico) | `status_os`, `status_transicao`, `os_historico_status`; `trg_os_historico_status_bi_regras` / `ai_aplica` / `bu_imutavel`, `trg_ordem_servico_bu_status` |
| RF08 Catálogo de peças (saldo em tempo real) | `peca` (`estoque_atual`, `custo_medio`), `movimento_estoque` (kardex); `trg_peca_bi_regras` / `bu_regras`, `trg_peca_bu_estoque_somente_kardex`, `trg_movimento_estoque_ai_aplica`; view `vw_estoque_reposicao` |
| RF09 Entrada de peças (qtd, custo, preço sugerido, data, gerente) | `fornecedor`, `compra`, `compra_item` (quantidade, custo, data da compra, funcionário com ESTOQUE_ENTRADA), `peca.preco_venda`; `trg_compra_*`, `trg_compra_item_ai_entrada` (gera movimento `ENTRADA`) |
| RF10 Baixa/saída (só uso em OS ou descarte; qtd, valor, data, técnico) | `movimento_estoque` com tipos `SAIDA_OS` e `DESCARTE` (e `AJUSTE_*`, `ESTORNO_OS` de inventário/estorno); `trg_movimento_estoque_bi_regras` (ESTOQUE_BAIXA, OS_EXECUTAR) |
| RF11 Vínculo de peças na OS (gera baixa) | `os_peca`; `trg_os_peca_bi_regras`, `trg_os_peca_ai_baixa` (gera `SAIDA_OS`), `trg_os_peca_au_estorno` (`ESTORNO_OS`) |
| RN01 Baixa só em "Orçamento Aprovado"/"Em Reparo" | `status_os.permite_baixa_peca` + `trg_os_peca_bi_regras` (`'RN01: ...'`) |
| RN02 Histórico financeiro imutável | `trg_movimento_estoque_bu_imutavel`, `trg_os_historico_status_bu_imutavel`, `trg_auditoria_bu_imutavel`, `trg_historico_preco_bu_imutavel`, `trg_compra_item_bu_imutavel`; preço e custo congelados em `os_servico`/`os_peca` (`trg_os_servico_bu_regras`, `trg_os_peca_bu_regras`: só cancelar/estornar); `trg_<tabela>_bd_bloqueia` (sem `DELETE`) |
| RN03 Estoque nunca negativo | `CHECK (estoque_atual >= 0)` em `peca`; `'RN03: estoque insuficiente'` em `trg_os_peca_bi_regras` e `trg_movimento_estoque_bi_regras` |
| RN04 Total automático (serviços + peças) e forma de pagamento no fechamento | `ordem_servico.valor_total` (coluna gerada: subtotais − desconto), `trg_os_servico_*_recalcula`, `trg_os_peca_*`, `trg_ordem_servico_bu_subtotais`; `forma_pagamento`, `os_pagamento` (`trg_os_pagamento_bi_regras`); `trg_os_historico_status_bi_regras` exige os pagamentos para `ENTREGUE` |

## Recursos de nível produção

- Permissões por cargo verificadas em triggers (um padrão único, funcionário inativo bloqueado).
- Hash de senha obrigatório (`length ≥ 60`, formato `$...$...`); `senha_hash` nunca vai para a auditoria.
- IMEI validado por Luhn (CTE recursiva em trigger) e `tipo_equipamento.exige_imei`.
- Razão de estoque (kardex) imutável, saldos encadeados e **custo médio ponderado**; `estoque_atual` e `custo_medio` só mudam por movimento.
- Máquina de estados da OS (`status_transicao`) com pré-condições (técnico, orçamento aprovado, pagamento completo) e histórico imutável.
- Orçamento com situação, validade, forma de aprovação e unicidade do orçamento vigente.
- Preço e custo congelados nos itens; estorno de peça devolve estoque e recalcula a OS.
- Pagamentos múltiplos/parcelados, limite por forma de pagamento, estorno único e total nunca excedido.
- Desconto com permissão (`DESCONTO_CONCEDER`), teto = subtotais; `valor_total` é coluna gerada.
- Garantia calculada na entrega (maior `garantia_dias` entre os itens).
- Auditoria JSON (`json_object`, `json_valid`) imutável, com responsável; histórico de preços.
- Versionamento (`versao` + `atualizado_em`) para lock otimista: `UPDATE ... WHERE id = ? AND versao = ?`.
- Bloqueio de `DELETE` físico (`trg_<tabela>_bd_bloqueia`), exceto `cargo_permissao`/`schema_versao`.
- `schema_versao` + `PRAGMA user_version = 3`; índices em todas as FKs e índices parciais.
- 8 views gerenciais: `vw_os_painel`, `vw_os_extrato`, `vw_estoque_reposicao`, `vw_kardex`,
  `vw_faturamento_mensal`, `vw_produtividade_tecnico`, `vw_garantias_ativas`, `vw_auditoria`.
- Script completo reexecutável e banco `.sqlite` pronto.

## Decisões e desvios em relação à especificação

- `ordem_servico.valor_total` é **coluna gerada (STORED)** `subtotal_servicos + subtotal_pecas - desconto`
  (o CHECK da especificação vale por construção e `UPDATE` de desconto não exige reenviar o total).
- Colunas extras: `funcionario.criado_por/atualizado_por` (permite exigir FUNCIONARIO_GERENCIAR; o
  primeiro funcionário é o bootstrap do gerente) e `cliente_contato`/`cliente_endereco.criado_por/atualizado_por`.
- `os_peca.custo_unitario` deve ser enviado igual a `peca.custo_medio` (como o preço congelado, divergência é rejeitada).
- O estorno de peça devolve o estoque ao custo médio vigente (o custo médio só muda em `ENTRADA`) e usa o técnico da peça como responsável.
- Orçamento: criar exige `OS_ALTERAR_STATUS` (a especificação não define permissão própria).
- `CANCELADO` exige peças estornadas; pagamento só com OS em `PRONTO`; estorno de pagamento/peça/serviço só em OS não final.
- Subtotais da OS só aceitam o valor recalculado; o recálculo reduz o `desconto` ao novo teto quando um item é cancelado/estornado.
- Numeração da OS usa o ano de `data_abertura`.
- A aplicação não deve gravar `versao`; o trigger a incrementa.
- Seed: 2 compras (fornecedores fictícios) lançam o estoque inicial; `senha_hash` são **placeholders** (trocar antes de usar de verdade).
