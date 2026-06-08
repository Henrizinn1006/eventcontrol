<h1 align="center">📦 EventControl</h1>
<p align="center">Sistema completo para gerenciamento de eventos e controle de estoque — mobile + API</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white"/>
</p>

---

## 📌 Sobre o projeto

O **EventControl** é um sistema full-stack (mobile + backend) para empresas de eventos e locação de itens. Conecta o **estoque físico** a cada **evento**, permitindo controle em tempo real de disponibilidade, movimentações e relatórios.

---

## 🛠️ Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| App Mobile | Flutter (Android e iOS) |
| Backend | Python 3 + FastAPI |
| Banco | MySQL |
| ORM | SQLAlchemy |
| Autenticação | JWT |
| Docs | Swagger / OpenAPI |
| Servidor | Uvicorn |

---

## 🚀 Como rodar

### Backend (API)

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload
```

Swagger: **http://localhost:8000/docs**

### App Flutter

```bash
flutter pub get
flutter run
```

> Configure a URL da API em `lib/services/api_service.dart` apontando para `http://localhost:8000`.

---

## 📊 Funcionalidades

- ✅ Autenticação e controle de acesso por usuário (JWT)
- ✅ Cadastro de itens com categorias e disponibilidade
- ✅ Criação e gerenciamento de eventos
- ✅ Associação de itens a eventos com controle de quantidade
- ✅ Geração de PDF por evento
- ✅ Dark mode / Light mode
- ✅ API REST documentada com Swagger
- ✅ Conclusão com devolução automática de itens ao estoque

---

## 🔌 API REST

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/auth/login` | Autenticação JWT |
| GET/POST | `/itens` | Listar / Criar itens |
| GET/POST | `/eventos` | Listar / Criar eventos |
| POST | `/eventos/{id}/itens` | Adicionar item ao evento |
| GET | `/relatorios/{evento_id}` | Gerar relatório PDF |

---

## 👨‍💻 Autor

**Henrique Tavares**
- GitHub: [@Henrizinn1006](https://github.com/Henrizinn1006)
- LinkedIn: [linkedin.com/in/henriquetavares1006](https://linkedin.com/in/henriquetavares1006)
- Email: htavares803@gmail.com
