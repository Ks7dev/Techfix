-- ============================================================================
-- TechFix - Sistema de Gestao de Assistencia Tecnica
-- Script DDL (MySQL 8.0+)
-- Cada bloco traz o(s) RF/RN do briefing que a tabela/trigger atende.
-- ============================================================================

DROP DATABASE IF EXISTS techfix;
CREATE DATABASE techfix DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE techfix;

SET NAMES utf8mb4;

-- ============================================================================
-- MODULO A: PESSOAL E ATENDIMENTO
-- ============================================================================

-- RF01: cargos definem o tipo de perfil (atendente, tecnico, gerente),
-- usado pelas triggers abaixo para validar quem pode cadastrar o que.
CREATE TABLE cargo (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome_cargo  VARCHAR(60) NOT NULL,
    tipo        ENUM('ATENDENTE','TECNICO','GERENTE') NOT NULL,
    status      TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_cargo_nome (nome_cargo)
) ENGINE=InnoDB;

-- RF01: cadastro de funcionarios para controle de acesso e auditoria.
CREATE TABLE funcionario (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome           VARCHAR(120) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    login          VARCHAR(60) NOT NULL,
    senha_hash     VARCHAR(255) NOT NULL,
    id_cargo       INT UNSIGNED NOT NULL,
    data_cadastro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status         TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_funcionario_email (email),
    UNIQUE KEY uq_funcionario_login (login),
    CONSTRAINT fk_funcionario_cargo FOREIGN KEY (id_cargo) REFERENCES cargo (id)
) ENGINE=InnoDB;

-- RF02: cadastro de clientes. id_funcionario_cadastro guarda quem fez o
-- registro (validado por trigger: so atendente ou gerente).
CREATE TABLE cliente (
    id                     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome                   VARCHAR(120) NOT NULL,
    cpf                    VARCHAR(14) NOT NULL,
    email                  VARCHAR(150) NOT NULL,
    telefone               VARCHAR(20) NOT NULL,
    endereco               VARCHAR(200),
    id_funcionario_cadastro INT UNSIGNED NOT NULL,
    data_cadastro          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status                 TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_cliente_cpf (cpf),
    UNIQUE KEY uq_cliente_email (email),
    CONSTRAINT fk_cliente_funcionario FOREIGN KEY (id_funcionario_cadastro) REFERENCES funcionario (id)
) ENGINE=InnoDB;

-- ============================================================================
-- Dominios de equipamento (RF03)
-- ============================================================================

CREATE TABLE marca (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(80) NOT NULL,
    status  TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_marca_nome (nome)
) ENGINE=InnoDB;

CREATE TABLE modelo (
    id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome      VARCHAR(80) NOT NULL,
    id_marca  INT UNSIGNED NOT NULL,
    status    TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_modelo_marca (id_marca, nome),
    CONSTRAINT fk_modelo_marca FOREIGN KEY (id_marca) REFERENCES marca (id)
) ENGINE=InnoDB;

CREATE TABLE tipo_equipamento (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome    VARCHAR(60) NOT NULL,
    status  TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_tipo_nome (nome)
) ENGINE=InnoDB;

-- RF03: aparelho do cliente (marca, modelo, tipo, serial/IMEI).
CREATE TABLE equipamento (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_cliente              INT UNSIGNED NOT NULL,
    id_marca                INT UNSIGNED NOT NULL,
    id_modelo               INT UNSIGNED NOT NULL,
    id_tipo                 INT UNSIGNED NOT NULL,
    numero_serie            VARCHAR(60),
    imei                    VARCHAR(20),
    id_funcionario_cadastro INT UNSIGNED NOT NULL,
    data_cadastro           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status                  TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_equipamento_imei (imei),
    CONSTRAINT fk_equipamento_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id),
    CONSTRAINT fk_equipamento_marca FOREIGN KEY (id_marca) REFERENCES marca (id),
    CONSTRAINT fk_equipamento_modelo FOREIGN KEY (id_modelo) REFERENCES modelo (id),
    CONSTRAINT fk_equipamento_tipo FOREIGN KEY (id_tipo) REFERENCES tipo_equipamento (id),
    CONSTRAINT fk_equipamento_funcionario FOREIGN KEY (id_funcionario_cadastro) REFERENCES funcionario (id)
) ENGINE=InnoDB;

-- ============================================================================
-- MODULO B: ORDENS DE SERVICO (OS) E SERVICOS
-- ============================================================================

-- RF07: dominio fechado dos status possiveis de uma OS.
CREATE TABLE status_os (
    id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome  VARCHAR(30) NOT NULL,
    UNIQUE KEY uq_status_os_nome (nome)
) ENGINE=InnoDB;

INSERT INTO status_os (nome) VALUES
    ('Aberto'), ('Em Diagnostico'), ('Orcamento Aprovado'),
    ('Em Reparo'), ('Pronto'), ('Entregue'), ('Cancelado');

-- RN04: forma de pagamento registrada no encerramento da OS.
CREATE TABLE forma_pagamento (
    id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome  VARCHAR(30) NOT NULL,
    UNIQUE KEY uq_forma_pagamento_nome (nome)
) ENGINE=InnoDB;

INSERT INTO forma_pagamento (nome) VALUES
    ('Dinheiro'), ('Pix'), ('Cartao de Debito'), ('Cartao de Credito');

-- RF04: abertura da OS. id_tecnico fica NULL ate a atribuicao do tecnico
-- responsavel (RF06: uma OS so pode ter um tecnico).
CREATE TABLE ordem_servico (
    id                       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_cliente               INT UNSIGNED NOT NULL,
    id_equipamento           INT UNSIGNED NOT NULL,
    id_funcionario_abertura  INT UNSIGNED NOT NULL,
    id_tecnico               INT UNSIGNED NULL,
    id_status_atual          INT UNSIGNED NOT NULL DEFAULT 1,
    id_forma_pagamento       INT UNSIGNED NULL,
    defeito_relatado         TEXT NOT NULL,
    diagnostico              TEXT,
    data_abertura            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_fechamento          DATETIME NULL,
    valor_total              DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_os_cliente FOREIGN KEY (id_cliente) REFERENCES cliente (id),
    CONSTRAINT fk_os_equipamento FOREIGN KEY (id_equipamento) REFERENCES equipamento (id),
    CONSTRAINT fk_os_funcionario_abertura FOREIGN KEY (id_funcionario_abertura) REFERENCES funcionario (id),
    CONSTRAINT fk_os_tecnico FOREIGN KEY (id_tecnico) REFERENCES funcionario (id),
    CONSTRAINT fk_os_status FOREIGN KEY (id_status_atual) REFERENCES status_os (id),
    CONSTRAINT fk_os_forma_pagamento FOREIGN KEY (id_forma_pagamento) REFERENCES forma_pagamento (id)
) ENGINE=InnoDB;

-- RF07: historico imutavel de mudancas de status. E a fonte da verdade;
-- ordem_servico.id_status_atual e um cache mantido por trigger (abaixo).
CREATE TABLE os_status_historico (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_os         INT UNSIGNED NOT NULL,
    id_status     INT UNSIGNED NOT NULL,
    id_funcionario INT UNSIGNED NOT NULL,
    data_hora     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    observacao    VARCHAR(255),
    CONSTRAINT fk_hist_os FOREIGN KEY (id_os) REFERENCES ordem_servico (id),
    CONSTRAINT fk_hist_status FOREIGN KEY (id_status) REFERENCES status_os (id),
    CONSTRAINT fk_hist_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id)
) ENGINE=InnoDB;

-- RF05: catalogo de servicos com valor base (cadastro restrito a gerente).
CREATE TABLE servico (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome                    VARCHAR(100) NOT NULL,
    descricao               VARCHAR(255),
    valor_base              DECIMAL(10,2) NOT NULL,
    id_funcionario_cadastro INT UNSIGNED NOT NULL,
    data_cadastro           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status                  TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_servico_nome (nome),
    CONSTRAINT fk_servico_funcionario FOREIGN KEY (id_funcionario_cadastro) REFERENCES funcionario (id)
) ENGINE=InnoDB;

-- RF06 / RN02: servicos aplicados na OS com valor_aplicado congelado na
-- data da execucao (nao acompanha alteracoes futuras em servico.valor_base).
CREATE TABLE os_servico (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_os           INT UNSIGNED NOT NULL,
    id_servico      INT UNSIGNED NOT NULL,
    id_tecnico      INT UNSIGNED NOT NULL,
    valor_aplicado  DECIMAL(10,2) NOT NULL,
    data_execucao   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_os_servico_os FOREIGN KEY (id_os) REFERENCES ordem_servico (id),
    CONSTRAINT fk_os_servico_servico FOREIGN KEY (id_servico) REFERENCES servico (id),
    CONSTRAINT fk_os_servico_tecnico FOREIGN KEY (id_tecnico) REFERENCES funcionario (id)
) ENGINE=InnoDB;

-- ============================================================================
-- MODULO C: CONTROLE RIGOROSO DE ESTOQUE
-- ============================================================================

-- RF08: catalogo de pecas com saldo atual em tempo real.
CREATE TABLE peca (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome            VARCHAR(100) NOT NULL,
    descricao       VARCHAR(255),
    preco_custo     DECIMAL(10,2) NOT NULL,
    preco_venda     DECIMAL(10,2) NOT NULL,
    saldo_estoque   INT NOT NULL DEFAULT 0,
    status          TINYINT NOT NULL DEFAULT 1,
    UNIQUE KEY uq_peca_nome (nome),
    CONSTRAINT ck_peca_saldo CHECK (saldo_estoque >= 0)
) ENGINE=InnoDB;

-- RF09: entrada/reposicao de pecas (cadastro restrito a gerente).
CREATE TABLE peca_entrada (
    id                      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_peca                 INT UNSIGNED NOT NULL,
    quantidade              INT NOT NULL,
    preco_custo             DECIMAL(10,2) NOT NULL,
    preco_venda_sugerido    DECIMAL(10,2) NOT NULL,
    data_entrada            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_funcionario          INT UNSIGNED NOT NULL,
    CONSTRAINT fk_entrada_peca FOREIGN KEY (id_peca) REFERENCES peca (id),
    CONSTRAINT fk_entrada_funcionario FOREIGN KEY (id_funcionario) REFERENCES funcionario (id),
    CONSTRAINT ck_entrada_quantidade CHECK (quantidade > 0)
) ENGINE=InnoDB;

-- RF10: motivo da baixa de estoque (dominio fechado).
CREATE TABLE motivo_saida_peca (
    id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nome  VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_motivo_saida_nome (nome)
) ENGINE=InnoDB;

INSERT INTO motivo_saida_peca (nome) VALUES
    ('Uso em Reparo'), ('Descarte por Defeito/Avaria');

-- RF10 / RF11: baixa de pecas. id_os obrigatorio apenas quando o motivo e
-- "Uso em Reparo" (validado por trigger); valor_unitario e congelado no
-- momento da baixa (RN02).
CREATE TABLE peca_saida (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_peca         INT UNSIGNED NOT NULL,
    id_motivo       INT UNSIGNED NOT NULL,
    id_os           INT UNSIGNED NULL,
    id_tecnico      INT UNSIGNED NOT NULL,
    quantidade      INT NOT NULL,
    valor_unitario  DECIMAL(10,2) NOT NULL,
    data_saida      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_saida_peca FOREIGN KEY (id_peca) REFERENCES peca (id),
    CONSTRAINT fk_saida_motivo FOREIGN KEY (id_motivo) REFERENCES motivo_saida_peca (id),
    CONSTRAINT fk_saida_os FOREIGN KEY (id_os) REFERENCES ordem_servico (id),
    CONSTRAINT fk_saida_tecnico FOREIGN KEY (id_tecnico) REFERENCES funcionario (id),
    CONSTRAINT ck_saida_quantidade CHECK (quantidade > 0)
) ENGINE=InnoDB;

-- ============================================================================
-- PROCEDURE - RN04: valor_total = soma dos servicos + soma das pecas usadas
-- (definida antes das triggers pois e chamada por elas)
-- ============================================================================

DELIMITER $$

CREATE PROCEDURE sp_recalcular_valor_os(IN p_id_os INT UNSIGNED)
BEGIN
    DECLARE v_servicos DECIMAL(10,2);
    DECLARE v_pecas DECIMAL(10,2);

    SELECT COALESCE(SUM(valor_aplicado), 0) INTO v_servicos
      FROM os_servico WHERE id_os = p_id_os;

    SELECT COALESCE(SUM(valor_unitario * quantidade), 0) INTO v_pecas
      FROM peca_saida WHERE id_os = p_id_os;

    UPDATE ordem_servico
       SET valor_total = v_servicos + v_pecas
     WHERE id = p_id_os;
END$$

DELIMITER ;

-- ============================================================================
-- TRIGGERS - Regras de Negocio Rigidas (RN01 a RN04)
-- ============================================================================

DELIMITER $$

-- RF02: cliente so pode ser cadastrado por atendente ou gerente.
CREATE TRIGGER trg_cliente_before_insert
BEFORE INSERT ON cliente
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10);
    SELECT c.tipo INTO v_tipo
      FROM funcionario f JOIN cargo c ON c.id = f.id_cargo
     WHERE f.id = NEW.id_funcionario_cadastro;
    IF v_tipo NOT IN ('ATENDENTE','GERENTE') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cadastro de cliente permitido apenas para atendente ou gerente.';
    END IF;
END$$

-- RF03: equipamento so pode ser cadastrado por atendente ou gerente.
CREATE TRIGGER trg_equipamento_before_insert
BEFORE INSERT ON equipamento
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10);
    SELECT c.tipo INTO v_tipo
      FROM funcionario f JOIN cargo c ON c.id = f.id_cargo
     WHERE f.id = NEW.id_funcionario_cadastro;
    IF v_tipo NOT IN ('ATENDENTE','GERENTE') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cadastro de equipamento permitido apenas para atendente ou gerente.';
    END IF;
END$$

-- RF05: servico so pode ser cadastrado por gerente.
CREATE TRIGGER trg_servico_before_insert
BEFORE INSERT ON servico
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10);
    SELECT c.tipo INTO v_tipo
      FROM funcionario f JOIN cargo c ON c.id = f.id_cargo
     WHERE f.id = NEW.id_funcionario_cadastro;
    IF v_tipo <> 'GERENTE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cadastro de servico permitido apenas para gerente.';
    END IF;
END$$

-- RF09: entrada de pecas so pode ser feita por gerente; ao confirmar,
-- soma a quantidade ao saldo_estoque da peca.
CREATE TRIGGER trg_peca_entrada_before_insert
BEFORE INSERT ON peca_entrada
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10);
    SELECT c.tipo INTO v_tipo
      FROM funcionario f JOIN cargo c ON c.id = f.id_cargo
     WHERE f.id = NEW.id_funcionario;
    IF v_tipo <> 'GERENTE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Entrada de pecas permitida apenas para gerente.';
    END IF;
END$$

CREATE TRIGGER trg_peca_entrada_after_insert
AFTER INSERT ON peca_entrada
FOR EACH ROW
BEGIN
    UPDATE peca SET saldo_estoque = saldo_estoque + NEW.quantidade WHERE id = NEW.id_peca;
END$$

-- RN01 + RN03: valida status da OS quando o motivo e "Uso em Reparo" e
-- garante que ha saldo suficiente antes da baixa.
CREATE TRIGGER trg_peca_saida_before_insert
BEFORE INSERT ON peca_saida
FOR EACH ROW
BEGIN
    DECLARE v_motivo VARCHAR(40);
    DECLARE v_status VARCHAR(30);
    DECLARE v_saldo INT;

    SELECT nome INTO v_motivo FROM motivo_saida_peca WHERE id = NEW.id_motivo;

    IF v_motivo = 'Uso em Reparo' THEN
        IF NEW.id_os IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Baixa por uso em reparo exige uma OS vinculada.';
        END IF;
        SELECT so.nome INTO v_status
          FROM ordem_servico os JOIN status_os so ON so.id = os.id_status_atual
         WHERE os.id = NEW.id_os;
        IF v_status NOT IN ('Orcamento Aprovado','Em Reparo') THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'RN01: peca so pode ser baixada com a OS em Orcamento Aprovado ou Em Reparo.';
        END IF;
    END IF;

    SELECT saldo_estoque INTO v_saldo FROM peca WHERE id = NEW.id_peca;
    IF v_saldo < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RN03: saldo em estoque insuficiente para esta baixa.';
    END IF;
END$$

-- RN03 + RN04: efetiva a baixa no estoque e recalcula o valor total da OS
-- quando a saida esta vinculada a uma OS.
CREATE TRIGGER trg_peca_saida_after_insert
AFTER INSERT ON peca_saida
FOR EACH ROW
BEGIN
    UPDATE peca SET saldo_estoque = saldo_estoque - NEW.quantidade WHERE id = NEW.id_peca;
    IF NEW.id_os IS NOT NULL THEN
        CALL sp_recalcular_valor_os(NEW.id_os);
    END IF;
END$$

-- RN04: recalcula o valor total da OS sempre que um servico e aplicado.
CREATE TRIGGER trg_os_servico_after_insert
AFTER INSERT ON os_servico
FOR EACH ROW
BEGIN
    CALL sp_recalcular_valor_os(NEW.id_os);
END$$

-- RF07: toda nova linha no historico atualiza o status atual (cache) da OS
-- e, ao entrar em Entregue/Cancelado, grava a data de fechamento.
CREATE TRIGGER trg_historico_after_insert
AFTER INSERT ON os_status_historico
FOR EACH ROW
BEGIN
    DECLARE v_nome_status VARCHAR(30);
    SELECT nome INTO v_nome_status FROM status_os WHERE id = NEW.id_status;

    UPDATE ordem_servico
       SET id_status_atual = NEW.id_status,
           data_fechamento = CASE WHEN v_nome_status IN ('Entregue','Cancelado')
                                   THEN NEW.data_hora ELSE data_fechamento END
     WHERE id = NEW.id_os;
END$$

DELIMITER ;
