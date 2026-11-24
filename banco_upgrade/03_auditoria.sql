-- =============================================================================
-- TechFix - Banco Upgrade
-- 03_auditoria.sql : auditoria JSON, versionamento (versao/atualizado_em),
-- imutabilidade de logs e bloqueio de DELETE fisico
-- Fonte de verdade: docs/especificacao_upgrade.md (2.8, 1)
--
-- Notas de projeto:
--  * Versionamento: um trigger AFTER UPDATE por tabela versionada incrementa
--    versao e atualiza atualizado_em quando o UPDATE de origem NAO alterou
--    versao (WHEN NEW.versao = OLD.versao). O UPDATE interno do proprio trigger
--    altera versao e por isso nao dispara auditoria nem novo incremento
--    (recursive_triggers = OFF). A aplicacao NAO deve gravar versao; o lock
--    otimista e feito com "UPDATE ... WHERE id = ? AND versao = ?" e checando
--    changes().
--  * Auditoria de UPDATE em tabela versionada registra, em dados_depois, a
--    versao ja incrementada (NEW.versao + 1) e atualizado_em corrente.
--  * ordem_servico: a atribuicao do numero (UPDATE interno do trigger de
--    abertura, OLD.numero IS NULL) nao conta como alteracao/versao; o INSERT
--    auditado ja traz o numero calculado.
--  * usuario: senha_hash NUNCA entra na auditoria; dados_depois traz apenas o
--    indicador senha_alterada.
--  * Bloqueio de DELETE: trg_<tabela>_bd_bloqueia em todas as tabelas, exceto
--    cargo_permissao (configuracao) e schema_versao (metadado).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Versionamento / atualizado_em
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_cliente_au_versao AFTER UPDATE ON cliente
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE cliente SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_equipamento_au_versao AFTER UPDATE ON equipamento
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE equipamento SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_ordem_servico_au_versao AFTER UPDATE ON ordem_servico
WHEN NEW.versao = OLD.versao AND OLD.numero IS NOT NULL
BEGIN
    UPDATE ordem_servico SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_peca_au_versao AFTER UPDATE ON peca
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE peca SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

CREATE TRIGGER trg_servico_au_versao AFTER UPDATE ON servico
WHEN NEW.versao = OLD.versao
BEGIN
    UPDATE servico SET versao = OLD.versao + 1, atualizado_em = datetime('now','localtime') WHERE id = NEW.id;
END;

-- ---------------------------------------------------------------------------
-- Auditoria (json_object das colunas; senha_hash excluido)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_funcionario_ai_auditoria AFTER INSERT ON funcionario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('funcionario', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'cpf', NEW.cpf,
                      'email', NEW.email,
                      'telefone', NEW.telefone,
                      'id_cargo', NEW.id_cargo,
                      'data_admissao', NEW.data_admissao,
                      'data_demissao', NEW.data_demissao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_por', NEW.atualizado_por),
            NEW.criado_por);
END;

CREATE TRIGGER trg_funcionario_au_auditoria AFTER UPDATE ON funcionario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('funcionario', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'nome', OLD.nome,
                      'cpf', OLD.cpf,
                      'email', OLD.email,
                      'telefone', OLD.telefone,
                      'id_cargo', OLD.id_cargo,
                      'data_admissao', OLD.data_admissao,
                      'data_demissao', OLD.data_demissao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_por', OLD.atualizado_por),
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'cpf', NEW.cpf,
                      'email', NEW.email,
                      'telefone', NEW.telefone,
                      'id_cargo', NEW.id_cargo,
                      'data_admissao', NEW.data_admissao,
                      'data_demissao', NEW.data_demissao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_por', NEW.atualizado_por),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_usuario_ai_auditoria AFTER INSERT ON usuario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('usuario', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_funcionario', NEW.id_funcionario,
                      'login', NEW.login,
                      'tentativas_falhas', NEW.tentativas_falhas,
                      'bloqueado_ate', NEW.bloqueado_ate,
                      'ultimo_login', NEW.ultimo_login,
                      'ativo', NEW.ativo,
                      'senha_alterada', 0),
            NULL);
END;

CREATE TRIGGER trg_usuario_au_auditoria AFTER UPDATE ON usuario
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('usuario', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_funcionario', OLD.id_funcionario,
                      'login', OLD.login,
                      'tentativas_falhas', OLD.tentativas_falhas,
                      'bloqueado_ate', OLD.bloqueado_ate,
                      'ultimo_login', OLD.ultimo_login,
                      'ativo', OLD.ativo),
            json_object('id', NEW.id,
                      'id_funcionario', NEW.id_funcionario,
                      'login', NEW.login,
                      'tentativas_falhas', NEW.tentativas_falhas,
                      'bloqueado_ate', NEW.bloqueado_ate,
                      'ultimo_login', NEW.ultimo_login,
                      'ativo', NEW.ativo,
                      'senha_alterada', CASE WHEN NEW.senha_hash <> OLD.senha_hash THEN 1 ELSE 0 END),
            NULL);
END;

CREATE TRIGGER trg_cliente_ai_auditoria AFTER INSERT ON cliente
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('cliente', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'tipo_pessoa', NEW.tipo_pessoa,
                      'nome', NEW.nome,
                      'documento', NEW.documento,
                      'data_nascimento', NEW.data_nascimento,
                      'aceita_comunicacao', NEW.aceita_comunicacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_cliente_au_auditoria AFTER UPDATE ON cliente
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('cliente', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'tipo_pessoa', OLD.tipo_pessoa,
                      'nome', OLD.nome,
                      'documento', OLD.documento,
                      'data_nascimento', OLD.data_nascimento,
                      'aceita_comunicacao', OLD.aceita_comunicacao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'tipo_pessoa', NEW.tipo_pessoa,
                      'nome', NEW.nome,
                      'documento', NEW.documento,
                      'data_nascimento', NEW.data_nascimento,
                      'aceita_comunicacao', NEW.aceita_comunicacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_equipamento_ai_auditoria AFTER INSERT ON equipamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('equipamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_cliente', NEW.id_cliente,
                      'id_modelo', NEW.id_modelo,
                      'numero_serie', NEW.numero_serie,
                      'imei', NEW.imei,
                      'cor', NEW.cor,
                      'observacao', NEW.observacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_equipamento_au_auditoria AFTER UPDATE ON equipamento
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('equipamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_cliente', OLD.id_cliente,
                      'id_modelo', OLD.id_modelo,
                      'numero_serie', OLD.numero_serie,
                      'imei', OLD.imei,
                      'cor', OLD.cor,
                      'observacao', OLD.observacao,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'id_cliente', NEW.id_cliente,
                      'id_modelo', NEW.id_modelo,
                      'numero_serie', NEW.numero_serie,
                      'imei', NEW.imei,
                      'cor', NEW.cor,
                      'observacao', NEW.observacao,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_servico_ai_auditoria AFTER INSERT ON servico
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('servico', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'codigo', NEW.codigo,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'preco_base', NEW.preco_base,
                      'tempo_estimado_min', NEW.tempo_estimado_min,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_servico_au_auditoria AFTER UPDATE ON servico
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('servico', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'codigo', OLD.codigo,
                      'nome', OLD.nome,
                      'id_categoria', OLD.id_categoria,
                      'preco_base', OLD.preco_base,
                      'tempo_estimado_min', OLD.tempo_estimado_min,
                      'garantia_dias', OLD.garantia_dias,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'codigo', NEW.codigo,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'preco_base', NEW.preco_base,
                      'tempo_estimado_min', NEW.tempo_estimado_min,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_peca_ai_auditoria AFTER INSERT ON peca
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('peca', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'sku', NEW.sku,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'unidade', NEW.unidade,
                      'preco_venda', NEW.preco_venda,
                      'custo_medio', NEW.custo_medio,
                      'estoque_atual', NEW.estoque_atual,
                      'estoque_minimo', NEW.estoque_minimo,
                      'localizacao', NEW.localizacao,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.criado_por);
END;

CREATE TRIGGER trg_peca_au_auditoria AFTER UPDATE ON peca
WHEN NEW.versao = OLD.versao
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('peca', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'sku', OLD.sku,
                      'nome', OLD.nome,
                      'id_categoria', OLD.id_categoria,
                      'unidade', OLD.unidade,
                      'preco_venda', OLD.preco_venda,
                      'custo_medio', OLD.custo_medio,
                      'estoque_atual', OLD.estoque_atual,
                      'estoque_minimo', OLD.estoque_minimo,
                      'localizacao', OLD.localizacao,
                      'garantia_dias', OLD.garantia_dias,
                      'ativo', OLD.ativo,
                      'criado_em', OLD.criado_em,
                      'criado_por', OLD.criado_por,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'sku', NEW.sku,
                      'nome', NEW.nome,
                      'id_categoria', NEW.id_categoria,
                      'unidade', NEW.unidade,
                      'preco_venda', NEW.preco_venda,
                      'custo_medio', NEW.custo_medio,
                      'estoque_atual', NEW.estoque_atual,
                      'estoque_minimo', NEW.estoque_minimo,
                      'localizacao', NEW.localizacao,
                      'garantia_dias', NEW.garantia_dias,
                      'ativo', NEW.ativo,
                      'criado_em', NEW.criado_em,
                      'criado_por', NEW.criado_por,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.criado_por));
END;

CREATE TRIGGER trg_ordem_servico_ai_auditoria AFTER INSERT ON ordem_servico
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('ordem_servico', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'numero', COALESCE(NEW.numero, 'OS-' || strftime('%Y', NEW.data_abertura) || '-' || printf('%06d', NEW.id)),
                      'id_cliente', NEW.id_cliente,
                      'id_equipamento', NEW.id_equipamento,
                      'id_atendente', NEW.id_atendente,
                      'id_tecnico', NEW.id_tecnico,
                      'id_status', NEW.id_status,
                      'prioridade', NEW.prioridade,
                      'defeito_relatado', NEW.defeito_relatado,
                      'defeito_constatado', NEW.defeito_constatado,
                      'acessorios_recebidos', NEW.acessorios_recebidos,
                      'data_abertura', NEW.data_abertura,
                      'previsao_entrega', NEW.previsao_entrega,
                      'data_fechamento', NEW.data_fechamento,
                      'subtotal_servicos', NEW.subtotal_servicos,
                      'subtotal_pecas', NEW.subtotal_pecas,
                      'desconto', NEW.desconto,
                      'valor_total', NEW.valor_total,
                      'garantia_ate', NEW.garantia_ate,
                      'criado_em', NEW.criado_em,
                      'atualizado_em', NEW.atualizado_em,
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao),
            NEW.id_atendente);
END;

CREATE TRIGGER trg_ordem_servico_au_auditoria AFTER UPDATE ON ordem_servico
WHEN NEW.versao = OLD.versao AND OLD.numero IS NOT NULL
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('ordem_servico', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'numero', OLD.numero,
                      'id_cliente', OLD.id_cliente,
                      'id_equipamento', OLD.id_equipamento,
                      'id_atendente', OLD.id_atendente,
                      'id_tecnico', OLD.id_tecnico,
                      'id_status', OLD.id_status,
                      'prioridade', OLD.prioridade,
                      'defeito_relatado', OLD.defeito_relatado,
                      'defeito_constatado', OLD.defeito_constatado,
                      'acessorios_recebidos', OLD.acessorios_recebidos,
                      'data_abertura', OLD.data_abertura,
                      'previsao_entrega', OLD.previsao_entrega,
                      'data_fechamento', OLD.data_fechamento,
                      'subtotal_servicos', OLD.subtotal_servicos,
                      'subtotal_pecas', OLD.subtotal_pecas,
                      'desconto', OLD.desconto,
                      'valor_total', OLD.valor_total,
                      'garantia_ate', OLD.garantia_ate,
                      'criado_em', OLD.criado_em,
                      'atualizado_em', OLD.atualizado_em,
                      'atualizado_por', OLD.atualizado_por,
                      'versao', OLD.versao),
            json_object('id', NEW.id,
                      'numero', COALESCE(NEW.numero, 'OS-' || strftime('%Y', NEW.data_abertura) || '-' || printf('%06d', NEW.id)),
                      'id_cliente', NEW.id_cliente,
                      'id_equipamento', NEW.id_equipamento,
                      'id_atendente', NEW.id_atendente,
                      'id_tecnico', NEW.id_tecnico,
                      'id_status', NEW.id_status,
                      'prioridade', NEW.prioridade,
                      'defeito_relatado', NEW.defeito_relatado,
                      'defeito_constatado', NEW.defeito_constatado,
                      'acessorios_recebidos', NEW.acessorios_recebidos,
                      'data_abertura', NEW.data_abertura,
                      'previsao_entrega', NEW.previsao_entrega,
                      'data_fechamento', NEW.data_fechamento,
                      'subtotal_servicos', NEW.subtotal_servicos,
                      'subtotal_pecas', NEW.subtotal_pecas,
                      'desconto', NEW.desconto,
                      'valor_total', NEW.valor_total,
                      'garantia_ate', NEW.garantia_ate,
                      'criado_em', NEW.criado_em,
                      'atualizado_em', datetime('now','localtime'),
                      'atualizado_por', NEW.atualizado_por,
                      'versao', NEW.versao + 1),
            COALESCE(NEW.atualizado_por, NEW.id_atendente));
END;

CREATE TRIGGER trg_os_pagamento_ai_auditoria AFTER INSERT ON os_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('os_pagamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'id_os', NEW.id_os,
                      'id_forma_pagamento', NEW.id_forma_pagamento,
                      'valor', NEW.valor,
                      'parcelas', NEW.parcelas,
                      'data_pagamento', NEW.data_pagamento,
                      'id_funcionario', NEW.id_funcionario,
                      'estornado', NEW.estornado,
                      'estornado_em', NEW.estornado_em,
                      'motivo_estorno', NEW.motivo_estorno),
            NEW.id_funcionario);
END;

CREATE TRIGGER trg_os_pagamento_au_auditoria AFTER UPDATE ON os_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('os_pagamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'id_os', OLD.id_os,
                      'id_forma_pagamento', OLD.id_forma_pagamento,
                      'valor', OLD.valor,
                      'parcelas', OLD.parcelas,
                      'data_pagamento', OLD.data_pagamento,
                      'id_funcionario', OLD.id_funcionario,
                      'estornado', OLD.estornado,
                      'estornado_em', OLD.estornado_em,
                      'motivo_estorno', OLD.motivo_estorno),
            json_object('id', NEW.id,
                      'id_os', NEW.id_os,
                      'id_forma_pagamento', NEW.id_forma_pagamento,
                      'valor', NEW.valor,
                      'parcelas', NEW.parcelas,
                      'data_pagamento', NEW.data_pagamento,
                      'id_funcionario', NEW.id_funcionario,
                      'estornado', NEW.estornado,
                      'estornado_em', NEW.estornado_em,
                      'motivo_estorno', NEW.motivo_estorno),
            NEW.id_funcionario);
END;

CREATE TRIGGER trg_forma_pagamento_ai_auditoria AFTER INSERT ON forma_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('forma_pagamento', NEW.id, 'INSERT', NULL,
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'permite_parcelamento', NEW.permite_parcelamento,
                      'max_parcelas', NEW.max_parcelas,
                      'taxa_bp', NEW.taxa_bp,
                      'ativo', NEW.ativo),
            NULL);
END;

CREATE TRIGGER trg_forma_pagamento_au_auditoria AFTER UPDATE ON forma_pagamento
BEGIN
    INSERT INTO auditoria (tabela, id_registro, operacao, dados_antes, dados_depois, id_funcionario)
    VALUES ('forma_pagamento', NEW.id, 'UPDATE',
            json_object('id', OLD.id,
                      'nome', OLD.nome,
                      'permite_parcelamento', OLD.permite_parcelamento,
                      'max_parcelas', OLD.max_parcelas,
                      'taxa_bp', OLD.taxa_bp,
                      'ativo', OLD.ativo),
            json_object('id', NEW.id,
                      'nome', NEW.nome,
                      'permite_parcelamento', NEW.permite_parcelamento,
                      'max_parcelas', NEW.max_parcelas,
                      'taxa_bp', NEW.taxa_bp,
                      'ativo', NEW.ativo),
            NULL);
END;

-- ---------------------------------------------------------------------------
-- Logs imutaveis
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_auditoria_bu_imutavel BEFORE UPDATE ON auditoria
BEGIN
    SELECT RAISE(ABORT, 'IMUT: auditoria é imutável');
END;

CREATE TRIGGER trg_historico_preco_bu_imutavel BEFORE UPDATE ON historico_preco
BEGIN
    SELECT RAISE(ABORT, 'IMUT: historico_preco é imutável');
END;

-- ---------------------------------------------------------------------------
-- Bloqueio de DELETE fisico (exclusao e logica: ativo = 0)
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_cargo_bd_bloqueia BEFORE DELETE ON cargo
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_permissao_bd_bloqueia BEFORE DELETE ON permissao
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_funcionario_bd_bloqueia BEFORE DELETE ON funcionario
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_usuario_bd_bloqueia BEFORE DELETE ON usuario
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_bd_bloqueia BEFORE DELETE ON cliente
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_contato_bd_bloqueia BEFORE DELETE ON cliente_contato
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_cliente_endereco_bd_bloqueia BEFORE DELETE ON cliente_endereco
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_marca_bd_bloqueia BEFORE DELETE ON marca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_tipo_equipamento_bd_bloqueia BEFORE DELETE ON tipo_equipamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_modelo_bd_bloqueia BEFORE DELETE ON modelo
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_equipamento_bd_bloqueia BEFORE DELETE ON equipamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_categoria_bd_bloqueia BEFORE DELETE ON categoria
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_servico_bd_bloqueia BEFORE DELETE ON servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_peca_bd_bloqueia BEFORE DELETE ON peca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_historico_preco_bd_bloqueia BEFORE DELETE ON historico_preco
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_fornecedor_bd_bloqueia BEFORE DELETE ON fornecedor
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_compra_bd_bloqueia BEFORE DELETE ON compra
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_compra_item_bd_bloqueia BEFORE DELETE ON compra_item
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_status_os_bd_bloqueia BEFORE DELETE ON status_os
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_status_transicao_bd_bloqueia BEFORE DELETE ON status_transicao
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_ordem_servico_bd_bloqueia BEFORE DELETE ON ordem_servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_historico_status_bd_bloqueia BEFORE DELETE ON os_historico_status
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_orcamento_bd_bloqueia BEFORE DELETE ON os_orcamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_servico_bd_bloqueia BEFORE DELETE ON os_servico
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_peca_bd_bloqueia BEFORE DELETE ON os_peca
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_movimento_estoque_bd_bloqueia BEFORE DELETE ON movimento_estoque
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_forma_pagamento_bd_bloqueia BEFORE DELETE ON forma_pagamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_os_pagamento_bd_bloqueia BEFORE DELETE ON os_pagamento
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;

CREATE TRIGGER trg_auditoria_bd_bloqueia BEFORE DELETE ON auditoria
BEGIN
    SELECT RAISE(ABORT, 'DEL: exclusão física não permitida; use ativo = 0');
END;
