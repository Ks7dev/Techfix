-- TechFix - Banco de Entrega
-- Parte 4: dados iniciais.
-- Valores em centavos. NÃO se escreve valor_total, estoque_atual nem data_fechamento:
-- os triggers calculam. Funcionários: 1-3 Técnicos, 4-5 Atendentes, 6-7 Gerentes.

-- ---------------------------------------------------------------
-- Cargos e funcionários
-- ---------------------------------------------------------------
INSERT INTO cargo (nome_cargo) VALUES ('Gerente'), ('Atendente'), ('Técnico');

INSERT INTO funcionario (nome_funcionario, id_cargo) VALUES
    ('Carlos Almeida',  3),   -- 1 Técnico
    ('Marcos Oliveira', 3),   -- 2 Técnico
    ('Rafael Santos',   3),   -- 3 Técnico
    ('Ana Paula Silva', 2),   -- 4 Atendente
    ('Juliana Costa',   2),   -- 5 Atendente
    ('Roberto Martins', 1),   -- 6 Gerente
    ('Silas Camus',     1);   -- 7 Gerente

-- ---------------------------------------------------------------
-- Situações (os 7 status do RF07, nomes padronizados)
-- ---------------------------------------------------------------
INSERT INTO situacao (nome) VALUES
    ('Aberto'), ('Em Diagnóstico'), ('Orçamento Aprovado'), ('Em Reparo'),
    ('Pronto'), ('Entregue'), ('Cancelado');

-- ---------------------------------------------------------------
-- Formas de pagamento (Gerente)
-- ---------------------------------------------------------------
INSERT INTO forma_pagamento (nome, id_funcionario, id_funcionario_cargo) VALUES
    ('Dinheiro', 6, 1),
    ('PIX', 6, 1),
    ('Cartão de Débito', 6, 1),
    ('Cartão de Crédito - À Vista', 6, 1),
    ('Cartão de Crédito - Parcelado', 6, 1),
    ('Boleto Bancário', 6, 1);

-- ---------------------------------------------------------------
-- Clientes (Atendente ou Gerente). CPF só dígitos; telefone obrigatório
-- ---------------------------------------------------------------
INSERT INTO cliente (nome_cliente, cpf, telefone, email, id_funcionario, id_funcionario_cargo) VALUES
    ('João',                     '78264359754', '11987650001', 'joao@gmail.com',              4, 2),
    ('Marcos Vinicius Souza',    '00000000001', '11987650002', 'marcos.souza@email.com',      6, 1),
    ('Fernanda Maria Oliveira',  '00000000002', '11987650003', 'fernanda.oliveira@email.com', 6, 1),
    ('Roberto Carlos Andrade',   '00000000003', '11987650004', 'roberto.andrade@email.com',   6, 1),
    ('Camila de Cassia Martins', '00000000004', '11987650005', 'camila.martins@email.com',    6, 1),
    ('Patricia Ferreira Lima',   '00000000005', '11987650006', 'patricia.lima@email.com',     6, 1),
    ('Lucas Gabriel Barbosa',    '00000000006', '11987650007', 'lucas.barbosa@email.com',     6, 1);

-- ---------------------------------------------------------------
-- Categorias (Gerente)
-- ---------------------------------------------------------------
INSERT INTO categoria (nome, id_funcionario, id_funcionario_cargo) VALUES
    ('Computadores', 6, 1), ('Celulares', 7, 1), ('Smart TVs', 7, 1), ('Redes', 6, 1),
    ('Videogames', 6, 1), ('Áudio', 6, 1), ('Recuperação de Dados', 6, 1), ('Eletrônica Avançada', 7, 1),
    ('Informática', 7, 1), ('Insumos', 7, 1), ('Acessórios', 6, 1), ('Telas', 6, 1),
    ('Baterias', 7, 1), ('Componentes', 6, 1), ('Carcaças', 7, 1), ('TVs', 6, 1);

-- ---------------------------------------------------------------
-- Serviços do catálogo (23). Gerente cadastra.
-- ---------------------------------------------------------------
INSERT INTO servico (nome, id_categoria, preco, horas_trabalho, id_funcionario, id_funcionario_cargo) VALUES
    ('Formatação e Instalação de Sistema Operacional', (SELECT id FROM categoria WHERE nome = 'Computadores'), 12000, 2.0, 6, 1),
    ('Limpeza Interna e Troca de Pasta Térmica', (SELECT id FROM categoria WHERE nome = 'Computadores'), 15000, 1.5, 6, 1),
    ('Upgrade de Hardware (RAM/SSD)', (SELECT id FROM categoria WHERE nome = 'Computadores'), 8000, 1.0, 6, 1),
    ('Remoção de Vírus e Malwares', (SELECT id FROM categoria WHERE nome = 'Computadores'), 10000, 1.5, 6, 1),
    ('Troca de Tela de Notebook', (SELECT id FROM categoria WHERE nome = 'Computadores'), 18000, 1.5, 6, 1),
    ('Troca de Display/Frontal de Celular', (SELECT id FROM categoria WHERE nome = 'Celulares'), 15000, 1.0, 6, 1),
    ('Troca de Bateria de Smartphone', (SELECT id FROM categoria WHERE nome = 'Celulares'), 9000, 0.5, 6, 1),
    ('Desoxidação após Contato com Líquido', (SELECT id FROM categoria WHERE nome = 'Celulares'), 20000, 3.0, 6, 1),
    ('Reparo em Conector de Carga (Micro USB / Type-C)', (SELECT id FROM categoria WHERE nome = 'Celulares'), 11000, 1.5, 6, 1),
    ('Troca de Barra de LED de Smart TV', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 35000, 3.0, 6, 1),
    ('Reparo na Placa Principal de Smart TV', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 28000, 2.5, 6, 1),
    ('Conserto de Fonte de Alimentação Interna (TV)', (SELECT id FROM categoria WHERE nome = 'Smart TVs'), 22000, 2.0, 6, 1),
    ('Configuração de Rede e Roteador Wi-Fi', (SELECT id FROM categoria WHERE nome = 'Redes'), 9000, 1.0, 6, 1),
    ('Higienização e Troca de Metal Líquido / Pasta Térmica (Console)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 22000, 2.0, 6, 1),
    ('Reparo de Drift em Analógico de Controle (Joy-Con / DualSense / Xbox)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 8000, 1.0, 6, 1),
    ('Substituição de HDMI / Conector de Vídeo (Console)', (SELECT id FROM categoria WHERE nome = 'Videogames'), 25000, 2.5, 6, 1),
    ('Troca de Bateria de Caixa de Som Portátil (Bluetooth)', (SELECT id FROM categoria WHERE nome = 'Áudio'), 12000, 1.5, 6, 1),
    ('Troca de Almofadas / Reparo de Cabo de Headset Gamer', (SELECT id FROM categoria WHERE nome = 'Áudio'), 7000, 1.0, 6, 1),
    ('Recuperação de Dados de HD / SSD / Pendrive Danificado', (SELECT id FROM categoria WHERE nome = 'Recuperação de Dados'), 30000, 4.0, 6, 1),
    ('Rebaling / Reparo de BGA em Placa Mãe ou Placa de Vídeo', (SELECT id FROM categoria WHERE nome = 'Eletrônica Avançada'), 45000, 5.0, 6, 1),
    ('Gravação e Reprogramação de BIOS Eprom (Notebook / Desktop)', (SELECT id FROM categoria WHERE nome = 'Eletrônica Avançada'), 16000, 2.0, 6, 1),
    ('Troca de Vidro Traseiro de Smartphone a Laser / Manual', (SELECT id FROM categoria WHERE nome = 'Celulares'), 18000, 2.5, 6, 1),
    ('Reparo e Solda de Conector Jack P2/P10 de Mesa de Som ou Amplificador', (SELECT id FROM categoria WHERE nome = 'Áudio'), 9500, 1.0, 6, 1);

-- ---------------------------------------------------------------
-- Marcas, tipos e modelos (cada modelo pertence a uma marca)
-- ---------------------------------------------------------------
INSERT INTO marca (nome_marca, id_funcionario, id_funcionario_cargo) VALUES
    ('Apple', 6, 1), ('Samsung', 7, 1), ('Motorola', 7, 1), ('Xiaomi', 6, 1),
    ('Dell', 6, 1), ('Lenovo', 7, 1), ('LG', 7, 1), ('Sony', 6, 1);

INSERT INTO tipo (nome_tipo, id_funcionario, id_funcionario_cargo) VALUES
    ('Smartphone', 6, 1),             -- 1
    ('Notebook', 4, 2),               -- 2
    ('Desktop', 5, 2),                -- 3
    ('Smart TV', 5, 2),               -- 4
    ('Console de Videogame', 5, 2),   -- 5
    ('Caixa de Som Bluetooth', 5, 2); -- 6

INSERT INTO modelo (id_marca, nome_modelo, id_funcionario, id_funcionario_cargo) VALUES
    ((SELECT id FROM marca WHERE nome_marca = 'Apple'),    'iPhone 11',              6, 1),  -- 1
    ((SELECT id FROM marca WHERE nome_marca = 'Apple'),    'iPhone 12',              6, 1),  -- 2
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Galaxy A54',             6, 1),  -- 3
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Galaxy A32',             7, 1),  -- 4
    ((SELECT id FROM marca WHERE nome_marca = 'Motorola'), 'Moto G84',               7, 1),  -- 5
    ((SELECT id FROM marca WHERE nome_marca = 'Motorola'), 'Moto G30',               4, 2),  -- 6
    ((SELECT id FROM marca WHERE nome_marca = 'Xiaomi'),   'Redmi Note 11',          4, 2),  -- 7
    ((SELECT id FROM marca WHERE nome_marca = 'Dell'),     'Inspiron 15 3000',       6, 1),  -- 8
    ((SELECT id FROM marca WHERE nome_marca = 'Lenovo'),   'IdeaPad 3',              6, 1),  -- 9
    ((SELECT id FROM marca WHERE nome_marca = 'Samsung'),  'Smart TV 50 UN50TU8000', 7, 1),  -- 10
    ((SELECT id FROM marca WHERE nome_marca = 'LG'),       'Smart TV 43 43UP7500',   4, 2),  -- 11 (era cadastrado como Samsung/LG trocado)
    ((SELECT id FROM marca WHERE nome_marca = 'Sony'),     'PlayStation 5',          7, 1);  -- 12

-- ---------------------------------------------------------------
-- Equipamentos: série ou IMEI (15 dígitos)
-- ---------------------------------------------------------------
INSERT INTO equipamento (id_cliente, id_modelo, id_tipo, numero_serie, imei, id_funcionario, id_funcionario_cargo) VALUES
    (1, 1,  1, NULL,                  '356789012345671', 6, 1),  -- 1 iPhone 11
    (2, 3,  1, NULL,                  '356789012345672', 6, 1),  -- 2 Galaxy A54
    (3, 8,  2, 'DELL-INSP-2023-998',  NULL,              6, 1),  -- 3 Notebook Dell
    (4, 11, 4, 'LG-TV43-77612',       NULL,              6, 1),  -- 4 Smart TV LG 43
    (5, 12, 5, 'PS5-SONY-009182',     NULL,              6, 1),  -- 5 PlayStation 5
    (6, 5,  1, NULL,                  '356789012345673', 6, 1);  -- 6 Moto G84

-- ---------------------------------------------------------------
-- Peças do catálogo (34), cadastradas com estoque 0. Gerente cadastra.
-- O estoque inicial entra pelas entradas abaixo (trigger soma).
-- ---------------------------------------------------------------
INSERT INTO peca (nome, id_categoria, preco_compra, preco_venda, id_funcionario, id_funcionario_cargo) VALUES
    ('SSD NVMe 512GB M.2', (SELECT id FROM categoria WHERE nome = 'Informática'), 14000, 26000, 7, 1),  -- 1
    ('SSD SATA III 480GB 2.5"', (SELECT id FROM categoria WHERE nome = 'Informática'), 11000, 21000, 7, 1),  -- 2
    ('Memória RAM DDR4 8GB 2666MHz (Notebook)', (SELECT id FROM categoria WHERE nome = 'Informática'), 9000, 17000, 7, 1),  -- 3
    ('Memória RAM DDR4 16GB 3200MHz (Desktop)', (SELECT id FROM categoria WHERE nome = 'Informática'), 18000, 32000, 7, 1),  -- 4
    ('Pasta Térmica de Alta Performance (Bisnaga 4g)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 2500, 6000, 7, 1),  -- 5
    ('Fonte ATX 500W 80 Plus Bronze', (SELECT id FROM categoria WHERE nome = 'Informática'), 19000, 34000, 7, 1),  -- 6
    ('Bateria Célula Moeda CR2032 (Cartela c/ 5)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 800, 2500, 7, 1),  -- 7
    ('Cooler para Processador Socket Universal', (SELECT id FROM categoria WHERE nome = 'Informática'), 4500, 9500, 7, 1),  -- 8
    ('Cabo SATA III 6Gbps 50cm', (SELECT id FROM categoria WHERE nome = 'Acessórios'), 300, 1500, 7, 1),  -- 9
    ('Tela LED 15.6" Slim 30 Pinos Full HD', (SELECT id FROM categoria WHERE nome = 'Telas'), 28000, 48000, 7, 1),  -- 10
    ('Display Frontal Completo iPhone 11', (SELECT id FROM categoria WHERE nome = 'Telas'), 18000, 35000, 7, 1),  -- 11
    ('Display Frontal Completo Samsung Galaxy A54', (SELECT id FROM categoria WHERE nome = 'Telas'), 16000, 31000, 7, 1),  -- 12
    ('Display Frontal Completo Motorola Moto G84', (SELECT id FROM categoria WHERE nome = 'Telas'), 14000, 28000, 7, 1),  -- 13
    ('Bateria Compatível iPhone 11 (3110mAh)', (SELECT id FROM categoria WHERE nome = 'Baterias'), 7500, 16000, 7, 1),  -- 14
    ('Bateria Compatível Samsung Galaxy A32', (SELECT id FROM categoria WHERE nome = 'Baterias'), 6000, 13000, 7, 1),  -- 15
    ('Bateria Compatível Moto G30', (SELECT id FROM categoria WHERE nome = 'Baterias'), 5500, 12000, 7, 1),  -- 16
    ('Conector de Carga Type-C Universal (Unidade)', (SELECT id FROM categoria WHERE nome = 'Componentes'), 250, 2000, 7, 1),  -- 17
    ('Conector de Carga Micro USB V8', (SELECT id FROM categoria WHERE nome = 'Componentes'), 150, 1500, 7, 1),  -- 18
    ('Flex de Carga e Microfone Moto G9 Play', (SELECT id FROM categoria WHERE nome = 'Componentes'), 1800, 5500, 7, 1),  -- 19
    ('Tampa Traseira de Vidro iPhone 12', (SELECT id FROM categoria WHERE nome = 'Carcaças'), 4000, 11000, 7, 1),  -- 20
    ('Câmera Traseira Principal Redmi Note 11', (SELECT id FROM categoria WHERE nome = 'Componentes'), 6500, 14000, 7, 1),  -- 21
    ('Alto-Falante Auricular Universal', (SELECT id FROM categoria WHERE nome = 'Componentes'), 500, 2500, 7, 1),  -- 22
    ('Barra de LED TV Samsung 50" (Kit com 3 barras)', (SELECT id FROM categoria WHERE nome = 'TVs'), 11000, 23000, 7, 1),  -- 23
    ('Barra de LED TV LG 43" (Kit com 3 barras)', (SELECT id FROM categoria WHERE nome = 'TVs'), 9500, 19500, 7, 1),  -- 24
    ('Placa Fonte TV Samsung UN50TU8000', (SELECT id FROM categoria WHERE nome = 'TVs'), 16000, 31000, 7, 1),  -- 25
    ('Placa Principal TV LG 43UP7500', (SELECT id FROM categoria WHERE nome = 'TVs'), 21000, 42000, 7, 1),  -- 26
    ('Cabo Flat T-Con para Display TV 55"', (SELECT id FROM categoria WHERE nome = 'TVs'), 2200, 6500, 7, 1),  -- 27
    ('Receptor Infravermelho para Controle Remoto TV', (SELECT id FROM categoria WHERE nome = 'Componentes'), 400, 2000, 7, 1),  -- 28
    ('Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 8500, 15000, 7, 1),  -- 29
    ('Álcool Isopropílico 99.8% 1 Litro', (SELECT id FROM categoria WHERE nome = 'Insumos'), 2200, 4500, 7, 1),  -- 30
    ('Fita Kapton Térmica 10mm x 33m', (SELECT id FROM categoria WHERE nome = 'Insumos'), 1200, 3000, 7, 1),  -- 31
    ('Fita Dupla Face Fixação de Telas (3mm x 50m)', (SELECT id FROM categoria WHERE nome = 'Insumos'), 1500, 3500, 7, 1),  -- 32
    ('Fusível de Louça 5A 250V (Pacote c/ 10)', (SELECT id FROM categoria WHERE nome = 'Componentes'), 500, 1800, 7, 1),  -- 33
    ('Capacitor Eletrolítico 1000uF x 25V', (SELECT id FROM categoria WHERE nome = 'Componentes'), 80, 500, 7, 1);  -- 34

-- ---------------------------------------------------------------
-- Entradas de peça: estoque inicial do catálogo (quantidade = estoque do catálogo)
-- ---------------------------------------------------------------
INSERT INTO entrada_peca (id_peca, preco_compra, preco_venda_sugerido, quantidade, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (1, 14000, 26000, 15, 7, 1, '2026-08-25 08:00:00'),  -- SSD NVMe 512GB M.2
    (2, 11000, 21000, 20, 7, 1, '2026-08-25 08:00:00'),  -- SSD SATA III 480GB 2.5"
    (3, 9000, 17000, 12, 7, 1, '2026-08-25 08:00:00'),  -- Memória RAM DDR4 8GB 2666MHz (Notebook)
    (4, 18000, 32000, 8, 7, 1, '2026-08-25 08:00:00'),  -- Memória RAM DDR4 16GB 3200MHz (Desktop)
    (5, 2500, 6000, 25, 7, 1, '2026-08-25 08:00:00'),  -- Pasta Térmica de Alta Performance (Bisnaga 4g)
    (6, 19000, 34000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Fonte ATX 500W 80 Plus Bronze
    (7, 800, 2500, 30, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Célula Moeda CR2032 (Cartela c/ 5)
    (8, 4500, 9500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Cooler para Processador Socket Universal
    (9, 300, 1500, 50, 7, 1, '2026-08-25 08:00:00'),  -- Cabo SATA III 6Gbps 50cm
    (10, 28000, 48000, 5, 7, 1, '2026-08-25 08:00:00'),  -- Tela LED 15.6" Slim 30 Pinos Full HD
    (11, 18000, 35000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo iPhone 11
    (12, 16000, 31000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo Samsung Galaxy A54
    (13, 14000, 28000, 5, 7, 1, '2026-08-25 08:00:00'),  -- Display Frontal Completo Motorola Moto G84
    (14, 7500, 16000, 8, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível iPhone 11 (3110mAh)
    (15, 6000, 13000, 7, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível Samsung Galaxy A32
    (16, 5500, 12000, 6, 7, 1, '2026-08-25 08:00:00'),  -- Bateria Compatível Moto G30
    (17, 250, 2000, 100, 7, 1, '2026-08-25 08:00:00'),  -- Conector de Carga Type-C Universal (Unidade)
    (18, 150, 1500, 100, 7, 1, '2026-08-25 08:00:00'),  -- Conector de Carga Micro USB V8
    (19, 1800, 5500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Flex de Carga e Microfone Moto G9 Play
    (20, 4000, 11000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Tampa Traseira de Vidro iPhone 12
    (21, 6500, 14000, 3, 7, 1, '2026-08-25 08:00:00'),  -- Câmera Traseira Principal Redmi Note 11
    (22, 500, 2500, 40, 7, 1, '2026-08-25 08:00:00'),  -- Alto-Falante Auricular Universal
    (23, 11000, 23000, 4, 7, 1, '2026-08-25 08:00:00'),  -- Barra de LED TV Samsung 50" (Kit com 3 barras)
    (24, 9500, 19500, 5, 7, 1, '2026-08-25 08:00:00'),  -- Barra de LED TV LG 43" (Kit com 3 barras)
    (25, 16000, 31000, 2, 7, 1, '2026-08-25 08:00:00'),  -- Placa Fonte TV Samsung UN50TU8000
    (26, 21000, 42000, 2, 7, 1, '2026-08-25 08:00:00'),  -- Placa Principal TV LG 43UP7500
    (27, 2200, 6500, 8, 7, 1, '2026-08-25 08:00:00'),  -- Cabo Flat T-Con para Display TV 55"
    (28, 400, 2000, 15, 7, 1, '2026-08-25 08:00:00'),  -- Receptor Infravermelho para Controle Remoto TV
    (29, 8500, 15000, 3, 7, 1, '2026-08-25 08:00:00'),  -- Solda em Fio Sn60/Pb40 0.8mm (Carretel 500g)
    (30, 2200, 4500, 12, 7, 1, '2026-08-25 08:00:00'),  -- Álcool Isopropílico 99.8% 1 Litro
    (31, 1200, 3000, 15, 7, 1, '2026-08-25 08:00:00'),  -- Fita Kapton Térmica 10mm x 33m
    (32, 1500, 3500, 10, 7, 1, '2026-08-25 08:00:00'),  -- Fita Dupla Face Fixação de Telas (3mm x 50m)
    (33, 500, 1800, 20, 7, 1, '2026-08-25 08:00:00'),  -- Fusível de Louça 5A 250V (Pacote c/ 10)
    (34, 80, 500, 150, 7, 1, '2026-08-25 08:00:00');  -- Capacitor Eletrolítico 1000uF x 25V

-- Entradas de reposição (preço sugerido = preço de venda atual da peça)
INSERT INTO entrada_peca (id_peca, preco_compra, preco_venda_sugerido, quantidade, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (1,  18000, (SELECT preco_venda FROM peca WHERE id = 1),  20, 7, 1, '2026-08-28 09:00:00'),  -- SSD NVMe
    (3,  11000, (SELECT preco_venda FROM peca WHERE id = 3),  15, 6, 1, '2026-08-28 09:10:00'),  -- RAM DDR4 8GB
    (11, 22000, (SELECT preco_venda FROM peca WHERE id = 11), 10, 6, 1, '2026-08-28 09:20:00'),  -- Display iPhone 11
    (14,  9000, (SELECT preco_venda FROM peca WHERE id = 14), 12, 7, 1, '2026-08-28 09:30:00'),  -- Bateria iPhone 11
    (23, 14000, (SELECT preco_venda FROM peca WHERE id = 23),  8, 6, 1, '2026-08-28 09:40:00');  -- Barra LED Samsung 50

-- ---------------------------------------------------------------
-- Ordens de serviço, refeitas pelo fluxo correto:
-- abrir OS (histórico "Aberto" é automático) -> situações -> serviços (preço do catálogo)
-- -> peças (só em situação 3/4) -> forma de pagamento -> Entregue.
-- Técnico de todas: Rafael Santos (3). Aberta por Roberto Martins (6, Gerente).
-- ---------------------------------------------------------------
INSERT INTO ordem (id_equipamento, defeito_relatado, defeito_constatado, data_abertura,
                   id_funcionario_abertura, id_funcionario_cargo_abertura, id_tecnico, id_tecnico_cargo) VALUES
    (1, 'Tela quebrada após queda.',                'Display frontal danificado, toque não responde.',                 '2026-09-01 09:30:00', 6, 1, 3, 3),  -- OS 1 iPhone 11
    (3, 'Notebook muito lento para ligar.',         'Lentidão provocada por HD mecânico antigo.',                      '2026-09-10 10:15:00', 6, 1, 3, 3),  -- OS 2 Dell
    (4, 'TV com som, mas imagem não aparece.',      'Barra de LED queimada.',                                          '2026-09-15 11:00:00', 6, 1, 3, 3),  -- OS 3 Smart TV LG
    (5, 'Desligando por aquecimento.',              'Acúmulo severo de poeira e necessidade de troca de pasta térmica.', '2026-09-20 14:20:00', 6, 1, 3, 3);  -- OS 4 PS5

-- ===== OS 1: iPhone 11 -> Entregue =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 2, 7, '2026-09-01 10:00:00'),   -- Em Diagnóstico
    (1, 3, 6, '2026-09-01 11:30:00'),   -- Orçamento Aprovado
    (1, 4, 7, '2026-09-01 14:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (1, 6, (SELECT preco FROM servico WHERE id = 6), 1, '2026-09-01 15:00:00');       -- Troca de Display/Frontal de Celular
INSERT INTO ordem_peca (id_ordem, id_peca, preco, quantidade, id_tecnico, id_tecnico_cargo, data_saida) VALUES
    (1, 11, (SELECT preco_venda FROM peca WHERE id = 11), 1, 3, 3, '2026-09-01 14:30:00');  -- Display iPhone 11
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 5, 6, '2026-09-02 15:30:00');   -- Pronto
UPDATE ordem SET id_forma_pagamento = 2 WHERE id = 1;                                  -- PIX
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (1, 6, 6, '2026-09-02 16:00:00');   -- Entregue (data_fechamento automática)

-- ===== OS 2: Notebook Dell -> Pronto (ainda não entregue) =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (2, 3, 7, '2026-09-10 10:45:00'),   -- Orçamento Aprovado
    (2, 4, 6, '2026-09-10 11:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (2, 1, (SELECT preco FROM servico WHERE id = 1), 1, '2026-09-10 13:00:00');       -- Formatação e Instalação de SO
INSERT INTO ordem_peca (id_ordem, id_peca, preco, quantidade, id_tecnico, id_tecnico_cargo, data_saida) VALUES
    (2, 1, (SELECT preco_venda FROM peca WHERE id = 1), 1, 3, 3, '2026-09-10 11:30:00');    -- SSD NVMe 512GB
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (2, 5, 6, '2026-09-11 14:30:00');   -- Pronto
UPDATE ordem SET id_forma_pagamento = 1 WHERE id = 2;                                  -- Dinheiro (a pagar na retirada)

-- ===== OS 3: Smart TV LG -> Em Diagnóstico (sem peças: ainda não há orçamento aprovado) =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (3, 2, 6, '2026-09-15 15:00:00');   -- Em Diagnóstico
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (3, 10, (SELECT preco FROM servico WHERE id = 10), 1, '2026-09-15 16:00:00');     -- Troca de Barra de LED de Smart TV

-- ===== OS 4: PlayStation 5 -> Em Reparo =====
INSERT INTO ordem_situacao (id_ordem, id_nova_situacao, id_funcionario, data_situacao) VALUES
    (4, 3, 6, '2026-09-20 15:00:00'),   -- Orçamento Aprovado
    (4, 4, 7, '2026-09-20 16:00:00');   -- Em Reparo
INSERT INTO ordem_servico (id_ordem, id_servico, preco_praticado, quantidade, data_execucao) VALUES
    (4, 14, (SELECT preco FROM servico WHERE id = 14), 1, '2026-09-20 16:30:00');     -- Higienização / Metal Líquido (Console)
UPDATE ordem SET id_forma_pagamento = 4 WHERE id = 4;                                  -- Cartão de Crédito - À Vista

-- ---------------------------------------------------------------
-- Descarte (saida_peca = somente descarte; técnico pode descartar)
-- ---------------------------------------------------------------
INSERT INTO saida_peca (id_peca, preco, quantidade, motivo, id_funcionario, id_funcionario_cargo, data_cadastro) VALUES
    (5, 6000, 1, 'Descarte por defeito/avaria: bisnaga ressecada', 2, 3, '2026-09-05 10:00:00');
