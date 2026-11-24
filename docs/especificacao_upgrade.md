# TechFix — Especificação do Banco Upgrade

> Banco Upgrade: a evolução do banco de entrega, completo e de alta complexidade, com recursos de nível produção. Ele é derivado
> deste documento. Pasta: `banco_upgrade/`.
> Ele atende RF01–RF11 e RN01–RN04 e acrescenta: controle de acesso por
> permissões, auditoria completa em JSON, razão de estoque (kardex) com custo
> médio ponderado, máquina de estados da OS, orçamento, pagamentos múltiplos e
> parcelados, garantia, histórico de preços, compras com fornecedor e nota
> fiscal, e índices.

## 1. Convenções

| Item | Convenção |
|---|---|
| SGBD | SQLite ≥ 3.38 (`STRICT`, funções JSON, índices parciais) |
| PRAGMAs de conexão | `foreign_keys = ON`, `journal_mode = WAL`, `busy_timeout = 5000`, `recursive_triggers = OFF` |
| Versão do esquema | tabela `schema_versao` e `PRAGMA user_version = 3` |
| Chave primária | `id INTEGER PRIMARY KEY` (rowid; `AUTOINCREMENT` só nas tabelas de log/razão, para nunca reutilizar ids) |
| Dinheiro | `INTEGER` em centavos, nunca negativo, salvo indicação |
| Percentual | `INTEGER` em pontos-base (`250` = 2,50 %) |
| Data/hora | `TEXT` ISO `AAAA-MM-DD HH:MM:SS`, com `CHECK (col IS NULL OR datetime(col) = col)`; padrão `datetime('now','localtime')` |
| Data | `TEXT` `AAAA-MM-DD`, com `CHECK (date(col) = col)` |
| Booleano | `INTEGER CHECK (col IN (0,1))` |
| Exclusão | **lógica** (`ativo = 0`). Um `DELETE` físico é bloqueado por trigger em todas as tabelas de negócio |
| Concorrência | coluna `versao INTEGER NOT NULL DEFAULT 1`, incrementada por trigger a cada UPDATE (para lock otimista na aplicação) nas tabelas `cliente`, `equipamento`, `ordem_servico`, `peca`, `servico` |
| Atualização | `atualizado_em` mantido por trigger nas mesmas tabelas |
| Responsável | colunas `criado_por` / `atualizado_por` → `funcionario(id)` |
| Mensagens de erro | `RAISE(ABORT, 'CÓDIGO: mensagem em português')`, ex.: `'RN03: estoque insuficiente'` |

## 2. Módulos e tabelas

### 2.1 Acesso e pessoas
- **cargo**: `id`, `nome` (UQ, NOCASE), `descricao`, `ativo`.
- **permissao**: `id`, `codigo` (UQ, `CHECK (codigo = upper(codigo))`), `descricao`.
- **cargo_permissao**: `id_cargo` FK, `id_permissao` FK, com PK `(id_cargo, id_permissao)`, `WITHOUT ROWID`.
- **funcionario**:
  - colunas: `id`, `nome`, `cpf` (UQ, 11 dígitos), `email` (UQ, NOCASE), `telefone`, `id_cargo` FK, `data_admissao` (date), `data_demissao` (date, NULL, `CHECK ≥ admissão`), `ativo`, `criado_em`.
  - CHECK: `ativo = 0 OR data_demissao IS NULL`.
- **usuario**: `id`, `id_funcionario` (FK, UQ), `login` (UQ, NOCASE, 4–30 caracteres), `senha_hash` (NN, `length ≥ 60`, hash argon2/bcrypt gerado pela aplicação; nunca a senha em texto), `tentativas_falhas` (DEF 0), `bloqueado_ate` (datetime NULL), `ultimo_login`, `ativo`.

Permissões (seed), com os cargos que as possuem:

| Código | Gerente | Atendente | Técnico |
|---|:-:|:-:|:-:|
| FUNCIONARIO_GERENCIAR | ✔ | | |
| CLIENTE_GERENCIAR | ✔ | ✔ | |
| EQUIPAMENTO_GERENCIAR | ✔ | ✔ | |
| OS_ABRIR | ✔ | ✔ | |
| OS_EXECUTAR | | | ✔ |
| OS_ALTERAR_STATUS | ✔ | ✔ | ✔ |
| CATALOGO_GERENCIAR | ✔ | | |
| ESTOQUE_ENTRADA | ✔ | | |
| ESTOQUE_BAIXA | ✔ | | ✔ |
| ESTOQUE_AJUSTE | ✔ | | |
| PAGAMENTO_REGISTRAR | ✔ | ✔ | |
| DESCONTO_CONCEDER | ✔ | | |

A verificação de permissão é feita por trigger, sempre com o mesmo padrão:

```sql
WHEN NOT EXISTS (SELECT 1 FROM funcionario f
                 JOIN cargo_permissao cp ON cp.id_cargo = f.id_cargo
                 JOIN permissao p ON p.id = cp.id_permissao
                 WHERE f.id = NEW.<responsavel> AND f.ativo = 1 AND p.codigo = '<CODIGO>')
```

Funcionário inativo não executa nada.

### 2.2 Clientes
- **cliente**:
  - colunas: `id`, `tipo_pessoa` (CHECK `'PF','PJ'`), `nome` (razão social, se PJ), `documento` (UQ, só dígitos), `data_nascimento` (date, NULL), `aceita_comunicacao` (bool, LGPD), `ativo`, `criado_em`, `criado_por`, `atualizado_em`, `atualizado_por`, `versao`.
  - CHECK: `(tipo_pessoa='PF' AND length(documento)=11) OR (tipo_pessoa='PJ' AND length(documento)=14)`.
- **cliente_contato**:
  - colunas: `id`, `id_cliente` FK, `tipo` (CHECK `'CELULAR','TELEFONE','EMAIL','WHATSAPP'`), `valor`, `principal` (bool), `ativo`.
  - CHECK: e-mail contém `@` quando `tipo = 'EMAIL'`; telefone tem 10–11 dígitos.
  - índice único parcial: `(id_cliente, tipo) WHERE principal = 1 AND ativo = 1`.
- **cliente_endereco**:
  - colunas: `id`, `id_cliente`, `cep` (8 dígitos), `logradouro`, `numero`, `complemento`, `bairro`, `cidade`, `uf` (CHECK com as 27 UFs), `principal`, `ativo`.
  - índice único parcial: um principal ativo por cliente.
- **Regras:**
  - inserir em `cliente` e `cliente_contato` exige `CLIENTE_GERENCIAR` de `criado_por` (RF02);
  - todo cliente precisa de ao menos um contato para ter OS aberta (validado na abertura da OS).

### 2.3 Equipamentos
- **marca**: `id`, `nome` (UQ, NOCASE), `ativo`.
- **tipo_equipamento**: `id`, `nome` (UQ), `exige_imei` (bool; Celular = 1), `ativo`.
- **modelo**: `id`, `id_marca` FK, `id_tipo_equipamento` FK, `nome`, `ativo`, UQ `(id_marca, nome)`.
- **equipamento**:
  - colunas: `id`, `id_cliente` FK, `id_modelo` FK, `numero_serie` (UQ, NULL), `imei` (UQ, NULL, 15 dígitos), `cor`, `observacao`, `ativo`, `criado_em`, `criado_por`, `atualizado_em`, `atualizado_por`, `versao`.
  - CHECK: `numero_serie IS NOT NULL OR imei IS NOT NULL`.
  - trigger: tipo com `exige_imei = 1` → IMEI obrigatório;
  - trigger: o IMEI precisa passar no **algoritmo de Luhn**, com uma CTE recursiva dentro do trigger;
  - permissão `EQUIPAMENTO_GERENCIAR` (RF03).

### 2.4 Catálogo
- **categoria**:
  - colunas: `id`, `nome`, `id_categoria_pai` (FK auto-relacionamento, NULL), `aplica_a` (CHECK `'SERVICO','PECA','AMBOS'`), `ativo`.
  - UQ `(id_categoria_pai, nome)`; CHECK `id_categoria_pai <> id`.
- **servico**: `id`, `codigo` (UQ, ex. `SRV-001`), `nome` (UQ, NOCASE), `id_categoria` FK, `preco_base`, `tempo_estimado_min` (> 0), `garantia_dias` (≥ 0, DEF 90), `ativo`, `criado_em`, `criado_por`, `atualizado_em`, `atualizado_por`, `versao`. Permissão `CATALOGO_GERENCIAR` (RF05).
- **peca**:
  - colunas: `id`, `sku` (UQ, ex. `PEC-001`), `nome` (UQ, NOCASE), `id_categoria` FK, `unidade` (CHECK `'UN','KIT','CX','PCT','L','M','G'`), `preco_venda`, `custo_medio` (DEF 0), `estoque_atual` (DEF 0, CHECK ≥ 0 — RN03), `estoque_minimo` (DEF 0, ≥ 0), `localizacao`, `garantia_dias` (DEF 90), `ativo`, `criado_em`, `criado_por`, `atualizado_em`, `atualizado_por`, `versao`.
  - `estoque_atual` e `custo_medio` **só mudam pela razão de estoque**. Trigger: UPDATE dessas colunas fora de um movimento é bloqueado. Técnica: a flag `peca.movimento_pendente`, ou comparar com o último movimento (`saldo_posterior`). Use a comparação com o último movimento.
- **historico_preco**:
  - colunas: `id` (AUTOINCREMENT), `tipo_item` (CHECK `'SERVICO','PECA'`), `id_item`, `preco_anterior`, `preco_novo`, `id_funcionario`, `data_hora`.
  - preenchido por trigger AFTER UPDATE OF `preco_base`/`preco_venda`, quando o preço muda. `atualizado_por` é obrigatório nesse UPDATE e precisa de `CATALOGO_GERENCIAR`.

### 2.5 Fornecedores e compras (RF09)
- **fornecedor**: `id`, `razao_social`, `cnpj` (UQ, 14 dígitos), `email`, `telefone`, `ativo`.
- **compra**:
  - colunas: `id`, `id_fornecedor` FK, `numero_nf`, `data_compra` (date), `valor_total` (mantido por trigger = Σ itens), `id_funcionario` (precisa de `ESTOQUE_ENTRADA`), `criado_em`.
  - UQ `(id_fornecedor, numero_nf)`.
- **compra_item**:
  - colunas: `id`, `id_compra` FK, `id_peca` FK, `quantidade` (> 0), `custo_unitario` (≥ 0), `preco_venda_sugerido` (≥ 0).
  - UQ `(id_compra, id_peca)`.
  - trigger AFTER INSERT: gera o movimento `ENTRADA` e recalcula `compra.valor_total`. É imutável (UPDATE e DELETE bloqueados).

### 2.6 Razão de estoque (kardex) — RF08, RF10, RF11, RN03
- **movimento_estoque** (AUTOINCREMENT, imutável):
  - colunas: `id`, `id_peca` FK, `tipo` (CHECK `'ENTRADA','SAIDA_OS','DESCARTE','AJUSTE_ENTRADA','AJUSTE_SAIDA','ESTORNO_OS'`), `quantidade` (> 0), `custo_unitario` (≥ 0), `saldo_anterior` (≥ 0), `saldo_posterior` (≥ 0), `custo_medio_anterior`, `custo_medio_posterior`, `id_compra_item` (FK, NULL), `id_os_peca` (FK, NULL), `motivo` (TEXT), `id_funcionario` FK, `data_hora`.
  - CHECKs de coerência:
    - `tipo='ENTRADA'` ⇔ `id_compra_item IS NOT NULL`;
    - `tipo IN ('SAIDA_OS','ESTORNO_OS')` ⇔ `id_os_peca IS NOT NULL`;
    - `tipo IN ('DESCARTE','AJUSTE_ENTRADA','AJUSTE_SAIDA')` ⇒ `motivo` obrigatório (length ≥ 5);
    - `saldo_posterior = saldo_anterior + quantidade` para tipos de entrada (`ENTRADA`, `AJUSTE_ENTRADA`, `ESTORNO_OS`) e `saldo_anterior - quantidade` para os de saída.
  - BEFORE INSERT: calcula/valida `saldo_anterior = peca.estoque_atual`. Como o SQLite não permite alterar NEW, a aplicação/trigger de origem informa os saldos e um trigger **valida** que `saldo_anterior` = estoque atual da peça. Os triggers de origem (`compra_item`, `os_peca`) fazem o INSERT já calculando os saldos.
  - AFTER INSERT: `UPDATE peca SET estoque_atual = NEW.saldo_posterior, custo_medio = NEW.custo_medio_posterior`.
  - Custo médio ponderado: em ENTRADA, `(saldo_ant × custo_medio_ant + qtd × custo_unit) / (saldo_ant + qtd)`, arredondado com `CAST(ROUND(...) AS INTEGER)`; nas saídas, ele não muda.
  - Permissões: `DESCARTE` precisa de `ESTOQUE_BAIXA`; `AJUSTE_*` precisa de `ESTOQUE_AJUSTE`; `SAIDA_OS` precisa de `OS_EXECUTAR`.
  - RN03: `saldo_posterior ≥ 0`, mais um trigger com a mensagem `'RN03: estoque insuficiente'`.

### 2.7 Ordem de serviço
- **status_os** (seed fixo):
  - colunas: `id`, `codigo` (UQ), `nome`, `ordem_exibicao`, `permite_baixa_peca` (bool), `permite_lancar_servico` (bool), `final` (bool).
  - registros:
    1. `ABERTO`
    2. `EM_DIAGNOSTICO`
    3. `ORCAMENTO_APROVADO` (baixa = 1)
    4. `EM_REPARO` (baixa = 1)
    5. `PRONTO`
    6. `ENTREGUE` (final)
    7. `CANCELADO` (final)
  - `permite_lancar_servico = 1` em 2, 3 e 4.
- **status_transicao** (PK `id_origem, id_destino`, `WITHOUT ROWID`). Transições válidas:
  - ABERTO→EM_DIAGNOSTICO
  - ABERTO→CANCELADO
  - EM_DIAGNOSTICO→ORCAMENTO_APROVADO
  - EM_DIAGNOSTICO→CANCELADO
  - ORCAMENTO_APROVADO→EM_REPARO
  - ORCAMENTO_APROVADO→CANCELADO
  - EM_REPARO→PRONTO
  - EM_REPARO→ORCAMENTO_APROVADO (novo orçamento)
  - PRONTO→ENTREGUE
  - PRONTO→EM_REPARO (retrabalho)
- **ordem_servico**:

  | Coluna | Tipo e restrições | Observação |
  |---|---|---|
  | `id` | PK | |
  | `numero` | TEXT, UQ | gerado por trigger: `'OS-' \|\| strftime('%Y') \|\| '-' \|\| printf('%06d', id)` |
  | `id_cliente` | FK | snapshot do dono; trigger valida que é o dono do equipamento na abertura |
  | `id_equipamento` | FK | |
  | `id_atendente` | FK | precisa de `OS_ABRIR` |
  | `id_tecnico` | FK, NULL | precisa de `OS_EXECUTAR` (RF06: um único técnico) |
  | `id_status` | FK, DEF 1 | |
  | `prioridade` | CHECK `'BAIXA','NORMAL','ALTA','URGENTE'`, DEF `'NORMAL'` | |
  | `defeito_relatado` | NN, length ≥ 5 | |
  | `defeito_constatado` | | |
  | `acessorios_recebidos` | | |
  | `data_abertura` | | |
  | `previsao_entrega` | | |
  | `data_fechamento` | | por trigger ao entrar em status final |
  | `subtotal_servicos` | DEF 0 | |
  | `subtotal_pecas` | DEF 0 | |
  | `desconto` | DEF 0, ≥ 0 | precisa de `DESCONTO_CONCEDER` para > 0 (trigger em UPDATE OF `desconto` com `atualizado_por`) |
  | `valor_total` | DEF 0 | |
  | `garantia_ate` | date, NULL | na entrega: data + maior `garantia_dias` entre os itens |
  | `criado_em` | | |
  | `atualizado_em` | | |
  | `atualizado_por` | | |
  | `versao` | | |

  - CHECK `valor_total = subtotal_servicos + subtotal_pecas - desconto`.
  - CHECK `desconto <= subtotal_servicos + subtotal_pecas`.
  - CHECK `(id_status IN (6,7)) = (data_fechamento IS NOT NULL)`, se viável com a ordem dos triggers. Senão, um trigger garante isso.
- **os_historico_status** (AUTOINCREMENT, imutável): `id`, `id_os`, `id_status_anterior` (NULL na abertura), `id_status_novo`, `id_funcionario`, `observacao`, `data_hora` (RF07).
- **Mudança de status:** pela inserção em `os_historico_status`.
  - BEFORE INSERT: valida a transição em `status_transicao`, a permissão `OS_ALTERAR_STATUS` e as pré-condições:
    - EM_DIAGNOSTICO exige técnico definido;
    - EM_REPARO exige orçamento APROVADO vigente;
    - ENTREGUE exige Σ pagamentos válidos = `valor_total` (RN04).
  - AFTER INSERT: atualiza `ordem_servico.id_status`, preenche `data_fechamento` e `garantia_ate` quando aplicável.
  - UPDATE direto de `id_status` é bloqueado se ele divergir do último histórico.
  - A abertura gera automaticamente o primeiro registro do histórico, com origem NULL.
- **os_orcamento**:
  - colunas: `id`, `id_os` FK, `valor_previsto`, `validade` (date), `situacao` (CHECK `'PENDENTE','APROVADO','RECUSADO','EXPIRADO'`), `aprovado_em`, `forma_aprovacao` (CHECK `'PRESENCIAL','TELEFONE','WHATSAPP','EMAIL'`, NULL), `criado_por`, `criado_em`.
  - índice único parcial: um orçamento `PENDENTE` ou `APROVADO` por OS.
  - Transição para ORCAMENTO_APROVADO exige orçamento APROVADO.
- **os_servico** (RF06):
  - colunas: `id`, `id_os`, `id_servico`, `id_tecnico`, `quantidade` (> 0), `preco_unitario` (congelado, RN02), `desconto_item` (≥ 0, ≤ qtd × preço), `data_execucao`, `cancelado` (bool, DEF 0), `motivo_cancelamento`.
  - BEFORE INSERT:
    - status com `permite_lancar_servico`;
    - `id_tecnico` = técnico da OS;
    - serviço ativo;
    - `preco_unitario` = `servico.preco_base` (o preço é congelado do catálogo; divergência é rejeitada — desconto via `desconto_item`).
  - UPDATE: só `cancelado` 0→1, com motivo, e só em OS não final. Qualquer outra alteração é bloqueada (RN02).
  - DELETE: bloqueado.
- **os_peca** (RF11):
  - colunas: `id`, `id_os`, `id_peca`, `id_tecnico`, `quantidade`, `preco_unitario` (congelado = `peca.preco_venda`), `custo_unitario` (snapshot de `custo_medio`, para a margem), `data_uso`, `estornado` (bool), `motivo_estorno`.
  - BEFORE INSERT:
    - RN01: status com `permite_baixa_peca`;
    - técnico = técnico da OS;
    - peça ativa;
    - RN03: estoque suficiente.
  - AFTER INSERT: movimento `SAIDA_OS` e recálculo dos subtotais.
  - UPDATE: só o estorno (0→1, com motivo, OS não final). Gera o movimento `ESTORNO_OS` (devolve o estoque) e recalcula os subtotais.
- **forma_pagamento**:
  - colunas: `id`, `nome` (UQ), `permite_parcelamento` (bool), `max_parcelas` (≥ 1), `taxa_bp` (≥ 0), `ativo`.
  - CHECK `permite_parcelamento = 1 OR max_parcelas = 1`.
- **os_pagamento** (RN04):
  - colunas: `id` (AUTOINCREMENT), `id_os`, `id_forma_pagamento`, `valor` (> 0), `parcelas` (≥ 1, ≤ `max_parcelas` via trigger), `data_pagamento`, `id_funcionario` (`PAGAMENTO_REGISTRAR`), `estornado` (bool), `estornado_em`, `motivo_estorno`.
  - BEFORE INSERT:
    - OS não final;
    - Σ pagamentos válidos + valor ≤ `valor_total`;
    - status ≥ PRONTO (pagamento na entrega/fechamento).
  - UPDATE: só o estorno, uma vez. DELETE: bloqueado.

### 2.8 Auditoria e metadados
- **auditoria**:
  - colunas: `id` (AUTOINCREMENT), `tabela`, `id_registro`, `operacao` (CHECK `'INSERT','UPDATE','DELETE'`), `dados_antes` (TEXT, `CHECK (dados_antes IS NULL OR json_valid(dados_antes))`), `dados_depois` (idem), `id_funcionario` (NULL), `data_hora`.
  - preenchida por triggers AFTER INSERT/UPDATE com `json_object(...)` das colunas, nas tabelas: `funcionario`, `usuario` (**sem** `senha_hash`), `cliente`, `equipamento`, `servico`, `peca`, `ordem_servico`, `os_pagamento`, `forma_pagamento`.
  - O `id_funcionario` vem de `criado_por`/`atualizado_por` quando existir.
  - A própria auditoria é imutável.
- **schema_versao**: `versao` (PK), `descricao`, `aplicado_em`.
- **Bloqueio de DELETE físico:** em todas as tabelas de negócio, um trigger `trg_<tabela>_bd_bloqueia` levanta `'DEL: exclusão física não permitida; use ativo = 0'`. Exceções: `cargo_permissao` (configuração).

## 3. Índices
Todas as colunas FK, mais:
- `ordem_servico(id_status, data_abertura)`
- `ordem_servico(id_tecnico, id_status)`
- `movimento_estoque(id_peca, data_hora)`
- `auditoria(tabela, id_registro)`
- `os_pagamento(id_os) WHERE estornado = 0`
- `peca(estoque_atual) WHERE ativo = 1`
- `cliente(nome)`

## 4. Views
| View | Conteúdo |
|---|---|
| `vw_os_painel` | número, cliente, contato principal, equipamento (tipo, marca, modelo), status, prioridade, técnico, dias em aberto, valores, saldo a pagar |
| `vw_os_extrato` | itens da OS (serviços e peças não cancelados/estornados), UNION com tipo, descrição, qtd, unitário, desconto, total |
| `vw_estoque_reposicao` | peças ativas com `estoque_atual <= estoque_minimo` e a sugestão de compra |
| `vw_kardex` | movimentos com peça, tipo, entradas/saídas, saldos, custo médio e responsável |
| `vw_faturamento_mensal` | por mês (`strftime('%Y-%m')`): OS entregues, receita de serviços, receita de peças, custo de peças, margem bruta, descontos |
| `vw_produtividade_tecnico` | por técnico: OS atendidas, entregues, tempo médio abertura→fechamento em horas, receita |
| `vw_garantias_ativas` | OS entregues com `garantia_ate >= date('now')` |
| `vw_auditoria` | auditoria com o nome do funcionário |

## 5. Dados iniciais (seed)
- Cargos, permissões, `cargo_permissao`, status, transições, formas de pagamento (Dinheiro, Pix, Débito, Crédito até 12x com taxa, Boleto).
- 1 gerente, 2 atendentes e 3 técnicos, cada um com usuário. O `senha_hash` é um placeholder com formato bcrypt fictício e um comentário avisando para trocar.
- Categorias hierárquicas: raiz "Serviços" e "Peças", com as subcategorias da tabela de peças e serviços.
- **Os 23 serviços e as 34 peças** da tabela de peças e serviços, com códigos `SRV-001…` / `PEC-001…`, `estoque_minimo` plausível e o estoque inicial **lançado por compra**: 1 a 2 compras de fornecedores fictícios, com NF, cujos itens trazem as quantidades e os custos da tabela.
- Clientes PF e PJ, com contatos e endereços; marcas, tipos, modelos e equipamentos, com IMEIs **válidos no algoritmo de Luhn**.
- No mínimo 6 OS percorrendo os fluxos:
  - entregue, com pagamento dividido e parcelado e garantia;
  - em reparo, com peça estornada;
  - aguardando orçamento;
  - aberta;
  - cancelada;
  - com desconto concedido pelo gerente.
- Mais 1 descarte e 1 ajuste de inventário.

## 6. Entregáveis (`banco_upgrade/`)
- `01_estrutura.sql` (tabelas e índices)
- `02_regras.sql` (triggers de negócio)
- `03_auditoria.sql` (triggers de auditoria, versão e `atualizado_em`, bloqueio de DELETE)
- `04_views.sql`
- `05_dados.sql`
- `techfix_upgrade_completo.sql` (script único; roda sozinho e pode ser executado de novo)
- `techfix_upgrade.sqlite`
- `README.md`.
