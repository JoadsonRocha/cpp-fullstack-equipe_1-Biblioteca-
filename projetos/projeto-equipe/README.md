# Projeto Final — Biblioteca

Sistema full stack para cadastro e controle de acervo de **livros** e **autores**, com API REST em C++17, banco de dados MariaDB em Docker e front-end em HTML, CSS e JavaScript puro.

```
Navegador (public/*.html + app.js)  ⇄  API em C++17 (cpp-httplib + nlohmann/json)  ⇄  MariaDB (Docker)
```

## Funcionalidades

- **Livros (entidade principal):** listar, buscar (`?busca=` em título, gênero, autor ou ISBN), filtrar por gênero ou autor (`?genero=` e `?autor_id=`), visualizar por ID, cadastrar, editar e excluir.
- **Autores (entidade de apoio):** listar (com total de títulos e exemplares), buscar, visualizar por ID, listar livros de um autor (`GET /api/autores/:id/livros`), cadastrar, editar e excluir (com bloqueio `409` caso existam livros vinculados).
- **Resumo do acervo:** rota `GET /api/livros/resumo` com totais de títulos, exemplares, autores, livros sem exemplares e distribuição por gênero e por autor, exibidos em `resumo.html`.
- **Destaque visual:** livros com `exemplares = 0` aparecem destacados na tabela principal.

## Como executar (do zero, em outro computador)

1. **Requisitos:** `g++` com suporte a C++17 (MSYS2 UCRT64 no Windows), biblioteca cliente do MariaDB (`libmariadb`) e Docker Desktop aberto. Passo a passo completo em [`../guia/01-preparar-ambiente.md`](../guia/01-preparar-ambiente.md).
2. **Subir o banco** (na pasta `projetos/projeto-equipe`):

   ```bash
   docker compose up -d --wait
   ```

   Isso cria o banco `projeto_iteam`, executa o `schema.sql` automaticamente e insere autores e livros de exemplo.
   Para **recriar o banco do zero** após alterações no `schema.sql`:

   ```bash
   docker compose down -v
   docker compose up -d --wait
   ```

3. **Compilar** (na pasta `projetos/projeto-equipe`):
   - Terminal do MSYS2 UCRT64: `./build.sh`
   - `cmd` / PowerShell (com `g++` e `libmariadb` configurados): `build.bat`
4. **Executar** (dentro de `projetos/projeto-equipe`, para o servidor encontrar `./public`):
   - MSYS2/Linux: `./build/servidor.exe` (ou `./build.sh rodar`)
   - Windows `cmd`: `build\servidor.exe`
5. **Acessar no navegador:** <http://localhost:8080>

> Só um container MariaDB por vez pode usar a porta `3306`. Se outro projeto (`starter-kit` ou `demo`) estiver usando a porta, execute `docker compose down` naquela pasta antes.

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

## Exemplos de requisição com `curl`

```bash
# 1. Criar autor
curl -X POST http://localhost:8080/api/autores \
  -d '{"nome":"Jorge Amado","nacionalidade":"Brasileira"}'

# 2. Criar livro válido
curl -X POST http://localhost:8080/api/livros \
  -d '{"titulo":"Capitães da Areia","autor_id":6,"genero":"Romance","ano_publicacao":1937,"isbn":"9788535914061","exemplares":4}'

# 3. Criar livro sem título -> 422 com detalhes
curl -X POST http://localhost:8080/api/livros \
  -d '{"titulo":"","autor_id":1}'

# 4. Criar livro com ano inválido -> 422
curl -X POST http://localhost:8080/api/livros \
  -d '{"titulo":"Teste","autor_id":1,"ano_publicacao":3000}'

# 5. Criar livro com autor_id inexistente -> 422 ("autor_id nao existe")
curl -X POST http://localhost:8080/api/livros \
  -d '{"titulo":"Teste","autor_id":9999}'

# 6. Criar dois livros com o mesmo ISBN -> segundo retorna 409
curl -X POST http://localhost:8080/api/livros \
  -d '{"titulo":"Outro","autor_id":1,"isbn":"9788535910663"}'

# 7. Criar dois livros sem ISBN -> ambos funcionam (NULLIF grava NULL)
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 1","autor_id":1}'
curl -X POST http://localhost:8080/api/livros -d '{"titulo":"Sem ISBN 2","autor_id":1}'

# 8. Buscar ID inexistente -> 404 | ID inválido -> 400
curl http://localhost:8080/api/livros/9999
curl http://localhost:8080/api/livros/abc

# 9. Apagar autor que possui livros -> 409
curl -X DELETE http://localhost:8080/api/autores/1
```

## Banco de dados

| Tabela | Colunas principais | Relacionamentos / regras |
|--------|--------------------|--------------------------|
| `autores` | `id`, `nome`, `nacionalidade`, `criado_em` | `nome` obrigatório e `UNIQUE` (`uq_autores_nome`) |
| `livros` | `id`, `titulo`, `autor_id`, `genero`, `ano_publicacao`, `isbn`, `exemplares`, `criado_em` | `autor_id` → `autores.id` (`ON DELETE RESTRICT`); `isbn` `UNIQUE` opcional (`NULLIF`); `CHECK` em `ano_publicacao` (`1000..2100`) e `exemplares` (`>= 0`) |

```
autores (1) ───────< (N) livros
```

## Estrutura do projeto

```
projeto-equipe/
├── docker-compose.yml            container MariaDB
├── schema.sql                    tabelas autores e livros + dados de exemplo
├── build.sh / build.bat          scripts de compilação
├── libs/                         cpp-httplib e nlohmann/json
├── src/
│   ├── main.cpp                  inicialização e registro das rotas
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
