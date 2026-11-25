// rotas_livros.hpp - Rotas HTTP do recurso "livros" (entidade principal).
//
//   GET    /api/livros          lista (aceita ?busca=, ?genero=, ?autor_id=)
//   GET    /api/livros/resumo   estatísticas gerais do acervo
//   GET    /api/livros/:id      busca um livro
//   POST   /api/livros          cria um livro
//   PUT    /api/livros/:id      atualiza um livro
//   DELETE /api/livros/:id      remove um livro
#pragma once

#include <httplib.h>

#include "config.hpp"

void registrarRotasLivros(httplib::Server& servidor, const Config& config);
