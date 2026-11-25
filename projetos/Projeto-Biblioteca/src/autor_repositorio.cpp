// autor_repositorio.cpp - Consultas SQL da tabela "autores" (sempre com parâmetros "?").
#include "autor_repositorio.hpp"

#include "parametros.hpp"

using nlohmann::json;

namespace {

// LEFT JOIN traz também autores que ainda não têm livros cadastrados (com contadores zerados).
const char* const kSelect =
    "SELECT a.id, a.nome, a.nacionalidade, a.criado_em, "
    "COUNT(l.id) AS total_livros, COALESCE(SUM(l.exemplares), 0) AS total_exemplares "
    "FROM autores a LEFT JOIN livros l ON l.autor_id = a.id ";

const char* const kAgrupar = "GROUP BY a.id, a.nome, a.nacionalidade, a.criado_em ";

}  // namespace

json AutorRepositorio::listar(const std::string& busca) {
    if (busca.empty()) {
        return banco_.consultar(std::string(kSelect) + kAgrupar + "ORDER BY a.nome");
    }
    // Escapa curingas (% e _) para evitar que caracteres digitados alterem o padrão do LIKE.
    const std::string padrao = "%" + parametros::escaparLike(busca) + "%";
    return banco_.consultar(
        std::string(kSelect) + "WHERE (a.nome LIKE ? OR COALESCE(a.nacionalidade, '') LIKE ?) " + kAgrupar +
            "ORDER BY a.nome",
        {padrao, padrao});
}

json AutorRepositorio::buscar(long long id) {
    json linhas = banco_.consultar(std::string(kSelect) + "WHERE a.id = ? " + kAgrupar, {std::to_string(id)});
    return linhas.empty() ? json(nullptr) : linhas.front();
}

json AutorRepositorio::criar(const json& dados) {
    // NULLIF(?, ''): string vazia vira NULL real no MariaDB para campos opcionais.
    banco_.executar("INSERT INTO autores (nome, nacionalidade) VALUES (?, NULLIF(?, ''))",
                    {parametros::comoTexto(dados.at("nome")), parametros::opcional(dados, "nacionalidade")});
    return buscar(static_cast<long long>(banco_.ultimoId()));
}

json AutorRepositorio::atualizar(long long id, const json& dados) {
    // Confere existência antes do UPDATE porque UPDATE sem mudanças retorna 0 linhas afetadas.
    if (buscar(id).is_null()) {
        return json(nullptr);
    }
    banco_.executar("UPDATE autores SET nome = ?, nacionalidade = NULLIF(?, '') WHERE id = ?",
                    {parametros::comoTexto(dados.at("nome")), parametros::opcional(dados, "nacionalidade"),
                     std::to_string(id)});
    return buscar(id);
}

bool AutorRepositorio::remover(long long id) {
    // Se o autor possuir livros, a FK ON DELETE RESTRICT lança ErroBanco (1451) -> rota responde 409.
    return banco_.executar("DELETE FROM autores WHERE id = ?", {std::to_string(id)}) > 0;
}
