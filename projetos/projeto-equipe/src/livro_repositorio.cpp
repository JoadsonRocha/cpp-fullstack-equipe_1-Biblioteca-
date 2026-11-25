#include "livro_repositorio.hpp"

#include <vector>

#include "parametros.hpp"

using nlohmann::json;

namespace {

const char* const kSelect =
    "SELECT l.id, l.titulo, l.autor_id, a.nome AS autor_nome, l.genero, "
    "l.ano_publicacao, l.isbn, l.exemplares, l.criado_em "
    "FROM livros l JOIN autores a ON a.id = l.autor_id ";

}  // namespace

json LivroRepositorio::listar(const FiltrosLivro& filtros) {
    std::vector<std::string> condicoes;
    Conexao::Parametros valores;

    if (!filtros.busca.empty()) {
        const std::string padrao = "%" + parametros::escaparLike(filtros.busca) + "%";
        condicoes.push_back(
            "(l.titulo LIKE ? OR COALESCE(l.genero, '') LIKE ? OR a.nome LIKE ? OR COALESCE(l.isbn, '') LIKE ?)");
        valores.insert(valores.end(), {padrao, padrao, padrao, padrao});
    }
    if (!filtros.genero.empty()) {
        condicoes.push_back("l.genero = ?");
        valores.push_back(filtros.genero);
    }
    if (!filtros.autorId.empty()) {
        condicoes.push_back("l.autor_id = ?");
        valores.push_back(filtros.autorId);
    }

    std::string sql = kSelect;
    for (std::size_t i = 0; i < condicoes.size(); ++i) {
        sql += (i == 0 ? "WHERE " : "AND ") + condicoes[i] + " ";
    }
    return banco_.consultar(sql + "ORDER BY l.id DESC", valores);
}

json LivroRepositorio::listarPorAutor(long long autorId) {
    return banco_.consultar(std::string(kSelect) + "WHERE l.autor_id = ? ORDER BY l.titulo",
                            {std::to_string(autorId)});
}

json LivroRepositorio::resumo() {
    json totais = banco_
                      .consultar(
                          "SELECT COUNT(*) AS total_livros, "
                          "COALESCE(SUM(exemplares), 0) AS total_exemplares, "
                          "COALESCE(SUM(exemplares = 0), 0) AS esgotados, "
                          "(SELECT COUNT(*) FROM autores) AS total_autores "
                          "FROM livros")
                      .front();

    totais["por_genero"] = banco_.consultar(
        "SELECT COALESCE(NULLIF(genero, ''), 'Sem gênero') AS genero, "
        "COUNT(*) AS total_livros, "
        "COALESCE(SUM(exemplares), 0) AS total_exemplares "
        "FROM livros "
        "GROUP BY COALESCE(NULLIF(genero, ''), 'Sem gênero') "
        "ORDER BY total_livros DESC, genero");

    totais["por_autor"] = banco_.consultar(
        "SELECT a.id AS autor_id, a.nome AS autor, "
        "COUNT(l.id) AS total_livros, "
        "COALESCE(SUM(l.exemplares), 0) AS total_exemplares "
        "FROM autores a LEFT JOIN livros l ON l.autor_id = a.id "
        "GROUP BY a.id, a.nome "
        "ORDER BY total_livros DESC, a.nome");

    return totais;
}

json LivroRepositorio::buscar(long long id) {
    json linhas = banco_.consultar(std::string(kSelect) + "WHERE l.id = ?", {std::to_string(id)});
    return linhas.empty() ? json(nullptr) : linhas.front();
}

json LivroRepositorio::criar(const json& dados) {
    banco_.executar(
        "INSERT INTO livros (titulo, autor_id, genero, ano_publicacao, isbn, exemplares) "
        "VALUES (?, ?, NULLIF(?, ''), NULLIF(?, ''), NULLIF(?, ''), ?)",
        {parametros::comoTexto(dados.at("titulo")),
         parametros::comoTexto(dados.at("autor_id")),
         parametros::opcional(dados, "genero"),
         parametros::opcional(dados, "ano_publicacao"),
         parametros::opcional(dados, "isbn"),
         parametros::opcional(dados, "exemplares", "1")});
    return buscar(static_cast<long long>(banco_.ultimoId()));
}

json LivroRepositorio::atualizar(long long id, const json& dados) {
    if (buscar(id).is_null()) {
        return json(nullptr);
    }
    banco_.executar(
        "UPDATE livros SET titulo = ?, autor_id = ?, genero = NULLIF(?, ''), "
        "ano_publicacao = NULLIF(?, ''), isbn = NULLIF(?, ''), exemplares = ? "
        "WHERE id = ?",
        {parametros::comoTexto(dados.at("titulo")),
         parametros::comoTexto(dados.at("autor_id")),
         parametros::opcional(dados, "genero"),
         parametros::opcional(dados, "ano_publicacao"),
         parametros::opcional(dados, "isbn"),
         parametros::opcional(dados, "exemplares", "1"),
         std::to_string(id)});
    return buscar(id);
}

bool LivroRepositorio::remover(long long id) {
    return banco_.executar("DELETE FROM livros WHERE id = ?", {std::to_string(id)}) > 0;
}
