# Equipe

## Identificação

| Campo | Preencher |
|-------|-----------|
| Nome da equipe | Equipe 1 |
| Tema (📚 Biblioteca · 🐾 Clínica Pet · 🛒 Estoque de Loja) | 📚 Biblioteca |
| Nome do projeto | Projeto-Biblioteca (`Projeto-Biblioteca/` na raiz do repositório) |
| Link da cópia da equipe no GitHub | <https://github.com/JoadsonRocha/cpp-fullstack-equipe_1-Biblioteca-> |
| Tag de entrega | `projeto-final` |

## Integrantes

| Nome | Usuário no GitHub | Papel principal (pode revezar) |
|------|-------------------|--------------------------------|
| Joadson Rocha | `JoadsonRocha` | [Preencher papel] |
| [Preencher nome] | `[Preencher usuário]` | [Preencher papel] |
| [Preencher nome] | `[Preencher usuário]` | [Preencher papel] |
| [Preencher nome] | `[Preencher usuário]` | [Preencher papel] |

## Como executar (do zero, em outro computador)

1. **Requisitos:** `g++` com suporte a C++17 (MSYS2 UCRT64 no Windows), `libmariadb` (`pacman -S mingw-w64-ucrt-x86_64-libmariadbclient`) e Docker Desktop aberto.
2. **Banco:** na pasta `Projeto-Biblioteca`, rodar `docker compose up -d --wait` (ou `docker compose --profile fullstack up -d --build --wait` para subir banco + API em containers). Para recriar do zero após editar `schema.sql`, rodar `docker compose down -v` e subir novamente.
3. **Compilar:** `./build.sh` no MSYS2 UCRT64 (ou `build.bat` no `cmd`).
4. **Executar:** na pasta `Projeto-Biblioteca`, rodar `./build/servidor.exe` (ou `build\servidor.exe`).
5. **Acessar:** <http://localhost:8080>

## Rotas da API

| Método | Caminho | O que faz | Status possíveis |
|--------|---------|-----------|------------------|
| GET | `/api/saude` · `/api/saude/banco` | Saúde da API e conexão com MariaDB | 200 · 500 |
| GET | `/api/autores` | Lista autores (aceita `?busca=`) | 200 |
| GET | `/api/autores/:id` | Busca um autor por ID | 200 · 400 · 404 |
| GET | `/api/autores/:id/livros` | Lista os livros do autor | 200 · 400 · 404 |
| POST | `/api/autores` | Cria um autor | 201 · 400 · 409 · 422 |
| PUT | `/api/autores/:id` | Atualiza um autor | 200 · 400 · 404 · 409 · 422 |
| DELETE | `/api/autores/:id` | Remove um autor (bloqueia se tiver livros) | 204 · 400 · 404 · 409 |
| GET | `/api/livros` | Lista livros (`?busca=`, `?genero=`, `?autor_id=`) | 200 · 422 |
| GET | `/api/livros/resumo` | Estatísticas do acervo | 200 |
| GET | `/api/livros/:id` | Busca um livro por ID | 200 · 400 · 404 |
| POST | `/api/livros` | Cria um livro | 201 · 400 · 409 · 422 |
| PUT | `/api/livros/:id` | Atualiza um livro | 200 · 400 · 404 · 409 · 422 |
| DELETE | `/api/livros/:id` | Remove um livro | 204 · 400 · 404 |

## Banco de dados

| Tabela | Colunas principais | Relacionamentos / regras |
|--------|--------------------|--------------------------|
| `autores` | `id`, `nome`, `nacionalidade`, `criado_em` | `nome` obrigatório e `UNIQUE` |
| `livros` | `id`, `titulo`, `autor_id`, `genero`, `ano_publicacao`, `isbn`, `exemplares`, `criado_em` | `autor_id` → `autores.id` (FK `ON DELETE RESTRICT`); `isbn` `UNIQUE` opcional via `NULLIF(?, '')`; `CHECK` em `ano_publicacao` (1000–2100) e `exemplares` (≥ 0) |

```
autores (1) ───────< (N) livros
```

## Divisão de tarefas

| Dia | Quem | O que foi feito |
|-----|------|-----------------|
| 6 | [Preencher] | Configuração do ambiente e leitura do starter kit |
| 7 | [Preencher] | Modelagem do `schema.sql` e criação das rotas iniciais |
| 8 | [Preencher] | CRUD completo de livros e autores + telas front-end |
| 9 | [Preencher] | Extras (resumo, filtros), testes e documentação |

## Decisões e dificuldades

- **Uso de `NULLIF(?, '')` para campos opcionais (especialmente `isbn` e `ano_publicacao`):** como a classe `Conexao` envia os parâmetros como texto, strings vazias impediriam cadastrar mais de um livro sem ISBN devido à restrição `UNIQUE`. Com `NULLIF(?, '')`, o banco grava `NULL` real.
- **Validação prévia de `autor_id` nas rotas de livros:** antes de inserir ou atualizar um livro, a API verifica se o autor existe e responde `422` com `"autor_id nao existe"`, evitando um `409` genérico de violação de chave estrangeira.
- **Registro de `/api/livros/resumo` antes de `/api/livros/:id`:** evita que a palavra `"resumo"` seja interpretada como parâmetro `:id` e gere erro `400`.

## Extras implementados

- [x] Busca / filtro (`?busca=`, `?genero=`, `?autor_id=`)
- [x] Rota de resumo ou relatório (`GET /api/livros/resumo` + `resumo.html`)
- [ ] Paginação ou ordenação
- [x] Validações extras no front-end
- [x] Outro: listagem de livros por autor (`GET /api/autores/:id/livros`), bloqueio `409` ao excluir autor com livros e destaque visual na tabela para livros com `exemplares = 0`

## Checklist de entrega (dia 9)

- [x] O projeto compila sem avisos (`-Wall -Wextra`)
- [x] `docker compose up -d --wait` cria o banco do zero (o `schema.sql` é executado sozinho) e há dados de exemplo
- [x] Todo SQL usa parâmetros `?`
- [ ] CRUD completo funciona pela tela *(validar após subir banco e servidor)*
- [ ] O README da equipe foi testado em outro computador
- [ ] Todos os integrantes têm *commits* no próprio usuário
- [ ] A tag `projeto-final` foi criada e enviada (`git push origin projeto-final`) e o link foi entregue ao professor
