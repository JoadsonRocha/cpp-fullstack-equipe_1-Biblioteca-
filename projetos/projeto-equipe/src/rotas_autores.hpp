// rotas_autores.hpp - Rotas HTTP do recurso "autores" (entidade de apoio).
//
//   GET    /api/autores              lista autores (aceita ?busca=)
//   GET    /api/autores/:id          busca um autor
//   GET    /api/autores/:id/livros   lista os livros do autor
//   POST   /api/autores              cria um autor (nome repetido -> 409)
//   PUT    /api/autores/:id          atualiza um autor (nome repetido -> 409)
//   DELETE /api/autores/:id          remove um autor (autor com livros -> 409)
#pragma once

#include <httplib.h>

#include "config.hpp"

void registrarRotasAutores(httplib::Server& servidor, const Config& config);
