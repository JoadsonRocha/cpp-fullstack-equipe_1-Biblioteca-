// livro_repositorio.cpp - Consultas SQL da tabela "livros" (todas parametrizadas com "?").
#include "livro_repositorio.hpp"

#include <vector>

#include "parametros.hpp"

using nlohmann::json;

namespace {

// JOIN com autores já traz "autor_nome" junto ao livro para evitar consultas extras no front-end.
const char* const kSelect =
    "SELECT l.id, l.titulo, l.autor_id, a.nome AS autor_nome, l.genero, "
    "l.ano_publicacao, l.isbn, l.exemplares, l.criado_em "
    "FROM livros l JOIN autores a ON a.id = l.autor_id ";

const char* resolverOrdenacao(const std::string& ordenar) {
    if (ordenar == "titulo") {
        return "ORDER BY l.titulo ASC, l.id DESC";
    }
    if (ordenar == "ano") {
        return "ORDER BY l.ano_publicacao DESC, l.titulo ASC";
    }
    if (ordenar == "exemplares") {
        return "ORDER BY l.exemplares DESC, l.titulo ASC";
    }
    return "ORDER BY l.id DESC";
}

}  // namespace

json LivroRepositorio::listar(const FiltrosLivro& filtros) {
    // Monta cláusula WHERE dinâmica combinando apenas os filtros informados com AND.
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
    if (filtros.apenasDisponiveis) {
        condicoes.push_back("l.exemplares > 0");
    }

    std::string sql = kSelect;
    for (std::size_t i = 0; i < condicoes.size(); ++i) {
        sql += (i == 0 ? "WHERE " : "AND ") + condicoes[i] + " ";
    }
    return banco_.consultar(sql + resolverOrdenacao(filtros.ordenar), valores);

}

json LivroRepositorio::listarPorAutor(long long autorId) {
    return banco_.consultar(std::string(kSelect) + "WHERE l.autor_id = ? ORDER BY l.titulo",
                            {std::to_string(autorId)});
}

json LivroRepositorio::listarEsgotados() {
    return banco_.consultar(std::string(kSelect) + "WHERE l.exemplares = 0 ORDER BY l.titulo");
}

json LivroRepositorio::resumo() {
    // COALESCE garante 0 em vez de NULL caso a tabela ainda esteja vazia.
    json totais = banco_
                      .consultar(
                          "SELECT COUNT(*) AS total_livros, "
                          "CAST(COALESCE(SUM(exemplares), 0) AS SIGNED) AS total_exemplares, "
                          "CAST(COALESCE(SUM(exemplares = 0), 0) AS SIGNED) AS esgotados, "
                          "(SELECT COUNT(*) FROM autores) AS total_autores "
                          "FROM livros")
                      .front();

    // Agrupa livros sem gênero definido sob o rótulo "Sem gênero".
    totais["por_genero"] = banco_.consultar(
        "SELECT COALESCE(NULLIF(genero, ''), 'Sem gênero') AS genero, "
        "COUNT(*) AS total_livros, "
        "CAST(COALESCE(SUM(exemplares), 0) AS SIGNED) AS total_exemplares "
        "FROM livros "
        "GROUP BY COALESCE(NULLIF(genero, ''), 'Sem gênero') "
        "ORDER BY total_livros DESC, genero");

    // LEFT JOIN inclui autores que ainda não possuem livros cadastrados.
    totais["por_autor"] = banco_.consultar(
        "SELECT a.id AS autor_id, a.nome AS autor, "
        "COUNT(l.id) AS total_livros, "
        "CAST(COALESCE(SUM(l.exemplares), 0) AS SIGNED) AS total_exemplares "
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
    // NULLIF(?, '') evita gravar "" em colunas opcionais (fundamental para o UNIQUE de isbn).
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
    // Confere existência antes para distinguir "id inexistente" (404) de "nenhum campo alterado" (0 linhas).
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
