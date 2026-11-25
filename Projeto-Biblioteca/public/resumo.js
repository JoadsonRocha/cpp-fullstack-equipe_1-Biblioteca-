"use strict";
/*
 * resumo.js - Consome GET /api/livros/resumo e renderiza indicadores e barras do acervo.
 * Usa textContent na criação dos elementos para evitar injeção de HTML (XSS).
 */

const elementos = {
  aviso: document.getElementById("aviso"),
  indicadores: document.getElementById("indicadores"),
  generos: document.getElementById("generos"),
  autores: document.getElementById("autores"),
};

function mostrarErro(texto) {
  elementos.aviso.textContent = texto;
  elementos.aviso.className = "aviso erro";
  elementos.aviso.hidden = false;
}

// Monta um cartão numérico do painel superior (ex.: "10" / "Títulos cadastrados").
function criarIndicador(valor, rotulo, classeExtra) {
  const caixa = document.createElement("div");
  caixa.className = "indicador" + (classeExtra ? " " + classeExtra : "");
  const numero = document.createElement("span");
  numero.className = "valor";
  numero.textContent = valor;
  const legenda = document.createElement("span");
  legenda.className = "rotulo";
  legenda.textContent = rotulo;
  caixa.append(numero, legenda);
  return caixa;
}

function desenharIndicadores(resumo) {
  elementos.indicadores.append(
    criarIndicador(resumo.total_livros, "Títulos cadastrados"),
    criarIndicador(resumo.total_exemplares, "Total de exemplares"),
    criarIndicador(resumo.total_autores, "Autores"),
    // Destaca o cartão em alerta quando houver livros com 0 exemplares.
    criarIndicador(
      resumo.esgotados,
      "Sem exemplares",
      Number(resumo.esgotados) > 0 ? "alerta" : ""
    )
  );
}

// Renderiza lista com barras proporcionais ao total de títulos (reutilizada para gênero e autor).
function desenharBarras(container, lista, campoNome, totalBase, mensagemVazio) {
  if (!Array.isArray(lista) || lista.length === 0) {
    container.textContent = mensagemVazio;
    return;
  }

  for (const item of lista) {
    const livros = Number(item.total_livros) || 0;
    const exemplares = Number(item.total_exemplares) || 0;
    const percentual = totalBase === 0 ? 0 : Math.round((livros / totalBase) * 100);

    const linha = document.createElement("div");
    linha.className = "grupo-resumo";

    const titulo = document.createElement("div");
    titulo.className = "grupo-titulo";
    const nome = document.createElement("strong");
    nome.textContent = item[campoNome];
    const contagem = document.createElement("span");
    contagem.textContent =
      livros +
      (livros === 1 ? " título" : " títulos") +
      " · " +
      exemplares +
      (exemplares === 1 ? " exemplar" : " exemplares") +
      " (" +
      percentual +
      "%)";
    titulo.append(nome, contagem);

    const trilho = document.createElement("div");
    trilho.className = "progresso";
    trilho.setAttribute("role", "progressbar");
    trilho.setAttribute("aria-valuemin", "0");
    trilho.setAttribute("aria-valuemax", "100");
    trilho.setAttribute("aria-valuenow", String(percentual));
    const preenchido = document.createElement("div");
    preenchido.className = "progresso-preenchido";
    preenchido.style.width = percentual + "%";
    trilho.appendChild(preenchido);

    linha.append(titulo, trilho);
    container.appendChild(linha);
  }
}

async function iniciar() {
  try {
    const resposta = await fetch("/api/livros/resumo");
    const resumo = await resposta.json();
    if (!resposta.ok) {
      throw new Error(resumo.erro || "Erro " + resposta.status);
    }
    desenharIndicadores(resumo);
    const totalLivros = Number(resumo.total_livros) || 0;
    desenharBarras(elementos.generos, resumo.por_genero, "genero", totalLivros, "Nenhum livro cadastrado.");
    desenharBarras(elementos.autores, resumo.por_autor, "autor", totalLivros, "Nenhum autor cadastrado.");
  } catch (erro) {
    mostrarErro("Não foi possível carregar o resumo: " + erro.message);
  }
}

iniciar();
