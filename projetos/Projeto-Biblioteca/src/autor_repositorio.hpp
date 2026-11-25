// autor_repositorio.hpp - Acesso à tabela "autores" (entidade de apoio da Biblioteca).
#pragma once

#include <string>

#include <nlohmann/json.hpp>

#include "banco.hpp"

class AutorRepositorio {
public:
    explicit AutorRepositorio(Conexao& banco) : banco_(banco) {}

    // Lista os autores em ordem alfabética (opcionalmente filtrando por busca), com total_livros e total_exemplares.
    nlohmann::json listar(const std::string& busca = "");

    // Devolve o autor com o id informado, ou null se não existir.
    nlohmann::json buscar(long long id);

    // Insere e devolve o autor criado. Nome repetido lança ErroBanco (1062) -> 409.
    nlohmann::json criar(const nlohmann::json& dados);

    // Atualiza o autor com o id informado. Devolve o registro atualizado, ou null se não existir.
    nlohmann::json atualizar(long long id, const nlohmann::json& dados);

    // Remove o autor. Devolve true se existia, false se não existir.
    // Autor que possui livros lança ErroBanco (1451) -> 409.
    bool remover(long long id);

private:
    Conexao& banco_;
};
