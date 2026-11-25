# 📚 Sistema de Biblioteca — Equipe 1

![C++17](https://img.shields.io/badge/C%2B%2B-17-00599C?style=flat-square&logo=cplusplus)
![MariaDB](https://img.shields.io/badge/MariaDB-11.8-003545?style=flat-square&logo=mariadb)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker)
![Status](https://img.shields.io/badge/Build-Sem%20Avisos%20(-Wall%20-Wextra)-2ea44f?style=flat-square)

Aplicação **Full Stack** para gestão de acervo bibliográfico (**livros** e **autores**), desenvolvida como projeto final do Módulo 08 (C++ Full Stack — ITEAM). Combina uma **API REST em C++17**, persistência em **MariaDB** com *prepared statements* (`?`) e um **front-end responsivo** em HTML, CSS e JavaScript puro servido diretamente pela API.

> 🎤 **Vai apresentar?** Acesse o roteiro completo para os 4 integrantes (10–12 min, demonstração ao vivo e respostas da banca) em **[`APRESENTACAO.md`](APRESENTACAO.md)** · 👥 **Dados da equipe:** **[`../projetos/EQUIPE.md`](../projetos/EQUIPE.md)**

---

## Sumário

1. [Visão Geral e Funcionalidades](#-visão-geral-e-funcionalidades)
2. [Telas do Sistema](#-telas-do-sistema)
3. [Como Executar (Docker e Local)](#-como-executar-docker-e-local)
4. [Rotas da API](#-rotas-da-api)
5. [Exemplos de Requisição e Resposta (`curl`)](#-exemplos-de-requisição-e-resposta-curl)
6. [Modelagem do Banco de Dados](#-modelagem-do-banco-de-dados)
7. [Arquitetura e Fluxo de Requisição](#-arquitetura-e-fluxo-de-requisição)
8. [Estrutura de Pastas](#-estrutura-de-pastas)
9. [Equipe e Entregáveis](#-equipe-e-entregáveis)

---

## 🎯 Visão Geral e Funcionalidades

```text
Navegador (HTML + CSS + JS)  ⇄  API REST C++17 (cpp-httplib + nlohmann/json)  ⇄  MariaDB
```

- **Livros (entidade principal):** CRUD completo (`GET`, `GET :id`, `POST`, `PUT`, `DELETE`), busca textual (`?busca=` em título, gênero, autor ou ISBN) e filtros combinados (`?genero=` e `?autor_id=`).
- **Autores (entidade de apoio):** listar com contagem de títulos e exemplares (`LEFT JOIN`), buscar (`?busca=`), buscar por ID, listar livros de um autor (`GET /api/autores/:id/livros`), criar, editar e excluir (com bloqueio `409` se houver livros vinculados).
- **Painel de Resumo:** rota `GET /api/livros/resumo` calculando totais de livros, exemplares, autores, livros sem exemplares e agrupamento por gênero e por autor.
- **Qualidade e Segurança:** 100% do SQL parametrizado com `?`, validação completa com status HTTP adequados (`200`, `201`, `204`, `400`, `404`, `409`, `422`), gerenciamento de conexão por **RAII** e compilação limpa com `-std=c++17 -Wall -Wextra`.

---

## 🖥️ Telas do Sistema

| Tela | Arquivo | O que faz |
|---|---|---|
| **Livros** | [`public/index.html`](public/index.html) + [`public/config.js`](public/config.js) | Listagem com nome do autor, busca, filtro por autor, formulário criar/editar com `<select>` dinâmico e destaque visual (`linha-alerta`) para livros com `0` exemplares. |
| **Autores** | [`public/autores.html`](public/autores.html) + [`public/config-autores.js`](public/config-autores.js) | Cadastro, edição, busca e exclusão de autores com exibição de total de títulos e exemplares. |
| **Resumo** | [`public/resumo.html`](public/resumo.html) + [`public/resumo.js`](public/resumo.js) | Cartões de indicadores gerais e barras proporcionais por gênero e por autor consumindo `GET /api/livros/resumo`. |

---

## 🚀 Como Executar (Docker e Local)

### Pré-requisitos
- **Modo completo com Docker:** Docker Desktop instalado e em execução.
- **Modo local (Windows/Linux):** `g++` com C++17 (MSYS2 UCRT64 no Windows) + `libmariadb` + Docker (ou MariaDB local). Guia detalhado em [`../material-professor/projetos/guia/01-preparar-ambiente.md`](../material-professor/projetos/guia/01-preparar-ambiente.md).

### Opção 1 — Subir tudo via Docker (Banco + API C++ + Front-end)

Na pasta `Projeto-Biblioteca-Equipe1`:

```bash
docker compose --profile fullstack up -d --build --wait
```

Acesse **<http://localhost:8080>** no navegador. O container `db` inicializa o banco `projeto_iteam` executando o [`schema.sql`](schema.sql) com 5 autores e 10 livros de exemplo, e o container `api` compila e inicia o servidor automaticamente.

### Opção 2 — Só o Banco em Docker + Compilação Local (padrão de avaliação)

1. **Suba o MariaDB:**
   ```bash
   docker compose up -d --wait
   ```
2. **Compile o servidor:**
   - MSYS2 UCRT64 / Linux: `./build.sh`
   - Windows `cmd` / PowerShell (com `C:\msys64\ucrt64\bin` no `PATH`): `build.bat`
3. **Execute (dentro de `Projeto-Biblioteca-Equipe1`, para localizar `./public`):**
   - MSYS2 / Linux: `./build/servidor.exe` (ou `./build.sh rodar`)
   - Windows `cmd`: `build\servidor.exe`
4. **Acesse:** <http://localhost:8080>

> **Dica:** para zerar o banco e reexecutar o `schema.sql` do zero: `docker compose --profile fullstack down -v` e suba novamente. Apenas um serviço MariaDB por vez pode usar a porta `3306`.

### Variáveis de ambiente (opcional)

| Variável | Padrão | Descrição |
|---|---|---|
| `DB_HOST` | `127.0.0.1` | Endereço do MariaDB (`db` dentro do Docker) |
| `DB_PORTA` | `3306` | Porta do MariaDB |
| `DB_USUARIO` | `iteam` | Usuário do banco |
| `DB_SENHA` | `iteam123` | Senha do banco |
| `DB_NOME` | `projeto_iteam` | Nome do banco |
| `HOST` | `127.0.0.1` | IP de escuta HTTP (`0.0.0.0` dentro do Docker) |
| `PORTA` | `8080` | Porta HTTP do servidor (também aceita argumento: `servidor.exe 8081`) |

---

## 📡 Rotas da API

| Recurso | Método | Caminho | Descrição | Status HTTP |
|---|---|---|---|---|
| **Saúde** | `GET` | `/api/saude` | Verifica se o servidor HTTP está no ar | `200` |
| **Saúde** | `GET` | `/api/saude/banco` | Testa conexão com o MariaDB (`SELECT 1`) | `200` · `500` |
| **Autores** | `GET` | `/api/autores` | Lista autores em ordem alfabética (aceita `?busca=`) | `200` |
| **Autores** | `GET` | `/api/autores/:id` | Busca um autor por ID | `200` · `400` · `404` |
| **Autores** | `GET` | `/api/autores/:id/livros` | Lista todos os livros de um autor | `200` · `400` · `404` |
| **Autores** | `POST` | `/api/autores` | Cadastra um autor | `201` · `400` · `409` · `422` |
| **Autores** | `PUT` | `/api/autores/:id` | Atualiza um autor | `200` · `400` · `404` · `409` · `422` |
| **Autores** | `DELETE` | `/api/autores/:id` | Remove um autor (bloqueia se possuir livros) | `204` · `400` · `404` · `409` |
| **Livros** | `GET` | `/api/livros` | Lista livros (aceita `?busca=`, `?genero=`, `?autor_id=`) | `200` · `422` |
| **Livros** | `GET` | `/api/livros/resumo` | Estatísticas do acervo (totais, esgotados, por gênero/autor) | `200` |
| **Livros** | `GET` | `/api/livros/:id` | Busca um livro por ID | `200` · `400` · `404` |
| **Livros** | `POST` | `/api/livros` | Cadastra um livro | `201` · `400` · `409` · `422` |
| **Livros** | `PUT` | `/api/livros/:id` | Atualiza um livro | `200` · `400` · `404` · `409` · `422` |
| **Livros** | `DELETE` | `/api/livros/:id` | Remove um livro | `204` · `400` · `404` |

---

## 🧪 Exemplos de Requisição e Resposta (`curl`)

<details>
<summary><strong>Expandir exemplos de testes com <code>curl</code> (sucesso, validação 422, conflito 409, 404/400)</strong></summary>

```bash
# 1. Criar autor -> 201 Created
curl -X POST http://localhost:8080/api/autores \
  -H "Content-Type: application/json" \
  -d '{"nome":"Jorge Amado","nacionalidade":"Brasileira"}'
# {"id":6,"nome":"Jorge Amado","nacionalidade":"Brasileira","criado_em":"2026-11-25 14:00:00","total_livros":0,"total_exemplares":0}

# 2. Criar livro válido -> 201 Created
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Capitães da Areia","autor_id":6,"genero":"Romance","ano_publicacao":1937,"isbn":"9788535914061","exemplares":4}'
# {"id":11,"titulo":"Capitães da Areia","autor_id":6,"autor_nome":"Jorge Amado","genero":"Romance","ano_publicacao":1937,"isbn":"9788535914061","exemplares":4,"criado_em":"2026-11-25 14:01:00"}

# 3. Criar livro sem título e com ano inválido -> 422 Unprocessable Entity
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"","autor_id":1,"ano_publicacao":3000}'
# {"erro":"Dados invalidos","detalhes":["titulo e obrigatorio","ano_publicacao deve ser um numero inteiro de 1000 a 2100"]}

# 4. Criar livro com autor_id inexistente -> 422 Unprocessable Entity
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Teste","autor_id":9999}'
# {"erro":"Dados invalidos","detalhes":["autor_id nao existe"]}

# 5. Criar livro com ISBN duplicado -> 409 Conflict
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Outro","autor_id":1,"isbn":"9788535910663"}'
# {"erro":"Ja existe um registro com este valor unico"}

# 6. Criar dois livros sem ISBN -> ambos retornam 201 (NULLIF grava NULL)
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 1","autor_id":1}'
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 2","autor_id":1}'

# 7. Buscar ID inexistente -> 404 | ID inválido -> 400
curl http://localhost:8080/api/livros/9999   # {"erro":"Livro nao encontrado"}
curl http://localhost:8080/api/livros/abc    # {"erro":"Id invalido"}

# 8. Apagar autor que possui livros -> 409 Conflict
curl -X DELETE http://localhost:8080/api/autores/1
# {"erro":"Operacao bloqueada por registros relacionados"}

# 9. Resumo do acervo -> 200 OK
curl http://localhost:8080/api/livros/resumo
# {"total_livros":10,"total_exemplares":22,"esgotados":2,"total_autores":5,"por_genero":[...],"por_autor":[...]}
```

</details>

---

## 🗄️ Modelagem do Banco de Dados

| Tabela | Colunas principais | Regras e restrições |
|---|---|---|
| `autores` | `id`, `nome`, `nacionalidade`, `criado_em` | `nome` `NOT NULL` e `UNIQUE` (`uq_autores_nome`) |
| `livros` | `id`, `titulo`, `autor_id`, `genero`, `ano_publicacao`, `isbn`, `exemplares`, `criado_em` | `autor_id` → `autores.id` (`ON DELETE RESTRICT`); `isbn` `UNIQUE` opcional (`NULLIF(?, '')`); `CHECK` em `ano_publicacao` (`1000..2100`) e `exemplares` (`>= 0`) |

```text
autores (1) ───────< (N) livros
```

---

## ⚙️ Arquitetura e Fluxo de Requisição

1. **Front-end (`public/`):** `app.js` lê `config.js` (Livros) ou `config-autores.js` (Autores) e envia `fetch()` em JSON; `resumo.js` consome `/api/livros/resumo`.
2. **Rotas (`src/rotas_*.cpp`):** fazem *parse* do JSON (`util::lerCorpoObjeto`), validam todos os campos (`validacao.hpp`), confirmam `autor_id` antes da escrita e delegam aos repositórios via `util::comBanco`.
3. **Repositórios (`src/*_repositorio.cpp`):** concentram **todo o SQL**, usando exclusivamente *prepared statements* com `?` via `Conexao` (`banco.hpp`/`banco.cpp`, gerenciada por **RAII**).
4. **Erros padronizados (`src/http_util.hpp`):** exceções do MariaDB (`ErroBanco`) viram JSON adequado (`1062` → `409`, `1451`/`1452` → `409`, `4025`/`3819` → `422`), mantendo o servidor no ar.

---

## 📁 Estrutura de Pastas

```text
Projeto-Biblioteca-Equipe1/
├── APRESENTACAO.md               roteiro da apresentação e perguntas da banca
├── README.md                     documentação principal do projeto
├── Dockerfile                    build multi-stage da API C++17 para Docker
├── .dockerignore                 ignora binários locais no contexto Docker
├── docker-compose.yml            MariaDB + perfil fullstack (db + api) + adminer
├── schema.sql                    tabelas autores e livros + dados de exemplo
├── build.sh / build.bat          scripts de compilação local
├── libs/                         cpp-httplib e nlohmann/json
├── src/
│   ├── main.cpp                  inicialização, arquivos estáticos e rotas
│   ├── config.hpp                variáveis de ambiente (DB_*, HOST, PORTA)
│   ├── banco.hpp / .cpp          conexão RAII e queries com parâmetros "?"
│   ├── http_util.hpp             respostas JSON e tratamento de erros
│   ├── parametros.hpp            helpers para parâmetros "?" e LIKE
│   ├── validacao.hpp             validações de strings e faixas inteiras
│   ├── autor_repositorio.hpp/.cpp
│   ├── livro_repositorio.hpp/.cpp
│   ├── rotas_autores.hpp/.cpp
│   └── rotas_livros.hpp/.cpp
└── public/
    ├── favicon.svg               ícone SVG do título/aba do navegador
    ├── index.html                tela principal de livros
    ├── autores.html              tela de autores
    ├── resumo.html               painel de resumo do acervo
    ├── config.js                 configuração da tela de livros
    ├── config-autores.js         configuração da tela de autores
    ├── app.js                    CRUD genérico
    ├── resumo.js                 carregamento do painel de resumo
    └── estilo.css                estilos responsivos
```

---

## 👥 Equipe e Entregáveis

- **Integrantes:** Joadson Rocha (`JoadsonRocha`), Eduardo Felipe *(demais integrantes em [`../projetos/EQUIPE.md`](../projetos/EQUIPE.md))*
- **Documentação da equipe:** [`../projetos/EQUIPE.md`](../projetos/EQUIPE.md)
- **Roteiro da apresentação:** [`APRESENTACAO.md`](APRESENTACAO.md)
- **Rubrica de avaliação:** [`../material-professor/projetos/rubrica.md`](../material-professor/projetos/rubrica.md)
- **Tag de entrega final:** `projeto-final`
