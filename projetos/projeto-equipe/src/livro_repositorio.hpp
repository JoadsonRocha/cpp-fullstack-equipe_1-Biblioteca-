// livro_repositorio.hpp - Acesso à tabela "livros" (entidade principal da Biblioteca).
#pragma once

#include <string>

#include <nlohmann/json.hpp>

#include "banco.hpp"

struct FiltrosLivro {
    std::string busca;    // procura em título, gênero, ISBN ou nome do autor
    std::string genero;   // filtro exato por gênero
    std::string autorId;  // filtro por id do autor
};

class LivroRepositorio {
public:
    explicit LivroRepositorio(Conexao& banco) : banco_(banco) {}

    // Lista os livros aplicando os filtros opcionais combinados com AND.
    nlohmann::json listar(const FiltrosLivro& filtros = {});

    // Lista todos os livros de um autor específico.
    nlohmann::json listarPorAutor(long long autorId);

    // Estatísticas gerais do acervo: totais, livros sem exemplares e agrupamento por gênero e autor.
    nlohmann::json resumo();

    // Devolve o livro com o id informado, ou null se não existir.
    nlohmann::json buscar(long long id);

    // Insere e devolve o livro criado. ISBN repetido lança ErroBanco (1062) -> 409.
    nlohmann::json criar(const nlohmann::json& dados);

    // Atualiza o livro com o id informado. Devolve o livro atualizado, ou null se não existir.
    nlohmann::json atualizar(long long id, const nlohmann::json& dados);

    // Remove o livro. Devolve true se existia, false se não existir.
    bool remover(long long id);

private:
    Conexao& banco_;
};
