"use strict";
/*
 * config-autores.js - Configuração da tela de AUTORES (entidade de apoio da Biblioteca).
 * Reutiliza o mesmo motor CRUD de app.js apontando para o recurso /api/autores.
 */

const CONFIG = {
  titulo: "Biblioteca — Autores",
  recurso: "autores", // base das rotas REST: /api/autores
  campos: [
    { nome: "nome", rotulo: "Nome", tipo: "texto", obrigatorio: true, max: 100 },
    { nome: "nacionalidade", rotulo: "Nacionalidade", tipo: "texto", max: 50 },
    // Colunas calculadas no SQL (LEFT JOIN) exibidas só na tabela, não no formulário.
    { nome: "total_livros", rotulo: "Livros", tipo: "somenteLeitura" },
    { nome: "total_exemplares", rotulo: "Exemplares", tipo: "somenteLeitura" },
  ],
  menu: [
    { texto: "Livros", href: "index.html" },
    { texto: "Autores", href: "autores.html" },
    { texto: "Resumo", href: "resumo.html" },
    { texto: "API Docs", href: "api.html" },
  ],
};
