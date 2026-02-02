# eventcontrol_api

EventControl — Sistema de Gerenciamento de Eventos

O EventControl é um sistema completo para gerenciamento de eventos e controle de itens, desenvolvido para simular um cenário real de negócio (locação, controle, organização e acompanhamento de eventos).

O projeto foi criado com foco em backend, utilizando API REST, banco de dados relacional e integração com aplicação cliente, seguindo boas práticas de organização e arquitetura.

## Objetivo do Projeto

- Gerenciar eventos
- Controlar itens vinculados a cada evento
- Registrar usuários e permissões
- Simular um sistema real usado por empresas de eventos/decoração
- Servir como projeto prático de estudo e portfólio profissional

## Tecnologias Utilizadas

**Backend:**

- Python
- FastAPI
- Uvicorn
- MySQL
- SQLAlchemy

**Frontend / App:**

- Flutter (consumo da API)

**Outros:**

- Git & GitHub
- API REST
- JSON
- CORS Middleware
- Swagger (OpenAPI)

## Funcionalidades

- Cadastro e autenticação de usuários
- Criação e gerenciamento de eventos
- Cadastro e controle de itens
- Associação de itens a eventos
- Controle de quantidades
- API documentada com Swagger
- Estrutura preparada para expansão

## Demonstração (telas)

| Login (modo claro) | Home | Catálogo (categorias) |
| --- | --- | --- |
| ![Login (modo claro)](assets/images/loginmodoclaro.jpeg) | ![Home](assets/images/home.jpeg) | ![Catálogo (categorias)](assets/images/catalogocategoria.jpeg) |

| Itens do catálogo | Dados do item | Novo item |
| --- | --- | --- |
| ![Itens do catálogo](assets/images/itenscatalogo.jpeg) | ![Dados do item](assets/images/dadositem.jpeg) | ![Novo item](assets/images/novoitem.jpeg) |

| Nova categoria | Novo item (nova categoria) | Edição no item |
| --- | --- | --- |
| ![Adicionar categoria](assets/images/adicionarcategoria.jpeg) | ![Novo item (nova categoria)](assets/images/novoitemnovacategoria.jpeg) | ![Edição no item](assets/images/ediçãonoitem.jpeg) |

| Evento criado | Itens do evento | Adicionando itens no evento |
| --- | --- | --- |
| ![Evento criado](assets/images/teladoeventocriado.jpeg) | ![Itens do evento](assets/images/itensdoevento.jpeg) | ![Adicionando itens no evento](assets/images/adicionandoitensnoevento.jpeg) |

| Item adicionado | Modo escuro | PDF gerado |
| --- | --- | --- |
| ![Item adicionado](assets/images/itemadicionado.jpeg) | ![Modo escuro](assets/images/modoescuroerec.jpeg) | ![PDF gerado](assets/images/pdfgerado.jpeg) |

| Conclusão com devolução | Criando um evento | Alteração na disponibilidade |
| --- | --- | --- |
| ![Conclusão com devolução](assets/images/conclusãocomdevolução.jpeg) | ![Criando um evento](assets/images/criandoumevento.jpeg) | ![Alteração na disponibilidade](assets/images/alteraçãonadisponibilidade.jpeg) |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
