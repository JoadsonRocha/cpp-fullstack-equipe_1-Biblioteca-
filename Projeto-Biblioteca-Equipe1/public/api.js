"use strict";
/*
 * api.js - Renderiza a documentação interativa das 14 rotas da API Biblioteca,
 * gera comandos curl dinâmicos e permite testar cada endpoint ao vivo com fetch().
 */

const urlBaseEl = document.getElementById("url-base");
const listaEl = document.getElementById("lista-endpoints");
const filtrosEl = document.getElementById("filtros-api");

const BASE_URL = window.location.origin;
urlBaseEl.textContent = BASE_URL;

// Catálogo completo das rotas implementadas em main.cpp, rotas_autores.cpp e rotas_livros.cpp.
const ENDPOINTS = [
  {
    grupo: "saude",
    metodo: "GET",
    caminho: "/api/saude",
    titulo: "Verificar se o servidor HTTP está no ar",
    descricao: "Retorna imediatamente {\"status\":\"ok\"} sem consultar o banco de dados.",
    status: ["200"],
  },
  {
    grupo: "saude",
    metodo: "GET",
    caminho: "/api/saude/banco",
    titulo: "Testar conexão com o MariaDB",
    descricao: "Executa SELECT 1 no MariaDB usando a classe Conexao (RAII) para validar as credenciais e o container.",
    status: ["200", "500"],
  },
  {
    grupo: "autores",
    metodo: "GET",
    caminho: "/api/autores",
    titulo: "Listar autores",
    descricao: "Lista os autores em ordem alfabética, trazendo total_livros e total_exemplares calculados via LEFT JOIN.",
    status: ["200"],
    queryParams: [
      { nome: "busca", placeholder: "Ex.: Machado ou Brasileira", padrao: "" },
    ],
  },
  {
    grupo: "autores",
    metodo: "GET",
    caminho: "/api/autores/:id",
    titulo: "Buscar um autor por ID",
    descricao: "Retorna os dados de um único autor. Teste \"abc\" para ver 400 ou \"9999\" para ver 404.",
    status: ["200", "400", "404"],
    pathId: "1",
  },
  {
    grupo: "autores",
    metodo: "GET",
    caminho: "/api/autores/:id/livros",
    titulo: "Listar todos os livros de um autor",
    descricao: "Rota extra do tema: confirma que o autor existe (404 se não existir) e lista seus livros ordenados por título.",
    status: ["200", "400", "404"],
    pathId: "1",
  },
  {
    grupo: "autores",
    metodo: "POST",
    caminho: "/api/autores",
    titulo: "Cadastrar novo autor",
    descricao: "Cria um autor. \"nome\" é obrigatório (até 100 caracteres) e único (nome repetido retorna 409).",
    status: ["201", "400", "409", "422"],
    corpoPadrao: '{\n  "nome": "Jorge Amado",\n  "nacionalidade": "Brasileira"\n}',
    atalhos: [
      { rotulo: "Válido (201)", corpo: '{\n  "nome": "Cecília Meireles",\n  "nacionalidade": "Brasileira"\n}' },
      { rotulo: "Nome vazio (422)", corpo: '{\n  "nome": ""\n}' },
      { rotulo: "Nome repetido (409)", corpo: '{\n  "nome": "Machado de Assis"\n}' },
    ],
  },
  {
    grupo: "autores",
    metodo: "PUT",
    caminho: "/api/autores/:id",
    titulo: "Atualizar autor existente",
    descricao: "Substitui nome e nacionalidade do autor informado.",
    status: ["200", "400", "404", "409", "422"],
    pathId: "1",
    corpoPadrao: '{\n  "nome": "Machado de Assis",\n  "nacionalidade": "Brasileira"\n}',
  },
  {
    grupo: "autores",
    metodo: "DELETE",
    caminho: "/api/autores/:id",
    titulo: "Excluir autor",
    descricao: "Remove o autor pelo ID. Se o autor ainda possuir livros vinculados, a FK bloqueia e a API responde 409 com explicação.",
    status: ["204", "400", "404", "409"],
    pathId: "1",
  },
  {
    grupo: "livros",
    metodo: "GET",
    caminho: "/api/livros",
    titulo: "Listar e filtrar livros",
    descricao: "Retorna livros com autor_nome (JOIN). Aceita busca livre e filtros combinados por gênero e autor_id.",
    status: ["200", "422"],
    queryParams: [
      { nome: "busca", placeholder: "Título, gênero, autor ou ISBN", padrao: "" },
      { nome: "genero", placeholder: "Ex.: Romance", padrao: "" },
      { nome: "autor_id", placeholder: "Ex.: 1", padrao: "" },
    ],
  },
  {
    grupo: "livros",
    metodo: "GET",
    caminho: "/api/livros/resumo",
    titulo: "Resumo estatístico do acervo",
    descricao: "Calcula totais de títulos, exemplares, autores, livros sem exemplares (esgotados) e agrupamentos por gênero e autor.",
    status: ["200"],
  },
  {
    grupo: "livros",
    metodo: "GET",
    caminho: "/api/livros/:id",
    titulo: "Buscar um livro por ID",
    descricao: "Retorna um livro específico. Teste \"9999\" (404) ou \"abc\" (400) para validar os códigos de erro.",
    status: ["200", "400", "404"],
    pathId: "1",
  },
  {
    grupo: "livros",
    metodo: "POST",
    caminho: "/api/livros",
    titulo: "Cadastrar novo livro",
    descricao: "Valida todos os campos, verifica se autor_id existe (422) e usa NULLIF para permitir múltiplos livros sem ISBN.",
    status: ["201", "400", "409", "422"],
    corpoPadrao:
      '{\n  "titulo": "Vidas Secas",\n  "autor_id": 1,\n  "genero": "Romance",\n  "ano_publicacao": 1938,\n  "isbn": "",\n  "exemplares": 2\n}',
    atalhos: [
      {
        rotulo: "Sem título (422)",
        corpo: '{\n  "titulo": "",\n  "autor_id": 1\n}',
      },
      {
        rotulo: "Ano 3000 (422)",
        corpo: '{\n  "titulo": "Teste Ano",\n  "autor_id": 1,\n  "ano_publicacao": 3000\n}',
      },
      {
        rotulo: "Autor inexistente (422)",
        corpo: '{\n  "titulo": "Teste Autor",\n  "autor_id": 9999\n}',
      },
      {
        rotulo: "ISBN repetido (409)",
        corpo: '{\n  "titulo": "Livro Repetido",\n  "autor_id": 1,\n  "isbn": "9788535910663"\n}',
      },
      {
        rotulo: "Sem ISBN (201)",
        corpo: '{\n  "titulo": "Edição Especial Sem ISBN",\n  "autor_id": 1,\n  "exemplares": 1\n}',
      },
    ],
  },
  {
    grupo: "livros",
    metodo: "PUT",
    caminho: "/api/livros/:id",
    titulo: "Atualizar livro existente",
    descricao: "Substitui todos os campos do livro informado após validar campos, autor_id e unicidade do ISBN.",
    status: ["200", "400", "404", "409", "422"],
    pathId: "1",
    corpoPadrao:
      '{\n  "titulo": "Dom Casmurro",\n  "autor_id": 1,\n  "genero": "Romance",\n  "ano_publicacao": 1899,\n  "isbn": "9788535910663",\n  "exemplares": 3\n}',
  },
  {
    grupo: "livros",
    metodo: "DELETE",
    caminho: "/api/livros/:id",
    titulo: "Excluir livro",
    descricao: "Remove o livro pelo ID (204 sem corpo) ou retorna 404 caso o ID não exista.",
    status: ["204", "400", "404"],
    pathId: "9999",
  },
];

function classeMetodo(metodo) {
  return "metodo-badge metodo-" + metodo.toLowerCase();
}

// Monta o caminho relativo final substituindo :id e anexando os filtros da query string.
function montarUrl(ep, inputId, inputsQuery) {
  let url = ep.caminho;
  if (inputId) {
    const idVal = inputId.value.trim() || "1";
    url = url.replace(":id", encodeURIComponent(idVal));
  }
  if (inputsQuery.length > 0) {
    const params = new URLSearchParams();
    for (const q of inputsQuery) {
      const val = q.input.value.trim();
      if (val !== "") params.set(q.nome, val);
    }
    const qs = params.toString();
    if (qs) url += "?" + qs;
  }
  return url;
}

// Gera comando curl copiável (escapando aspas simples de forma segura para bash).
function gerarCurl(ep, url, textareaCorpo) {
  const destino = BASE_URL + url;
  if (ep.metodo === "GET") {
    return `curl "${destino}"`;
  }
  if (ep.metodo === "DELETE") {
    return `curl -X DELETE "${destino}"`;
  }
  const compacto = textareaCorpo ? textareaCorpo.value.replace(/\s+/g, " ").trim() : "{}";
  const seguro = compacto.replace(/'/g, "'\\''");
  return `curl -X ${ep.metodo} "${destino}" \\\n  -H "Content-Type: application/json" \\\n  -d '${seguro}'`;
}

function criarCartaoEndpoint(ep) {
  const card = document.createElement("article");
  card.className = "endpoint";
  card.dataset.grupo = ep.grupo;

  // Cabeçalho do cartão: método + caminho + badges de status
  const topo = document.createElement("div");
  topo.className = "endpoint-topo";

  const rotaLinha = document.createElement("div");
  rotaLinha.className = "endpoint-rota";

  const badgeMetodo = document.createElement("span");
  badgeMetodo.className = classeMetodo(ep.metodo);
  badgeMetodo.textContent = ep.metodo;

  const caminho = document.createElement("code");
  caminho.className = "endpoint-caminho";
  caminho.textContent = ep.caminho;

  const titulo = document.createElement("strong");
  titulo.className = "endpoint-titulo";
  titulo.textContent = ep.titulo;

  rotaLinha.append(badgeMetodo, caminho, titulo);

  const listaStatus = document.createElement("div");
  listaStatus.className = "endpoint-status";
  for (const st of ep.status) {
    const pill = document.createElement("span");
    pill.className = "status-pill " + (st.startsWith("2") ? "ok" : "erro");
    pill.textContent = st;
    listaStatus.appendChild(pill);
  }

  topo.append(rotaLinha, listaStatus);

  const desc = document.createElement("p");
  desc.className = "endpoint-desc";
  desc.textContent = ep.descricao;

  card.append(topo, desc);

  // Controles de parâmetros (:id e query string)
  let inputId = null;
  const inputsQuery = [];

  if (ep.pathId !== undefined || (ep.queryParams && ep.queryParams.length > 0)) {
    const grade = document.createElement("div");
    grade.className = "endpoint-params";

    if (ep.pathId !== undefined) {
      const grp = document.createElement("div");
      grp.className = "campo";
      const lbl = document.createElement("label");
      lbl.textContent = "Parâmetro :id";
      inputId = document.createElement("input");
      inputId.type = "text";
      inputId.value = ep.pathId;
      inputId.placeholder = "Ex.: 1 ou abc";
      grp.append(lbl, inputId);
      grade.appendChild(grp);
    }

    for (const q of ep.queryParams || []) {
      const grp = document.createElement("div");
      grp.className = "campo";
      const lbl = document.createElement("label");
      lbl.textContent = "Filtro ?" + q.nome + "=";
      const inp = document.createElement("input");
      inp.type = "text";
      inp.value = q.padrao || "";
      inp.placeholder = q.placeholder || "";
      grp.append(lbl, inp);
      grade.appendChild(grp);
      inputsQuery.push({ nome: q.nome, input: inp });
    }

    card.appendChild(grade);
  }

  // Editor de JSON para POST / PUT + atalhos de teste rápido
  let textareaCorpo = null;
  if (ep.corpoPadrao !== undefined) {
    if (ep.atalhos && ep.atalhos.length > 0) {
      const barraAtalhos = document.createElement("div");
      barraAtalhos.className = "atalhos-json";
      const legenda = document.createElement("span");
      legenda.textContent = "Exemplos prontos:";
      barraAtalhos.appendChild(legenda);

      for (const atalho of ep.atalhos) {
        const btnAtalho = document.createElement("button");
        btnAtalho.type = "button";
        btnAtalho.className = "secundario btn-atalho";
        btnAtalho.textContent = atalho.rotulo;
        btnAtalho.addEventListener("click", () => {
          textareaCorpo.value = atalho.corpo;
          atualizarCurl();
        });
        barraAtalhos.appendChild(btnAtalho);
      }
      card.appendChild(barraAtalhos);
    }

    const grpJson = document.createElement("div");
    grpJson.className = "campo";
    const lblJson = document.createElement("label");
    lblJson.textContent = "Corpo JSON da requisição";
    textareaCorpo = document.createElement("textarea");
    textareaCorpo.className = "json-editor";
    textareaCorpo.value = ep.corpoPadrao;
    textareaCorpo.spellcheck = false;
    grpJson.append(lblJson, textareaCorpo);
    card.appendChild(grpJson);
  }

  // Bloco curl + botões de ação
  const preCurl = document.createElement("pre");
  preCurl.className = "codigo-bloco";

  function atualizarCurl() {
    const url = montarUrl(ep, inputId, inputsQuery);
    preCurl.textContent = gerarCurl(ep, url, textareaCorpo);
  }

  if (inputId) inputId.addEventListener("input", atualizarCurl);
  for (const q of inputsQuery) q.input.addEventListener("input", atualizarCurl);
  if (textareaCorpo) textareaCorpo.addEventListener("input", atualizarCurl);
  atualizarCurl();

  const acoes = document.createElement("div");
  acoes.className = "endpoint-acoes";

  const btnTestar = document.createElement("button");
  btnTestar.type = "button";
  btnTestar.textContent = "Testar agora";

  const btnCopiar = document.createElement("button");
  btnCopiar.type = "button";
  btnCopiar.className = "secundario";
  btnCopiar.textContent = "Copiar curl";

  acoes.append(btnTestar, btnCopiar);

  const caixaResposta = document.createElement("div");
  caixaResposta.className = "resposta-box";
  caixaResposta.hidden = true;

  const cabResposta = document.createElement("div");
  cabResposta.className = "resposta-cab";
  const badgeResp = document.createElement("span");
  badgeResp.className = "badge-status";
  const urlResp = document.createElement("code");
  cabResposta.append(badgeResp, urlResp);

  const preResp = document.createElement("pre");
  preResp.className = "codigo-bloco resposta-json";
  caixaResposta.append(cabResposta, preResp);

  btnCopiar.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(preCurl.textContent);
      btnCopiar.textContent = "Copiado!";
      setTimeout(() => (btnCopiar.textContent = "Copiar curl"), 1800);
    } catch {
      btnCopiar.textContent = "Selecione acima";
      setTimeout(() => (btnCopiar.textContent = "Copiar curl"), 1800);
    }
  });

  btnTestar.addEventListener("click", async () => {
    const url = montarUrl(ep, inputId, inputsQuery);
    const opcoes = { method: ep.metodo, headers: {} };
    if (textareaCorpo) {
      opcoes.headers["Content-Type"] = "application/json";
      opcoes.body = textareaCorpo.value;
    }

    btnTestar.disabled = true;
    btnTestar.textContent = "Enviando...";
    try {
      const resp = await fetch(url, opcoes);
      const texto = await resp.text();
      let exibicao = texto;
      if (resp.status === 204 || texto === "") {
        exibicao = "(204 No Content — sem corpo)";
      } else {
        try {
          exibicao = JSON.stringify(JSON.parse(texto), null, 2);
        } catch {
          /* mantém texto bruto caso não seja JSON */
        }
      }
      badgeResp.textContent = resp.status + " " + (resp.statusText || "");
      badgeResp.className = "badge-status " + (resp.ok ? "status-ok" : "status-erro");
      urlResp.textContent = ep.metodo + " " + url;
      preResp.textContent = exibicao; // textContent previne XSS
      caixaResposta.hidden = false;
    } catch (erro) {
      badgeResp.textContent = "Erro de rede";
      badgeResp.className = "badge-status status-erro";
      urlResp.textContent = ep.metodo + " " + url;
      preResp.textContent = erro.message;
      caixaResposta.hidden = false;
    } finally {
      btnTestar.disabled = false;
      btnTestar.textContent = "Testar agora";
    }
  });

  card.append(preCurl, acoes, caixaResposta);
  return card;
}

function renderizarEndpoints() {
  listaEl.textContent = "";
  for (const ep of ENDPOINTS) {
    listaEl.appendChild(criarCartaoEndpoint(ep));
  }
}

filtrosEl.addEventListener("click", (evento) => {
  const btn = evento.target.closest("button[data-grupo]");
  if (!btn) return;
  const grupo = btn.dataset.grupo;
  for (const b of filtrosEl.querySelectorAll(".filtro-api-btn")) {
    b.classList.toggle("ativo", b === btn);
  }
  for (const card of listaEl.querySelectorAll(".endpoint")) {
    card.hidden = grupo !== "todos" && card.dataset.grupo !== grupo;
  }
});

renderizarEndpoints();
