-- =============================================================================
-- TechFix - Banco Upgrade
-- 05_dados.sql : dados iniciais (seed)
-- Fonte: docs/especificacao_upgrade.md (secao 5) e tabela de pecas e servicos
--
-- ATENCAO (uso real): os senha_hash abaixo sao PLACEHOLDERS fictícios no formato
-- bcrypt. TROQUE por hashes reais (bcrypt/argon2) gerados pela aplicacao antes
-- de usar o banco; nunca grave senha em texto.
--
-- O seed passa pelos MESMOS triggers do sistema: estoque inicial entra por
-- compras (movimentos ENTRADA), OS percorrem a maquina de estados, pagamentos
-- e descontos exigem permissao. Ids sao deterministicos (banco recem-criado).
-- Dinheiro em centavos.
-- =============================================================================

-- Versao do esquema
INSERT INTO schema_versao (versao, descricao) VALUES
    (1, 'Modelo base RF01-RF11 / RN01-RN04'),
    (2, 'Permissoes por cargo, kardex com custo medio, maquina de estados da OS'),
    (3, 'Upgrade: auditoria JSON, versionamento, orcamento, pagamentos multiplos, garantia, indices e views');

-- Cargos e permissoes
INSERT INTO cargo (id, nome, descricao) VALUES
    (1, 'Gerente',   'Administra a loja: catalogo, estoque, descontos e equipe'),
    (2, 'Atendente', 'Recepciona clientes, abre OS e recebe pagamentos'),
    (3, 'Técnico',   'Diagnostica, executa o reparo e baixa peças');

INSERT INTO permissao (id, codigo, descricao) VALUES
    (1,  'FUNCIONARIO_GERENCIAR', 'Cadastrar e alterar funcionários'),
    (2,  'CLIENTE_GERENCIAR',     'Cadastrar e alterar clientes, contatos e endereços'),
    (3,  'EQUIPAMENTO_GERENCIAR', 'Cadastrar e alterar equipamentos'),
    (4,  'OS_ABRIR',              'Abrir ordem de serviço'),
    (5,  'OS_EXECUTAR',           'Executar serviços e baixar peças em OS'),
    (6,  'OS_ALTERAR_STATUS',     'Alterar o status da OS e gerir orçamentos'),
    (7,  'CATALOGO_GERENCIAR',    'Gerir catálogo de serviços e peças e seus preços'),
    (8,  'ESTOQUE_ENTRADA',       'Registrar compras / entrada de estoque'),
    (9,  'ESTOQUE_BAIXA',         'Descartar peças'),
    (10, 'ESTOQUE_AJUSTE',        'Ajustar o inventário'),
    (11, 'PAGAMENTO_REGISTRAR',   'Registrar pagamentos'),
    (12, 'DESCONTO_CONCEDER',     'Conceder desconto na OS');

-- Matriz da especificacao 2.1: Gerente (1) tudo menos OS_EXECUTAR | Atendente (2) | Tecnico (3)
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (1,1),(1,2),(1,3),(1,4),(1,6),(1,7),(1,8),(1,9),(1,10),(1,11),(1,12);
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (2,2),(2,3),(2,4),(2,6),(2,11);
INSERT INTO cargo_permissao (id_cargo, id_permissao) VALUES
    (3,5),(3,6),(3,9);

-- Status da OS (seed fixo) e transicoes
INSERT INTO status_os (id, codigo, nome, ordem_exibicao, permite_baixa_peca, permite_lancar_servico, final) VALUES
    (1, 'ABERTO',             'Aberto',               1, 0, 0, 0),
    (2, 'EM_DIAGNOSTICO',     'Em diagnóstico',       2, 0, 1, 0),
    (3, 'ORCAMENTO_APROVADO', 'Orçamento aprovado',   3, 1, 1, 0),
    (4, 'EM_REPARO',          'Em reparo',            4, 1, 1, 0),
    (5, 'PRONTO',             'Pronto para retirada', 5, 0, 0, 0),
    (6, 'ENTREGUE',           'Entregue',             6, 0, 0, 1),
    (7, 'CANCELADO',          'Cancelado',            7, 0, 0, 1);

INSERT INTO status_transicao (id_origem, id_destino) VALUES
    (1,2),(1,7),(2,3),(2,7),(3,4),(3,7),(4,5),(4,3),(5,6),(5,4);

-- Formas de pagamento (taxa em pontos-base)
INSERT INTO forma_pagamento (id, nome, permite_parcelamento, max_parcelas, taxa_bp) VALUES
    (1, 'Dinheiro', 0, 1, 0),
    (2, 'Pix',      0, 1, 0),
    (3, 'Débito',   0, 1, 150),
    (4, 'Crédito',  1, 12, 349),
    (5, 'Boleto',   0, 1, 200);

-- Equipe: 1 gerente, 2 atendentes, 3 tecnicos (o primeiro funcionario e o bootstrap do gerente)
INSERT INTO funcionario (id, nome, cpf, email, telefone, id_cargo, data_admissao, criado_por) VALUES
    (1, 'Marcos Andrade',     '12345678909', 'marcos.andrade@techfix.com.br',  '11991110001', 1, '2024-01-08', NULL);
INSERT INTO funcionario (id, nome, cpf, email, telefone, id_cargo, data_admissao, criado_por) VALUES
    (2, 'Juliana Prado',      '98765432100', 'juliana.prado@techfix.com.br',   '11991110002', 2, '2024-02-05', 1),
    (3, 'Rafael Teixeira',    '45678912300', 'rafael.teixeira@techfix.com.br', '11991110003', 2, '2024-03-11', 1),
    (4, 'Carlos Menezes',     '86288366757', 'carlos.menezes@techfix.com.br',  '11991110004', 3, '2024-02-19', 1),
    (5, 'Beatriz Souza',      '71428793860', 'beatriz.souza@techfix.com.br',   '11991110005', 3, '2024-04-01', 1),
    (6, 'Diego Fontes',       '41763058907', 'diego.fontes@techfix.com.br',    '11991110006', 3, '2024-05-13', 1);

-- Usuarios (senha_hash = PLACEHOLDER bcrypt ficticio: TROCAR antes de producao)
INSERT INTO usuario (id_funcionario, login, senha_hash) VALUES
    (1, 'marcos.andrade',  '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (2, 'juliana.prado',   '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (3, 'rafael.teixeira', '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (4, 'carlos.menezes',  '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (5, 'beatriz.souza',   '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx'),
    (6, 'diego.fontes',    '$2b$12$TROCAR.ESTE.HASH.ANTES.DE.USAR.EM.PRODUCAO.xxxxxxxxxx');

-- Categorias hierarquicas (raizes: Servicos=1, Pecas=2)
INSERT INTO categoria (id, nome, id_categoria_pai, aplica_a) VALUES
    (1, 'Serviços', NULL, 'SERVICO'),
    (2, 'Peças',    NULL, 'PECA');
INSERT INTO categoria (id, nome, id_categoria_pai, aplica_a) VALUES
    (3,  'Computadores',         1, 'SERVICO'),
    (4,  'Celulares',            1, 'SERVICO'),
    (5,  'Smart TVs',            1, 'SERVICO'),
    (6,  'Redes',                1, 'SERVICO'),
    (7,  'Videogames',           1, 'SERVICO'),
    (8,  'Áudio',                1, 'SERVICO'),
    (9,  'Recuperação de Dados', 1, 'SERVICO'),
    (10, 'Eletrônica Avançada',  1, 'SERVICO'),
    (11, 'Informática',          2, 'PECA'),
    (12, 'Insumos',              2, 'PECA'),
    (13, 'Acessórios',           2, 'PECA'),
    (14, 'Telas',                2, 'PECA'),
    (15, 'Baterias',             2, 'PECA'),
    (16, 'Componentes',          2, 'PECA'),
    (17, 'Carcaças',             2, 'PECA'),
    (18, 'TVs',                  2, 'PECA');

-- Marcas, tipos e modelos
INSERT INTO marca (id, nome) VALUES
    (1,'Apple'),(2,'Samsung'),(3,'Motorola'),(4,'Xiaomi'),(5,'LG'),
    (6,'Dell'),(7,'Lenovo'),(8,'Sony'),(9,'Microsoft'),(10,'JBL');
INSERT INTO tipo_equipamento (id, nome, exige_imei) VALUES
    (1,'Celular',1),(2,'Notebook',0),(3,'Desktop',0),(4,'Smart TV',0),
    (5,'Videogame',0),(6,'Caixa de Som',0),(7,'Headset',0);
INSERT INTO modelo (id, id_marca, id_tipo_equipamento, nome) VALUES
    (1, 1, 1, 'iPhone 11'),
    (2, 2, 1, 'Galaxy A54'),
    (3, 3, 1, 'Moto G84'),
    (4, 4, 1, 'Redmi Note 11'),
    (5, 6, 2, 'Inspiron 15 3520'),
    (6, 7, 2, 'IdeaPad 3'),
    (7, 2, 4, 'UN50TU8000'),
    (8, 5, 4, '43UP7500'),
    (9, 8, 5, 'PlayStation 5'),
    (10, 9, 5, 'Xbox Series S'),
    (11, 10, 6, 'Flip 6');

-- Fornecedores
INSERT INTO fornecedor (id, razao_social, cnpj, email, telefone) VALUES
    (1, 'InfoParts Distribuidora Ltda',      '11222333000181', 'vendas@infoparts.example.com', '1133334444'),
    (2, 'Mobile & TV Componentes Eireli',    '27865757000102', 'comercial@mobiletv.example.com', '1144445555');

-- Catalogo de SERVICOS (23): codigo SRV-001.., preco em centavos, tempo em minutos
INSERT INTO servico (codigo, nome, id_categoria, preco_base, tempo_estimado_min, garantia_dias, criado_por) VALUES
    ('SRV-001', 'Formatação e Instalação de Sistema Operacional', 3, 12000, 120, 30, 1),
    ('SRV-002', 'Limpeza Interna e Troca de Pasta Térmica', 3, 15000, 90, 90, 1),
    ('SRV-003', 'Upgrade de Hardware (RAM/SSD)', 3, 8000, 60, 90, 1),
    ('SRV-004', 'Remoção de Vírus e Malwares', 3, 10000, 90, 30, 1),
    ('SRV-005', 'Troca de Tela de Notebook', 3, 18000, 90, 90, 1),
    ('SRV-006', 'Troca de Display/Frontal de Celular', 4, 15000, 60, 90, 1),
    ('SRV-007', 'Troca de Bateria de Smartphone', 4, 9000, 30, 90, 1),
    ('SRV-008', 'Desoxidação após Contato com Líquido', 4, 20000, 180, 90, 1),
    ('SRV-009', 'Reparo em Conector de Carga (Micro USB / Type-C)', 4, 11000, 90, 90, 1),
    ('SRV-010', 'Troca de Barra de LED de Smart TV', 5, 35000, 180, 90, 1),
    ('SRV-011', 'Reparo na Placa Principal de Smart TV', 5, 28000, 150, 90, 1),
    ('SRV-012', 'Conserto de Fonte de Alimentação Interna (TV)', 5, 22000, 120, 90, 1),
    ('SRV-013', 'Configuração de Rede e Roteador Wi-Fi', 6, 9000, 60, 30, 1),
    ('SRV-014', 'Higienização e Troca de Metal Líquido / Pasta Térmica (Console)', 7, 22000, 120, 90, 1),
    ('SRV-015', 'Reparo de Drift em Analógico de Controle (Joy-Con / DualSense / Xbox)', 7, 8000, 60, 90, 1),
    ('SRV-016', 'Substituição de HDMI / Conector de Vídeo (Console)', 7, 25000, 150, 90, 1),
    ('SRV-017', 'Troca de Bateria de Caixa de Som Portátil (Bluetooth)', 8, 12000, 90, 90, 1),
    ('SRV-018', 'Troca de Almofadas / Reparo de Cabo de Headset Gamer', 8, 7000, 60, 90, 1),
    ('SRV-019', 'Recuperação de Dados de HD / SSD / Pendrive Danificado', 9, 30000, 240, 30, 1),
    ('SRV-020', 'Rebaling / Reparo de BGA em Placa Mãe ou Placa de Vídeo', 10, 45000, 300, 180, 1),
    ('SRV-021', 'Gravação e Reprogramação de BIOS Eprom (Notebook / Desktop)', 10, 16000, 120, 90, 1),
    ('SRV-022', 'Troca de Vidro Traseiro de Smartphone a Laser / Manual', 4, 18000, 150, 90, 1),
    ('SRV-023', 'Reparo e Solda de Conector Jack P2/P10 de Mesa de Som ou Amplificador', 8, 9500, 60, 90, 1);

-- Catalogo de PECAS (34): nascem com estoque 0; o estoque inicial entra por compras (ENTRADA)
INSERT INTO peca (sku, nome, id_categoria, unidade, preco_venda, estoque_minimo, localizacao, garantia_dias, criado_por) VALUES
    ('PEC-001', 'SSD NVMe 512GB M.2', 11, 'UN', 26000, 4, 'EST-A-01', 90, 1),
    ('PEC-002', 'SSD SATA III 480GB 2.5"', 11, 'UN', 21000, 5, 'EST-A-02', 90, 1),
    ('PEC-003', 'Memória RAM DDR4 8GB 2666MHz (Notebook)', 11, 'UN', 17000, 3, 'EST-A-03', 90, 1),
    ('PEC-004', 'Memória RAM DDR4 16GB 3200MHz (Desktop)', 11, 'UN', 32000, 2, 'EST-A-04', 90, 1),
    ('PEC-005', 'Pasta Térmica de Alta Performance (Bisnaga 4g)', 12, 'UN', 6000, 6, 'EST-B-05', 30, 1),
    ('PEC-006', 'Fonte ATX 500W 80 Plus Bronze', 11, 'UN', 34000, 2, 'EST-A-06', 90, 1),
    ('PEC-007', 'Bateria Célula Moeda CR2032 (Cartela c/ 5)', 12, 'PCT', 2500, 8, 'EST-B-07', 30, 1),
    ('PEC-008', 'Cooler para Processador Socket Universal', 11, 'UN', 9500, 2, 'EST-A-08', 90, 1),
    ('PEC-009', 'Cabo SATA III 6Gbps 50cm', 13, 'UN', 1500, 12, 'EST-C-09', 90, 1),
    ('PEC-010', 'Tela LED 15.6" Slim 30 Pinos Full HD', 14, 'UN', 48000, 1, 'EST-D-10', 90, 1),
    ('PEC-011', 'Display Frontal Completo iPhone 11', 14, 'UN', 35000, 1, 'EST-D-11', 90, 1),
    ('PEC-012', 'Display Frontal Completo Samsung Galaxy A54', 14, 'UN', 31000, 2, 'EST-D-12', 90, 1),
    ('PEC-013', 'Display Frontal Completo Motorola Moto G84', 14, 'UN', 28000, 1, 'EST-D-13', 90, 1),
    ('PEC-014', 'Bateria Compatível iPhone 11 (3110mAh)', 15, 'UN', 16000, 2, 'EST-E-14', 90, 1),
    ('PEC-015', 'Bateria Compatível Samsung Galaxy A32', 15, 'UN', 13000, 2, 'EST-E-15', 90, 1),
    ('PEC-016', 'Bateria Compatível Moto G30', 15, 'UN', 12000, 2, 'EST-E-16', 90, 1),
    ('PEC-017', 'Conector de Carga Type-C Universal (Unidade)', 16, 'UN', 2000, 25, 'EST-F-17', 90, 1),
    ('PEC-018', 'Conector de Carga Micro USB V8', 16, 'UN', 1500, 25, 'EST-F-18', 90, 1),
    ('PEC-019', 'Flex de Carga e Microfone Moto G9 Play', 16, 'UN', 5500, 2, 'EST-F-19', 90, 1),
    ('PEC-020', 'Tampa Traseira de Vidro iPhone 12', 17, 'UN', 11000, 1, 'EST-G-20', 90, 1),
    ('PEC-021', 'Câmera Traseira Principal Redmi Note 11', 16, 'UN', 14000, 3, 'EST-F-21', 90, 1),
    ('PEC-022', 'Alto-Falante Auricular Universal', 16, 'UN', 2500, 10, 'EST-F-22', 90, 1),
    ('PEC-023', 'Barra de LED TV Samsung 50" (Kit com 3 barras)', 18, 'KIT', 23000, 1, 'EST-H-23', 90, 1),
    ('PEC-024', 'Barra de LED TV LG 43" (Kit com 3 barras)', 18, 'KIT', 19500, 1, 'EST-H-24', 90, 1),
    ('PEC-025', 'Placa Fonte TV Samsung UN50TU8000', 18, 'UN', 31000, 2, 'EST-H-25', 90, 1),
    ('PEC-026', 'Placa Principal TV LG 43UP7500', 18, 'UN', 42000, 2, 'EST-H-26', 90, 1),
    ('PEC-027', 'Cabo Flat T-Con para Display TV 55"', 18, 'UN', 6500, 2, 'EST-H-27', 90, 1),
    ('PEC-028', 'Receptor Infravermelho para Controle Remoto TV', 16, 'UN', 2000, 4, 'EST-F-28', 90, 1),
    ('PEC-029', 'Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)', 12, 'UN', 15000, 3, 'EST-B-29', 30, 1),
    ('PEC-030', 'Álcool Isopropílico 99.8% 1 Litro', 12, 'L', 4500, 3, 'EST-B-30', 30, 1),
    ('PEC-031', 'Fita Kapton Térmica 10mm x 33m', 12, 'UN', 3000, 4, 'EST-B-31', 30, 1),
    ('PEC-032', 'Fita Dupla Face Fixação de Telas (3mm x 50m)', 12, 'UN', 3500, 2, 'EST-B-32', 30, 1),
    ('PEC-033', 'Fusível de Louça 5A 250V (Pacote c/ 10)', 16, 'PCT', 1800, 5, 'EST-F-33', 90, 1),
    ('PEC-034', 'Capacitor Eletrolítico 1000uF x 25V', 16, 'UN', 500, 38, 'EST-F-34', 90, 1);

-- Compras com NF: cada item gera um movimento ENTRADA (custo medio ponderado)
INSERT INTO compra (id, id_fornecedor, numero_nf, data_compra, id_funcionario)
VALUES (1, 1, 'NF-000451', date('now','localtime','-30 days'), 1);
INSERT INTO compra_item (id_compra, id_peca, quantidade, custo_unitario, preco_venda_sugerido) VALUES
    (1, (SELECT id FROM peca WHERE sku = 'PEC-001'), 15, 14000, 26000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-002'), 20, 11000, 21000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-003'), 12, 9000, 17000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-004'), 8, 18000, 32000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-005'), 25, 2500, 6000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-006'), 6, 19000, 34000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-007'), 30, 800, 2500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-008'), 10, 4500, 9500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-009'), 50, 300, 1500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-010'), 5, 28000, 48000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-029'), 3, 8500, 15000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-030'), 12, 2200, 4500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-031'), 15, 1200, 3000),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-032'), 10, 1500, 3500),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-033'), 20, 500, 1800),
    (1, (SELECT id FROM peca WHERE sku = 'PEC-034'), 150, 80, 500);

INSERT INTO compra (id, id_fornecedor, numero_nf, data_compra, id_funcionario)
VALUES (2, 2, 'NF-008812', date('now','localtime','-20 days'), 1);
INSERT INTO compra_item (id_compra, id_peca, quantidade, custo_unitario, preco_venda_sugerido) VALUES
    (2, (SELECT id FROM peca WHERE sku = 'PEC-011'), 4, 18000, 35000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-012'), 6, 16000, 31000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-013'), 5, 14000, 28000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-014'), 8, 7500, 16000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-015'), 7, 6000, 13000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-016'), 6, 5500, 12000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-017'), 100, 250, 2000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-018'), 100, 150, 1500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-019'), 10, 1800, 5500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-020'), 4, 4000, 11000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-021'), 3, 6500, 14000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-022'), 40, 500, 2500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-023'), 4, 11000, 23000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-024'), 5, 9500, 19500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-025'), 2, 16000, 31000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-026'), 2, 21000, 42000),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-027'), 8, 2200, 6500),
    (2, (SELECT id FROM peca WHERE sku = 'PEC-028'), 15, 400, 2000);

-- Clientes PF e PJ (criados pela atendente Juliana, id 2)
INSERT INTO cliente (id, tipo_pessoa, nome, documento, data_nascimento, aceita_comunicacao, criado_por) VALUES
    (1, 'PF', 'Ana Paula Ribeiro',            '52998224725', '1988-03-14', 1, 2),
    (2, 'PF', 'Bruno Henrique Lima',          '11144477735', '1995-11-02', 1, 2),
    (3, 'PF', 'Carla Mendes Oliveira',        '39053344705', '1979-07-27', 0, 2),
    (4, 'PJ', 'Padaria Pão Quente Ltda',      '11222333000181', NULL,      1, 2),
    (5, 'PJ', 'Contábil Alfa Serviços ME',    '45723174000110', NULL,      1, 3);

INSERT INTO cliente_contato (id_cliente, tipo, valor, principal, criado_por) VALUES
    (1, 'CELULAR',  '11988880001', 1, 2),
    (1, 'EMAIL',    'ana.ribeiro@example.com', 1, 2),
    (1, 'WHATSAPP', '11988880001', 1, 2),
    (2, 'CELULAR',  '11988880002', 1, 2),
    (2, 'EMAIL',    'bruno.lima@example.com', 1, 2),
    (3, 'CELULAR',  '11988880003', 1, 2),
    (3, 'TELEFONE', '1133220003',  1, 2),
    (4, 'TELEFONE', '1133220004',  1, 2),
    (4, 'EMAIL',    'contato@paoquente.example.com', 1, 2),
    (5, 'CELULAR',  '11988880005', 1, 3),
    (5, 'EMAIL',    'financeiro@contabilalfa.example.com', 1, 3);

INSERT INTO cliente_endereco (id_cliente, cep, logradouro, numero, complemento, bairro, cidade, uf, principal, criado_por) VALUES
    (1, '01310100', 'Avenida Paulista',     '1000', 'Apto 52', 'Bela Vista',  'São Paulo',      'SP', 1, 2),
    (2, '30140071', 'Rua da Bahia',         '250',  NULL,      'Centro',      'Belo Horizonte', 'MG', 1, 2),
    (3, '80010000', 'Rua XV de Novembro',   '88',   'Sala 3',  'Centro',      'Curitiba',       'PR', 1, 2),
    (4, '20040020', 'Rua da Assembleia',    '45',   NULL,      'Centro',      'Rio de Janeiro', 'RJ', 1, 2),
    (5, '40020000', 'Avenida Sete de Setembro', '900', 'Conj. 12', 'Comércio', 'Salvador',      'BA', 1, 3);

-- Equipamentos (celulares com IMEI valido pelo algoritmo de Luhn)
INSERT INTO equipamento (id, id_cliente, id_modelo, numero_serie, imei, cor, observacao, criado_por) VALUES
    (1, 1, 1, 'F2LXK1ABC123',  '353321101234568', 'Preto',   'Tela trincada',                 2),
    (2, 2, 2, NULL,            '356945087654329', 'Azul',    NULL,                            2),
    (3, 3, 3, 'ZY22-MG84-0192', '351209076543216', 'Grafite', NULL,                           2),
    (4, 4, 5, 'DL15-7788221',  NULL,         'Prata',   'Notebook do caixa',             3),
    (5, 1, 7, 'TVSAM50-001928', NULL,        'Preto',   NULL,                            2),
    (6, 2, 9, 'PS5-0099321',   NULL,         'Branco',  'Edição com leitor de disco',    2),
    (7, 5, 4, NULL,            '864523041122330', 'Cinza',   NULL,                            3),
    (8, 5, 6, 'LNV-IP3-55120', NULL,         'Cinza',   'Notebook do escritório',        3);

-- =============================================================================
-- ORDENS DE SERVICO (percorrem a maquina de estados pelos triggers)
-- =============================================================================

-- OS 1: ENTREGUE, pagamento dividido (Pix + Credito 3x), com garantia
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (1, 1, 1, 2, 4, 'ALTA', 'Tela quebrada após queda; touch sem resposta', 'Capa e carregador', datetime('now','localtime','-5 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 1, 2, 4, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (1, 50000, date('now','localtime','+7 days'), 2);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'WHATSAPP'
 WHERE id_os = 1 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 2, 3, 2, 'Orçamento aprovado pelo cliente via WhatsApp');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 3, 4, 4, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 1, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-006';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 1, id, 4, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-011';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 4, 5, 4, 'Reparo concluído');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (1, 2, 20000, 1, 2);
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (1, 4, 30000, 3, 2);
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (1, 5, 6, 2, 'Entregue ao cliente');

-- OS 2: EM_REPARO, com peca lancada por engano e ESTORNADA (estoque devolvido)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (2, 2, 2, 3, 5, 'NORMAL', 'Tela trincada e bateria viciada', 'Sem acessórios', datetime('now','localtime','-3 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 1, 2, 5, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (2, 46000, date('now','localtime','+7 days'), 3);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'TELEFONE'
 WHERE id_os = 2 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 2, 3, 3, 'Orçamento aprovado por telefone');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (2, 3, 4, 5, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 2, id, 5, 1, preco_base FROM servico WHERE codigo = 'SRV-006';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 2, id, 5, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-012';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 2, id, 5, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-015';
UPDATE os_peca SET estornado = 1, motivo_estorno = 'Peça lançada por engano (bateria de outro modelo)'
 WHERE id_os = 2 AND id_peca = (SELECT id FROM peca WHERE sku = 'PEC-015');

-- OS 3: aguardando ORCAMENTO (em diagnostico, orcamento PENDENTE)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (3, 3, 3, 2, 6, 'NORMAL', 'Não carrega; conector de carga parece danificado', NULL, datetime('now','localtime','-1 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (3, 1, 2, 6, 'Diagnóstico iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 3, id, 6, 1, preco_base FROM servico WHERE codigo = 'SRV-009';
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (3, 13000, date('now','localtime','+7 days'), 2);

-- OS 4: ABERTA (sem tecnico)
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (4, 4, 4, 3, NULL, 'URGENTE', 'Notebook muito lento e superaquecendo no caixa', 'Carregador', datetime('now','localtime','-0 days'), date('now','localtime','+1 days'));

-- OS 5: CANCELADA
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (5, 5, 7, 2, NULL, 'BAIXA', 'Câmera traseira com foco falhando', NULL, datetime('now','localtime','-6 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (5, 1, 7, 2, 'Cliente desistiu do reparo');

-- OS 6: PRONTA, com DESCONTO concedido pelo gerente (id 1) e pagamento parcial
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (6, 1, 5, 2, 6, 'ALTA', 'TV sem imagem (som normal); suspeita de barras de LED', NULL, datetime('now','localtime','-7 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 1, 2, 6, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (6, 58000, date('now','localtime','+7 days'), 2);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'PRESENCIAL'
 WHERE id_os = 6 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 2, 3, 2, 'Orçamento aprovado presencialmente');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 3, 4, 6, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 6, id, 6, 1, preco_base FROM servico WHERE codigo = 'SRV-010';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 6, id, 6, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-023';
UPDATE ordem_servico SET desconto = 3000, atualizado_por = 1 WHERE id = 6;
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (6, 4, 5, 6, 'Reparo concluído; aguardando retirada e pagamento');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (6, 1, 20000, 1, 3);

-- OS 7: ENTREGUE (2 servicos + 1 peca), pagamento no debito, com garantia
INSERT INTO ordem_servico (id, id_cliente, id_equipamento, id_atendente, id_tecnico, prioridade, defeito_relatado, acessorios_recebidos, data_abertura, previsao_entrega)
VALUES (7, 5, 8, 3, 4, 'NORMAL', 'Windows corrompido e notebook muito lento', 'Carregador de fábrica', datetime('now','localtime','-4 days'), date('now','localtime','+3 days'));
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 1, 2, 4, 'Diagnóstico iniciado');
INSERT INTO os_orcamento (id_os, valor_previsto, validade, criado_por)
VALUES (7, 41000, date('now','localtime','+7 days'), 3);
UPDATE os_orcamento SET situacao = 'APROVADO', aprovado_em = datetime('now','localtime'), forma_aprovacao = 'EMAIL'
 WHERE id_os = 7 AND situacao = 'PENDENTE';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 2, 3, 3, 'Orçamento aprovado por e-mail');
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 3, 4, 4, 'Reparo iniciado');
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 7, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-001';
INSERT INTO os_servico (id_os, id_servico, id_tecnico, quantidade, preco_unitario)
SELECT 7, id, 4, 1, preco_base FROM servico WHERE codigo = 'SRV-003';
INSERT INTO os_peca (id_os, id_peca, id_tecnico, quantidade, preco_unitario, custo_unitario)
SELECT 7, id, 4, 1, preco_venda, custo_medio FROM peca WHERE sku = 'PEC-002';
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 4, 5, 4, 'Reparo concluído');
INSERT INTO os_pagamento (id_os, id_forma_pagamento, valor, parcelas, id_funcionario)
VALUES (7, 3, 41000, 1, 3);
INSERT INTO os_historico_status (id_os, id_status_anterior, id_status_novo, id_funcionario, observacao)
VALUES (7, 5, 6, 3, 'Entregue ao cliente');

-- Descarte e ajuste de inventario (kardex)
INSERT INTO movimento_estoque
    (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
     custo_medio_anterior, custo_medio_posterior, motivo, id_funcionario)
SELECT id, 'DESCARTE', 2, custo_medio, estoque_atual, estoque_atual - 2, custo_medio, custo_medio,
       'Cabos SATA com defeito de fábrica descartados', 1
  FROM peca WHERE sku = 'PEC-009';

INSERT INTO movimento_estoque
    (id_peca, tipo, quantidade, custo_unitario, saldo_anterior, saldo_posterior,
     custo_medio_anterior, custo_medio_posterior, motivo, id_funcionario)
SELECT id, 'AJUSTE_ENTRADA', 3, custo_medio, estoque_atual, estoque_atual + 3, custo_medio, custo_medio,
       'Inventário: capacitores encontrados na prateleira B', 1
  FROM peca WHERE sku = 'PEC-034';
