# Apresentação do Projeto Final — Biblioteca

> Roteiro estruturado para a apresentação em equipe (**10 a 12 minutos · 4 integrantes**), cobrindo demonstração ao vivo, arquitetura, todas as rotas da API, fluxo de uma requisição e respostas às perguntas da [rubrica](../material-professor/projetos/rubrica.md).

---

## 1. Divisão do tempo e dos integrantes (10–12 min)

| Tempo | Integrante | Bloco | O que apresentar |
|---|---|---|---|
| **0:00 – 2:30** | Integrante 1 | **Visão geral, Docker e Banco** | Problema (gestão de livros e autores), arquitetura, `Dockerfile` / `docker-compose.yml` e `schema.sql` (PK, FK `ON DELETE RESTRICT`, `UNIQUE`, `CHECK`). |
| **2:30 – 5:30** | Integrante 2 | **Back-end C++ e Rotas** | Organização em camadas (`main.cpp` → `rotas_*` → `validacao.hpp` → `*_repositorio` → `banco.cpp`), RAII e parametrização `?`. |
| **5:30 – 9:00** | Integrante 3 | **Demonstração ao vivo** | Fluxo completo no navegador (`http://localhost:8080`): listar, buscar/filtrar, criar, editar, excluir, painel de resumo, `API Docs` e tratamento de erros (`422` e `409`). |
| **9:00 – 11:00** | Integrante 4 | **Front-end, extras e decisões** | Como `config.js` / `app.js` / `resumo.js` / `api.js` funcionam, extras implementados, decisões técnicas e abertura para perguntas. |

---

## 2. Roteiro Falado (Falas Prontas para Ensaio)

### 👤 Integrante 1: Visão Geral, Arquitetura e Banco (0:00 – 2:30)
*(Tom: Apresentador, claro e objetivo)*

> "Bom dia/boa tarde, professor(a) e colegas. Nós somos a **Equipe 1** e vamos apresentar nosso Projeto Final: o **Sistema de Gestão de Biblioteca**.
>
> O problema que resolvemos é a necessidade de um sistema leve e robusto para cadastrar livros e autores, controlar o estoque de exemplares, alertar visualmente sobre títulos esgotados e fornecer estatísticas rápidas do acervo.
>
> Nossa arquitetura segue um modelo de **3 camadas**:
> - No topo, o **Front-end**, feito com HTML, CSS e JavaScript puro, que se comunica via `fetch` e JSON.
> - No meio, a **API REST em C++17**, utilizando as bibliotecas `cpp-httplib` e `nlohmann/json`.
> - Na base, o **Banco de Dados MariaDB**, rodando em container Docker.
>
> Falando no banco de dados, nosso `schema.sql` garante a integridade dos dados. Temos a tabela `autores` com `nome` `UNIQUE`, e a tabela `livros` com regras rígidas: `autor_id` é uma chave estrangeira com `ON DELETE RESTRICT` (impedindo a exclusão de autores com livros), `isbn` é único, e usamos `CHECK` para garantir que o ano de publicação seja real (`1000` a `2100`) e que os exemplares nunca sejam negativos.
>
> Para facilitar a execução, utilizamos **Docker**. O comando `docker compose up -d --wait` sobe apenas o banco com dados de teste, enquanto o perfil `fullstack` compila e sobe a API C++ e o front-end na porta `8080` prontos para uso.
>
> Agora, o **[Nome do Integrante 2]** vai detalhar como o back-end foi construído."

### 👤 Integrante 2: Back-end C++17, Camadas e Rotas (2:30 – 5:30)
*(Tom: Técnico, destacando boas práticas de programação)*

> "Obrigado. Nosso back-end em C++17 foi desenhado com forte separação de responsabilidades.
>
> No `main.cpp`, carregamos as configurações, testamos a conexão e registramos as rotas. As requisições chegam nos arquivos `rotas_livros.cpp` e `rotas_autores.cpp`, que fazem o parse do JSON e delegam a validação para o `validacao.hpp`. Se tudo estiver certo, chamam os repositórios.
>
> Um ponto crucial do nosso projeto é o uso de **RAII** (Aquisição de Recursos é Inicialização). No arquivo `banco.cpp`, encapsulamos os ponteiros brutos da API C do MariaDB (`MYSQL*` e `MYSQL_STMT*`) dentro das classes `Conexao` e `Instrucao`. Isso garante que, mesmo que ocorra uma exceção, o destrutor será chamado e a conexão com o banco será fechada automaticamente, evitando *memory leaks*.
>
> Além disso, **100% das nossas consultas SQL usam parâmetros `?`** (*Prepared Statements*). Isso elimina totalmente o risco de SQL Injection, pois os dados do usuário nunca são concatenados na string da query.
>
> Sobre as rotas, cobrimos todo o ciclo CRUD para autores e livros, retornando os códigos HTTP corretos:
> - **200 e 201** para sucesso e criação.
> - **204** para exclusão concluída.
> - **400** para requisições malformadas ou IDs inválidos.
> - **404** quando um ID não é encontrado.
> - **409** para conflitos com mensagem clara ao usuário, como tentar deletar um autor que possui livros ou cadastrar um ISBN duplicado.
> - E **422** para erros de validação de campos, retornando um array detalhado do que está errado.
>
> Também implementamos rotas extras, como `/api/livros/resumo` para estatísticas e `/api/autores/:id/livros` para filtrar obras por autor.
>
> Agora, o **[Nome do Integrante 3]** fará a demonstração prática do sistema."

### 👤 Integrante 3: Demonstração ao Vivo (5:30 – 9:00)
*(Tom: Dinâmico, narrando as ações enquanto mexe no mouse. Pratique isso antes!)*

> "Vamos à demonstração ao vivo no `localhost:8080`.
>
> **Listagem e Filtros:** Na tela inicial, vemos a lista de livros. Notem que a tabela já faz o `JOIN` e exibe o nome do autor, não apenas o ID. Livros com zero exemplares, como este aqui, ficam destacados em vermelho. Vou usar a busca rápida digitando `'Machado'` e o filtro por autor para mostrar a reatividade da tela.
>
> **Validação (Erro 422):** Vou clicar em **`+ Novo livro`** para abrir o modal e tentar cadastrar um livro sem título e com o ano `'3000'`. Ao clicar em **Salvar**, o sistema bloqueia e exibe no topo do modal as mensagens de erro detalhadas *(dica: na aba **API Docs**, também dá para clicar no atalho **"Ano 3000 (422)"** para mostrar a resposta JSON direta da API)*.
>
> **Fluxo de Criação e Edição:** Vou na aba **Autores**, clico em **`+ Novo autor`** e cadastro `'Jorge Amado'`, nacionalidade `'Brasileira'`. Voltando aos livros, abro **`+ Novo livro`**, seleciono `'Jorge Amado'` no `select` e crio o livro `'Capitães da Areia'` com `0` exemplares. Vejam que ele já aparece destacado em vermelho na tabela. Agora, vou clicar em **Editar** e alterar o estoque para `4` exemplares. A linha perde o destaque vermelho imediatamente.
>
> **Regra de Negócio (Erro 409):** Se eu for em **Autores** e tentar excluir `'Jorge Amado'` agora, o sistema exibe um erro `409` explicando que não é possível excluir o autor porque ele ainda possui livros cadastrados. Isso porque o banco de dados está protegido pela regra `ON DELETE RESTRICT`.
>
> **Exclusão (204):** Para resolver, vou excluir primeiro o livro `'Capitães da Areia'`. O sistema pede confirmação e o remove. Agora, sim, consigo excluir o autor `'Jorge Amado'` com sucesso.
>
> **Painel de Resumo e API Docs:** Por fim, na aba **Resumo**, consumimos a rota `/api/livros/resumo` que exibe o total de títulos, exemplares, autores e gráficos de distribuição por gênero e autor — e na aba **API Docs**, temos uma documentação interativa onde qualquer pessoa pode testar todas as 14 rotas ao vivo.
>
> Agora, o **[Nome do Integrante 4]** vai falar sobre as decisões técnicas do front-end e encerrar."

### 👤 Integrante 4: Front-end, Decisões Técnicas e Encerramento (9:00 – 11:00)
*(Tom: Analítico, mostrando maturidade nas escolhas de design)*

> "Para finalizar, gostaria de destacar algumas decisões técnicas que elevaram a qualidade do projeto.
>
> No **Front-end**, optamos por JavaScript puro (*Vanilla JS*) para manter a leveza. Usamos arquivos `config.js` e `config-autores.js` para centralizar a geração de formulários e tabelas no `app.js`, evitando duplicação de código entre as páginas de livros e autores. No `resumo.js` e no `api.js`, manipulamos o DOM usando estritamente `textContent` em vez de `innerHTML`, o que é uma prática essencial de segurança para prevenir ataques de **XSS** (*Cross-Site Scripting*). Também criamos a tela **API Docs** (`api.html`) para facilitar testes ao vivo e aprendizado da API.
>
> Três decisões de **back-end** merecem destaque:
> 1. **Uso de `NULLIF(?, '')` no SQL:** Como o ISBN é opcional e `UNIQUE`, se salvássemos uma string vazia `""`, o segundo livro sem ISBN daria erro de duplicidade. O `NULLIF` converte strings vazias em `NULL`, e o banco permite múltiplos `NULL`s em colunas únicas.
> 2. **Validação prévia do `autor_id`:** Antes de tentar inserir o livro, verificamos se o autor existe. Se não existir, retornamos um `422` com a mensagem amigável `'autor_id nao existe'`, em vez de deixar o banco estourar um erro genérico `1452`.
> 3. **Ordem de registro das rotas:** No `cpp-httplib`, registramos a rota `/api/livros/resumo` **antes** da rota `/api/livros/:id`. Se fizéssemos o contrário, o framework interpretaria a palavra `'resumo'` como se fosse um ID de livro, gerando um erro `400`.
>
> Muito obrigado pela atenção, e ficamos à disposição para as perguntas da banca."

---

## 3. Resumo Técnico — Problema e Arquitetura (0:00 – 2:30)

### O que o sistema resolve
Sistema para uma biblioteca cadastrar **livros** e **autores**, controlar a quantidade de **exemplares**, destacar títulos esgotados (`exemplares = 0`), filtrar rapidamente o acervo e visualizar estatísticas em um painel de resumo.

### Arquitetura em 3 camadas
```
Navegador (HTML + CSS + JS puro)
        │  fetch() com JSON
        ▼
API REST em C++17 (cpp-httplib + nlohmann/json)
        │  Prepared statements (?) via libmariadb
        ▼
Banco de dados MariaDB (Docker)
```

### Banco de dados (`schema.sql`)
- **`autores`** *(entidade de apoio)*: `id` (PK), `nome` (`VARCHAR(100) NOT NULL`, `UNIQUE`), `nacionalidade` (`VARCHAR(50) NULL`), `criado_em`.
- **`livros`** *(entidade principal)*: `id` (PK), `titulo` (`VARCHAR(150) NOT NULL`), `autor_id` (FK obrigatória → `autores.id` com `ON DELETE RESTRICT`), `genero` (`VARCHAR(50) NULL`), `ano_publicacao` (`SMALLINT NULL`, `CHECK BETWEEN 1000 AND 2100`), `isbn` (`VARCHAR(20) NULL`, `UNIQUE`), `exemplares` (`INT NOT NULL DEFAULT 1`, `CHECK >= 0`), `criado_em`.
- **Execução via Docker (`docker-compose.yml` + `Dockerfile`):**
  - `docker compose up -d --wait`: sobe apenas o MariaDB (`db`) executando o `schema.sql` do zero com 5 autores e 10 livros de exemplo.
  - `docker compose --profile fullstack up -d --build --wait`: sobe o MariaDB **e** a API C++ compilada em container na porta `8080`.

---

## 4. Slide 2 — Back-end em C++17 e Rotas da API (2:30 – 5:30)

### Separação de responsabilidades (`src/`)
- **`main.cpp`:** carrega configurações de ambiente (`Config::doAmbiente()`), testa o banco, serve `./public` em `/`, registra rotas e define handlers globais de erro (`500` para exceções e `404` JSON para rotas `/api/*` inexistentes).
- **`rotas_autores.cpp` e `rotas_livros.cpp`:** recebem as requisições HTTP, leem e validam JSON e IDs e delegam a persistência aos repositórios.
- **`validacao.hpp`:** valida todos os campos de uma vez e retorna lista detalhada em `422`.
- **`autor_repositorio.cpp` e `livro_repositorio.cpp`:** concentram **100% do SQL**, sempre com parâmetros `?` e `NULLIF(?, '')` nos campos opcionais.
- **`banco.hpp` / `banco.cpp`:** encapsula a API C do MariaDB com **RAII** (`Conexao` fecha a conexão no destrutor; `Instrucao` fecha o `MYSQL_STMT` no destrutor).
- **`http_util.hpp`:** padroniza respostas JSON e converte `ErroBanco` (`1062` → `409`, `1451`/`1452` → `409`, `4025`/`3819` → `422`).

### Mapa completo de rotas

| Recurso | Método | Caminho | O que faz | Status |
|---|---|---|---|---|
| **Saúde** | `GET` | `/api/saude` | Verifica se o servidor HTTP está no ar | `200` |
| **Saúde** | `GET` | `/api/saude/banco` | Executa `SELECT 1` no MariaDB | `200` · `500` |
| **Autores** | `GET` | `/api/autores` | Lista autores em ordem alfabética (aceita `?busca=`), com `total_livros` e `total_exemplares` | `200` |
| **Autores** | `GET` | `/api/autores/:id` | Busca um autor por ID | `200` · `400` · `404` |
| **Autores** | `GET` | `/api/autores/:id/livros` | Lista todos os livros de um autor específico *(extra)* | `200` · `400` · `404` |
| **Autores** | `POST` | `/api/autores` | Cadastra novo autor (`nome` único e obrigatório) | `201` · `400` · `409` · `422` |
| **Autores** | `PUT` | `/api/autores/:id` | Atualiza dados do autor | `200` · `400` · `404` · `409` · `422` |
| **Autores** | `DELETE` | `/api/autores/:id` | Remove autor (bloqueia com `409` se tiver livros) | `204` · `400` · `404` · `409` |
| **Livros** | `GET` | `/api/livros` | Lista livros com `autor_nome` (`JOIN`), aceitando `?busca=`, `?genero=` e `?autor_id=` | `200` · `422` |
| **Livros** | `GET` | `/api/livros/resumo` | Totais do acervo, esgotados e agrupamento por gênero e autor *(extra)* | `200` |
| **Livros** | `GET` | `/api/livros/:id` | Busca um livro por ID | `200` · `400` · `404` |
| **Livros** | `POST` | `/api/livros` | Cadastra livro (valida campos, checa `autor_id` → `422` e ISBN único → `409`) | `201` · `400` · `409` · `422` |
| **Livros** | `PUT` | `/api/livros/:id` | Atualiza livro existente | `200` · `400` · `404` · `409` · `422` |
| **Livros** | `DELETE` | `/api/livros/:id` | Remove livro do acervo | `204` · `400` · `404` |

---

## 5. Slide 3 — Caminho de uma requisição `POST /api/livros` (ponta a ponta)

1. **Tela (`public/app.js` + `public/config.js`):** o usuário preenche o formulário e clica em **Salvar**. `lerFormulario()` monta o objeto JSON e `api("POST", "/api/livros", dados)` envia via `fetch()`.
2. **Rota (`src/rotas_livros.cpp`):**
   - `util::lerCorpoObjeto()` faz o *parse* do corpo (JSON inválido → `400`).
   - `validarLivro()` valida `titulo`, `autor_id`, `genero`, `ano_publicacao`, `isbn` e `exemplares` (erros acumulados → `422`).
   - `util::comBanco()` abre a `Conexao` (RAII) e `autorExiste()` verifica se o `autor_id` existe antes de gravar (se não existir → `422` com `"autor_id nao existe"`).
3. **Repositório (`src/livro_repositorio.cpp`):** `LivroRepositorio::criar()` executa `INSERT INTO livros ... VALUES (?, ?, NULLIF(?, ''), ...)` usando `parametros.hpp` e devolve o registro completo via `buscar(ultimoId())`.
4. **Banco (`src/banco.cpp`):** `Instrucao` prepara o `MYSQL_STMT`, vincula os parâmetros `?` via `MYSQL_BIND` e executa no MariaDB. Se o ISBN for repetido (`1062`), `ErroBanco` é convertido em `409` por `util::comBanco`. Caso contrário, a API retorna `201` com o JSON do livro criado (incluindo `autor_nome`), e o front-end atualiza a tabela.

---

## 6. Slide 4 — Roteiro da Demonstração ao Vivo (5:30 – 9:00)

Acesse **<http://localhost:8080>** e execute nesta ordem:

1. **Listagem e filtros (`index.html`):**
   - Mostrar a tabela trazendo o **nome do autor** (não só o ID).
   - Destacar as linhas em vermelho (*0 exemplares*).
   - Testar a busca (`Machado`) e o filtro por autor no `<select>`.
2. **Erro de validação (`422`):**
   - Tentar cadastrar um livro sem título (ou com ano `3000` / via `curl`) e mostrar a mensagem de erro detalhada exibida no topo da tela.
3. **Criar e Editar (`201` e `200`):**
   - Ir em **Autores** (`autores.html`) e criar um autor novo (ex.: *Jorge Amado*, *Brasileira*).
   - Voltar em **Livros**, selecionar *Jorge Amado* no `<select>`, criar *Capitães da Areia* com `0` exemplares (mostrando o destaque na tabela) e depois clicar em **Editar** para alterar para `4` exemplares.
4. **Regra de chave estrangeira (`409`):**
   - Ir em **Autores** e tentar excluir *Jorge Amado* enquanto ele ainda tem livro cadastrado → mostrar o aviso de erro `409` na tela.
5. **Exclusão (`204`):**
   - Excluir o livro *Capitães da Areia* (com confirmação) e depois excluir o autor *Jorge Amado*.
6. **Painel de Resumo (`resumo.html`):**
   - Mostrar os indicadores gerais (títulos, exemplares, autores, esgotados) e as barras por gênero e por autor.

---

## 7. Slide 5 — Front-end, Decisões Técnicas e Extras (9:00 – 11:00)

### Front-end (`public/`)
- `app.js` lê `CONFIG` de `config.js` (Livros) e `config-autores.js` (Autores) para gerar formulário em modal (`+ Novo livro` / `+ Novo autor`), validações básicas, busca, filtros e tabela sem duplicar código.
- `resumo.js` consome `GET /api/livros/resumo` e preenche o painel com `textContent` (prevenindo XSS).
- `api.html` + `api.js` oferecem documentação interativa dentro do próprio site para copiar `curl` e testar todas as 14 rotas ao vivo.
- `estilo.css` garante leitura responsiva em telas estreitas, favicon (`favicon.svg`) e destaque visual (`linha-alerta`) para livros com `exemplares = 0`.

### Principais decisões e aprendizados
- **`NULLIF(?, '')` para opcionais:** evita que livros sem ISBN sejam gravados como string vazia `""`, permitindo múltiplos livros sem ISBN sem violar o índice `UNIQUE`.
- **Checagem prévia de `autor_id`:** responde `422` com mensagem amigável (`"autor_id nao existe"`) em vez de deixar estourar erro genérico `1452` (`409`).
- **Ordem das rotas no `cpp-httplib`:** `/api/livros/resumo` registrada **antes** de `/api/livros/:id` para `"resumo"` não ser interpretado como `:id` (`400`).
- **Docker com perfil `fullstack`:** mantém `docker compose up -d --wait` subindo só o banco (padrão da avaliação) e permite subir banco + API + front com `--profile fullstack`.

---

## 8. Guia rápido para perguntas da banca (`rubrica.md`)

<details>
<summary><strong>Clique para ver respostas prontas para as perguntas típicas do professor</strong></summary>

1. **"O que acontece se enviar JSON inválido, título vazio ou ID inexistente?"**
   - JSON inválido → `400` em `util::lerCorpoObjeto`.
   - Título vazio/só espaços → `422` com array `"detalhes"` em `validacao::textoObrigatorio`.
   - ID não numérico (`/api/livros/abc`) → `400` em `util::lerId`; ID numérico inexistente (`/api/livros/9999`) → `404`.
2. **"Por que o SQL usa `?` em vez de concatenar texto?"**
   - Para prevenir **SQL Injection**: *prepared statements* separam a instrução SQL dos parâmetros enviados pelo usuário, e `parametros::escaparLike` escapa `%`, `_` e `\` nas buscas.
3. **"Onde a conexão com o banco é aberta e fechada? O que garante que fecha?"**
   - Na classe `Conexao` (`src/banco.hpp/.cpp`) via **RAII**: abre no construtor (`mysql_real_connect`) e fecha no destrutor de `Conexao::Impl` (`mysql_close`), garantindo fechamento automático mesmo quando ocorre exceção (`ErroBanco`).
4. **"O que acontece ao apagar um autor que tem livros?"**
   - A chave estrangeira `fk_livros_autor` usa `ON DELETE RESTRICT`. O MariaDB bloqueia com erro `1451` e `util::comBanco` devolve HTTP `409`.
5. **"Mostre no código conceitos das Unidades 3, 4 e 5:"**
   - **Unidade 3 (funções, referências e ponteiros):** passagem por `const &` nas rotas/repositórios e encapsulamento de ponteiros C (`MYSQL*`, `MYSQL_STMT*`) em `banco.cpp`.
   - **Unidade 4 (POO e RAII):** `Conexao` e `Instrucao` com destrutores RAII e cópia desabilitada (`= delete`), `ErroBanco` herdando de `std::runtime_error`, e classes de repositório.
   - **Unidade 5 (STL e C++ moderno):** `std::unique_ptr`, `std::vector`, `std::string` e funções *lambda* no registro de rotas e em `util::comBanco`.

</details>
