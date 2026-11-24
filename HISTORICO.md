# Histórico do desenvolvimento

O TechFix foi desenvolvido pelo grupo ao longo de várias etapas, do briefing inicial à consolidação dos dois bancos. As datas abaixo são as reais; os artefatos antigos estão preservados em `desenvolvimento/`.

## Fases

| Período | Fase | O que foi feito | Artefatos neste repositório |
|---|---|---|---|
| 18/09/2026 | Requisitos e repositório | Recebimento do briefing (Atividade BD), criação do repositório, primeiro envio dos arquivos e template do dicionário de dados. | [docs/requisitos/Atividade BD - TechFix.pdf](docs/requisitos/Atividade%20BD%20-%20TechFix.pdf); [desenvolvimento/2026-09-18_dicionario_template.xlsx](desenvolvimento/2026-09-18_dicionario_template.xlsx); [desenvolvimento/2026-09-18_dicionario_rascunho.ods](desenvolvimento/2026-09-18_dicionario_rascunho.ods) |
| 18/09 – 21/09/2026 | Modelagem conceitual | Primeiras entidades (cliente, funcionário, cargo, situação, equipamento) e ajustes no modelo conceitual. | [desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio](desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio) (versão revisada) |
| 18/09 – 02/10/2026 | Dicionário de dados (início) | O dicionário começa com cliente e funcionário e é ampliado a cada nova tabela. | [desenvolvimento/2026-09-18_dicionario_template.xlsx](desenvolvimento/2026-09-18_dicionario_template.xlsx) |
| 21/09 – 25/09/2026 | Modelo lógico | Montagem do modelo lógico; a ordem de serviço entra nos modelos conceitual e lógico. | [desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio](desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio) |
| 25/09/2026 | Regras de acesso | Restrição de cargo: só gerente e atendente cadastram clientes (CHECK). | [desenvolvimento/2026-09-28_techfix_schema_mysql.sql](desenvolvimento/2026-09-28_techfix_schema_mysql.sql) |
| 21/09 – 05/10/2026 | Modelo físico | Testes de funções no modelo físico, primeiro script do banco e tabelas de tipo, modelo, marca e equipamento. Saem a DDL MySQL v1 (28/09) e o rascunho em SQLite (05/10). | [desenvolvimento/2026-09-28_techfix_schema_mysql.sql](desenvolvimento/2026-09-28_techfix_schema_mysql.sql); [desenvolvimento/2026-10-05_rascunho_modelo_sqlite.drawio](desenvolvimento/2026-10-05_rascunho_modelo_sqlite.drawio) |
| 28/09 – 16/10/2026 | Módulo B (catálogo e OS) | Categorias, serviços, peças, situação e ordem de serviço; o módulo B é concluído em 16/10. Dicionário v1 completo em 28/09. | [desenvolvimento/2026-09-28_dicionario_de_dados_v1.xlsx](desenvolvimento/2026-09-28_dicionario_de_dados_v1.xlsx) |
| 28/09 – 23/10/2026 | Views e carga de dados | Views de consulta e população de categorias, serviços, peças, equipamentos, marcas, modelos, tipos e ordens. | [desenvolvimento/2026-09-28_techfix_schema_mysql.sql](desenvolvimento/2026-09-28_techfix_schema_mysql.sql) |
| 19/10/2026 | Módulo C (ordens e situação) | Correção da tabela de ordens, relações com serviços, peças e situação, inserção dos status, diagrama conceitual + lógico revisado e dicionário editado. | [desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio](desenvolvimento/2026-10-19_modelo_conceitual_logico_mysql.drawio) |
| 23/10 – 30/10/2026 | Triggers | Primeiro trigger funcionando (aula de 23/10), trigger de valor total da OS e trigger contra estoque negativo. | [desenvolvimento/2026-09-28_techfix_schema_mysql.sql](desenvolvimento/2026-09-28_techfix_schema_mysql.sql) |
| 19/10 – 06/11/2026 | Entrada e saída de peças | Tabelas e entidades de entrada/saída de peças, com controle de estoque. | [banco_entrega/](banco_entrega/) (versão final: `entrada_peca` e `saida_peca`) |
| 06/11 – 23/11/2026 | Revisão de diagramas e dicionário | Ajustes no MER, finalização do dicionário e atualização dos diagramas conforme o script. | [modelos/entrega/](modelos/entrega/); [docs/dicionario_de_dados_entrega.xlsx](docs/dicionario_de_dados_entrega.xlsx) |
| 23/11 – 24/11/2026 | Consolidação | Revisão completa contra RF01–RF11 e RN01–RN04, com correções. Geram-se o **Banco de Entrega** (18 tabelas, todas as regras no banco, testes automatizados) e o **Banco Upgrade** (31 tabelas: permissões, auditoria, kardex, máquina de estados, pagamentos). Também saem DER, MER, dicionários e script único de cada banco, e a organização deste repositório. | [banco_entrega/](banco_entrega/); [banco_upgrade/](banco_upgrade/); [modelos/](modelos/); [docs/](docs/) |

## Evolução técnica

- **MySQL v1 (17 tabelas):** primeiro esquema do grupo, com procedure e triggers, registrado em `desenvolvimento/2026-09-28_techfix_schema_mysql.sql`.
- **Rascunho em SQLite:** em 05/10 o modelo foi adaptado para o dialeto SQLite (`desenvolvimento/2026-10-05_rascunho_modelo_sqlite.drawio`), adotando um SGBD que roda em um único arquivo.
- **Modelo em SQLite com regras de cargo, histórico de situação e estoque:** CHECK de cargo para quem cadastra, histórico de situações da ordem e triggers de total da OS e de estoque.
- **Banco de Entrega (18 tabelas):** tabelas `STRICT`, FK composta de cargo, 22 triggers e 3 views; RN01–RN04 garantidas no próprio banco (`banco_entrega/`).
- **Banco Upgrade (31 tabelas):** permissões por cargo, auditoria JSON, razão de estoque (kardex) com custo médio, máquina de estados da OS, orçamento e pagamentos múltiplos e parcelados (`banco_upgrade/`).
