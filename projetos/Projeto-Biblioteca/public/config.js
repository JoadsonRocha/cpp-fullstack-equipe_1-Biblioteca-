"use strict";
/*
 * config.js - Configuração da tela principal de LIVROS (entidade principal da Biblioteca).
 */

const CONFIG = {
  titulo: "Biblioteca — Livros",
  recurso: "livros",
  campos: [
    { nome: "titulo", rotulo: "Título", tipo: "texto", obrigatorio: true, max: 150, largo: true },
    {
      nome: "autor_id",
      rotulo: "Autor",
      tipo: "select",
      obrigatorio: true,
      opcoesDe: { recurso: "autores", valor: "id", rotulo: "nome" },
    },
    { nome: "genero", rotulo: "Gênero", tipo: "texto", max: 50 },
    {
      nome: "ano_publicacao",
      rotulo: "Ano de publicação",
      rotuloTabela: "Ano",
      tipo: "numero",
      min: 1000,
      max: 2100,
    },
    { nome: "isbn", rotulo: "ISBN", tipo: "texto", max: 20 },
    { nome: "exemplares", rotulo: "Exemplares", tipo: "numero", min: 0, padrao: 1 },
  ],
  filtros: [
    {
      nome: "autor_id",
      rotulo: "Autor",
      opcoesDe: { recurso: "autores", valor: "id", rotulo: "nome" },
    },
  ],
  // Destaca na tabela os livros sem exemplares disponíveis.
  classeLinha: (livro) => (livro.exemplares === 0 ? "linha-alerta" : null),
  menu: [
    { texto: "Livros", href: "index.html" },
    { texto: "Autores", href: "autores.html" },
    { texto: "Resumo", href: "resumo.html" },
  ],
};
