"use strict";
/*
 * config-autores.js - Configuração da tela de AUTORES (entidade de apoio da Biblioteca).
 */

const CONFIG = {
  titulo: "Biblioteca — Autores",
  recurso: "autores",
  campos: [
    { nome: "nome", rotulo: "Nome", tipo: "texto", obrigatorio: true, max: 100 },
    { nome: "nacionalidade", rotulo: "Nacionalidade", tipo: "texto", max: 50 },
    { nome: "total_livros", rotulo: "Livros", tipo: "somenteLeitura" },
    { nome: "total_exemplares", rotulo: "Exemplares", tipo: "somenteLeitura" },
  ],
  menu: [
    { texto: "Livros", href: "index.html" },
    { texto: "Autores", href: "autores.html" },
    { texto: "Resumo", href: "resumo.html" },
  ],
};
