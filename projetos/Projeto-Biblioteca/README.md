# Projeto Final — Biblioteca

> 🎤 **Apresentação da equipe:** consulte o roteiro completo (divisão para 4 integrantes, demonstração ao vivo, mapa das rotas e respostas para a banca) em **[APRESENTACAO.md](APRESENTACAO.md)**.

Sistema full stack para cadastro e controle de acervo de **livros** e **autores**, com API REST em C++17, banco de dados MariaDB e front-end em HTML, CSS e JavaScript puro.

```
Navegador (public/*.html + app.js)  ⇄  API em C++17 (cpp-httplib + nlohmann/json)  ⇄  MariaDB
```

## Funcionalidades

- **Livros (entidade principal):** listar, buscar (`?busca=` em título, gênero, autor ou ISBN), filtrar por gênero ou autor (`?genero=` e `?autor_id=`), buscar por ID, cadastrar, editar e excluir.
- **Autores (entidade de apoio):** listar (com total de títulos e exemplares), buscar (`?busca=`), buscar por ID, listar todos os livros de um autor (`GET /api/autores/:id/livros`), cadastrar, editar e excluir (bloqueando com `409` quando existem livros vinculados).
- **Resumo do acervo:** rota `GET /api/livros/resumo` com totais de títulos, exemplares, autores, livros sem exemplares e distribuição por gênero e por autor, exibidos em `resumo.html`.
- **Destaque visual:** livros com `exemplares = 0` ficam destacados na tabela principal (`linha-alerta`).

## Telas do sistema

- **`index.html` (`config.js`):** gestão de **Livros** (formulário de criar/editar com seleção dinâmica de autor, busca, filtro por autor e destaque para livros esgotados).
- **`autores.html` (`config-autores.js`):** gestão de **Autores** (cadastro, edição, busca e exclusão com contagem de títulos e exemplares).
- **`resumo.html` (`resumo.js`):** painel de indicadores gerais do acervo e barras de distribuição por gênero e por autor.

## Como executar (do zero, em outro computador)

1. **Requisitos:** `g++` com suporte a C++17 (MSYS2 UCRT64 no Windows), biblioteca cliente do MariaDB (`libmariadb`) e Docker Desktop aberto (ou MariaDB local). Passo a passo completo em [`../guia/01-preparar-ambiente.md`](../guia/01-preparar-ambiente.md).
2. **Subir com Docker** (na pasta `projetos/Projeto-Biblioteca`):

   - **Modo 1 — Só o banco MariaDB** (padrão do curso, para compilar e rodar o servidor C++ localmente):
     ```bash
     docker compose up -d --wait
     ```
   - **Modo 2 — Stack completa em Docker** (sobe o MariaDB + compila e executa a API em C++ e o front-end via `Dockerfile`):
     ```bash
     docker compose --profile fullstack up -d --build --wait
     ```
     Nesse modo, basta abrir <http://localhost:8080> diretamente (não precisa compilar no Windows).

   O banco `projeto_iteam` executa o `schema.sql` automaticamente na primeira criação e insere 5 autores e 10 livros de exemplo.
   Para **recriar o banco do zero** após alterações no `schema.sql`:

   ```bash
   docker compose down -v
   docker compose up -d --wait
   ```

   > Só um serviço MariaDB por vez pode usar a porta `3306`. Se outro projeto (`starter-kit` ou `demo`) ou um MariaDB local estiver usando a porta, pare-o antes.

3. **Compilar localmente (Modo 1)** (na pasta `projetos/Projeto-Biblioteca`):
   - Terminal do **MSYS2 UCRT64**: `./build.sh`
   - **`cmd` / PowerShell** (com `C:\msys64\ucrt64\bin` no `PATH`): `build.bat`
4. **Executar localmente (Modo 1)** (dentro de `projetos/Projeto-Biblioteca`, para o servidor encontrar `./public`):
   - MSYS2/Linux: `./build/servidor.exe` (ou `./build.sh rodar`)
   - Windows `cmd` / PowerShell: `build\servidor.exe`
5. **Acessar no navegador:** <http://localhost:8080>

### Variáveis de ambiente (opcional)

Os padrões atendem ao `docker-compose.yml`. Para conectar a outro banco ou mudar o endereço/porta sem recompilar:

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `DB_HOST` | `127.0.0.1` | Endereço do MariaDB (`db` dentro do Docker) |
| `DB_PORTA` | `3306` | Porta do MariaDB |
| `DB_USUARIO` | `iteam` | Usuário do banco |
| `DB_SENHA` | `iteam123` | Senha do banco |
| `DB_NOME` | `projeto_iteam` | Nome do banco |
| `HOST` | `127.0.0.1` | IP de escuta HTTP (`0.0.0.0` dentro do Docker) |
| `PORTA` | `8080` | Porta HTTP do servidor (ou passe como argumento: `servidor.exe 8081`) |

## Rotas da API

| Método | Caminho | O que faz | Status possíveis |
|--------|---------|-----------|------------------|
| GET | `/api/saude` | Verifica se a API está no ar | 200 |
| GET | `/api/saude/banco` | Testa conexão com o MariaDB | 200 · 500 |
| GET | `/api/autores` | Lista autores (aceita `?busca=`) | 200 |
| GET | `/api/autores/:id` | Busca um autor por ID | 200 · 400 · 404 |
| GET | `/api/autores/:id/livros` | Lista todos os livros de um autor | 200 · 400 · 404 |
| POST | `/api/autores` | Cria um autor | 201 · 400 · 409 · 422 |
| PUT | `/api/autores/:id` | Atualiza um autor | 200 · 400 · 404 · 409 · 422 |
| DELETE | `/api/autores/:id` | Remove um autor (bloqueia se tiver livros) | 204 · 400 · 404 · 409 |
| GET | `/api/livros` | Lista livros (aceita `?busca=`, `?genero=`, `?autor_id=`) | 200 · 422 |
| GET | `/api/livros/resumo` | Estatísticas do acervo (totais, esgotados, por gênero/autor) | 200 |
| GET | `/api/livros/:id` | Busca um livro por ID | 200 · 400 · 404 |
| POST | `/api/livros` | Cria um livro | 201 · 400 · 409 · 422 |
| PUT | `/api/livros/:id` | Atualiza um livro | 200 · 400 · 404 · 409 · 422 |
| DELETE | `/api/livros/:id` | Remove um livro | 204 · 400 · 404 |

## Exemplos de requisição e resposta (`curl`)

```bash
# 1. Criar autor -> 201 Created
curl -X POST http://localhost:8080/api/autores \
  -H "Content-Type: application/json" \
  -d '{"nome":"Jorge Amado","nacionalidade":"Brasileira"}'
# Resposta 201:
# {"id":6,"nome":"Jorge Amado","nacionalidade":"Brasileira","criado_em":"2026-11-25 14:00:00","total_livros":0,"total_exemplares":0}

# 2. Criar livro válido -> 201 Created
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Capitães da Areia","autor_id":6,"genero":"Romance","ano_publicacao":1937,"isbn":"9788535914061","exemplares":4}'
# Resposta 201:
# {"id":11,"titulo":"Capitães da Areia","autor_id":6,"autor_nome":"Jorge Amado","genero":"Romance","ano_publicacao":1937,"isbn":"9788535914061","exemplares":4,"criado_em":"2026-11-25 14:01:00"}

# 3. Criar livro sem título e com ano inválido -> 422 Unprocessable Entity
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"","autor_id":1,"ano_publicacao":3000}'
# Resposta 422:
# {"erro":"Dados invalidos","detalhes":["titulo e obrigatorio","ano_publicacao deve ser um numero inteiro de 1000 a 2100"]}

# 4. Criar livro com autor_id inexistente -> 422 Unprocessable Entity
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Teste","autor_id":9999}'
# Resposta 422:
# {"erro":"Dados invalidos","detalhes":["autor_id nao existe"]}

# 5. Criar livro com ISBN duplicado -> 409 Conflict
curl -X POST http://localhost:8080/api/livros \
  -H "Content-Type: application/json" \
  -d '{"titulo":"Outro","autor_id":1,"isbn":"9788535910663"}'
# Resposta 409:
# {"erro":"Ja existe um registro com este valor unico"}

# 6. Criar dois livros sem ISBN -> ambos retornam 201 (NULLIF grava NULL)
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 1","autor_id":1}'
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 2","autor_id":1}'

# 7. Buscar ID inexistente -> 404 | ID inválido -> 400
curl http://localhost:8080/api/livros/9999
# Resposta 404: {"erro":"Livro nao encontrado"}
curl http://localhost:8080/api/livros/abc
# Resposta 400: {"erro":"Id invalido"}

# 8. Apagar autor que possui livros -> 409 Conflict
curl -X DELETE http://localhost:8080/api/autores/1
# Resposta 409: {"erro":"Operacao bloqueada por registros relacionados"}

# 9. Resumo do acervo -> 200 OK
curl http://localhost:8080/api/livros/resumo
# Resposta 200:
# {"total_livros":10,"total_exemplares":22,"esgotados":2,"total_autores":5,"por_genero":[...],"por_autor":[...]}
```

## Banco de dados

| Tabela | Colunas principais | Relacionamentos / regras |
|--------|--------------------|--------------------------|
| `autores` | `id`, `nome`, `nacionalidade`, `criado_em` | `nome` obrigatório e `UNIQUE` (`uq_autores_nome`) |
| `livros` | `id`, `titulo`, `autor_id`, `genero`, `ano_publicacao`, `isbn`, `exemplares`, `criado_em` | `autor_id` → `autores.id` (`ON DELETE RESTRICT`); `isbn` `UNIQUE` opcional (`NULLIF`); `CHECK` em `ano_publicacao` (`1000..2100`) e `exemplares` (`>= 0`) |

```
autores (1) ───────< (N) livros
```

## Arquitetura e fluxo de uma requisição

1. **Front-end (`public/`):** `app.js` lê as definições de `config.js` (Livros) ou `config-autores.js` (Autores) e envia `fetch()` em JSON; `resumo.js` consome `/api/livros/resumo`.
2. **Rotas (`src/rotas_*.cpp`):** fazem o *parse* do JSON (`util::lerCorpoObjeto`), validam campos (`validacao.hpp`), conferem a existência de `autor_id` e chamam o repositório dentro de `util::comBanco`.
3. **Repositórios (`src/*_repositorio.cpp`):** concentram todo o SQL usando exclusivamente *prepared statements* com parâmetros `?` via `Conexao` (`banco.hpp`/`banco.cpp`, com gerenciamento RAII).
4. **Tratamento de erros (`src/http_util.hpp`):** exceções de banco viram respostas JSON adequadas (`1062` → `409`, `1451`/`1452` → `409`, `4025` → `422`), sem derrubar o servidor.

## Estrutura do projeto

```
Projeto-Biblioteca/
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
│   ├── config.hpp                variáveis de ambiente e porta
│   ├── banco.hpp / .cpp          conexão RAII e queries com parâmetros "?"
│   ├── http_util.hpp             respostas JSON e tratamento de erros
│   ├── parametros.hpp            helpers para parâmetros "?" e LIKE
│   ├── validacao.hpp             validações de strings e faixas inteiras
│   ├── autor_repositorio.hpp/.cpp
│   ├── livro_repositorio.hpp/.cpp
│   ├── rotas_autores.hpp/.cpp
│   └── rotas_livros.hpp/.cpp
└── public/
    ├── index.html                tela principal de livros
    ├── autores.html              tela de autores
    ├── resumo.html               painel de resumo do acervo
    ├── config.js                 configuração da tela de livros
    ├── config-autores.js         configuração da tela de autores
    ├── app.js                    CRUD genérico
    ├── resumo.js                 carregamento do painel de resumo
    └── estilo.css                estilos responsivos
```
