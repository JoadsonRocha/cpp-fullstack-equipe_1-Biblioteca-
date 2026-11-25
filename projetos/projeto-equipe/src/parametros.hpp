// parametros.hpp - Funções auxiliares para preparar os parâmetros "?" das consultas SQL.
#pragma once

#include <string>

#include <nlohmann/json.hpp>

namespace parametros {

// Converte um valor JSON (texto ou número) para string compatível com prepared statements.
inline std::string comoTexto(const nlohmann::json& valor) {
    return valor.is_string() ? valor.get<std::string>() : valor.dump();
}

// Lê um campo opcional: se estiver ausente ou for null, devolve "padrao" ("" vira NULL via NULLIF no SQL).
inline std::string opcional(const nlohmann::json& dados, const char* campo, const std::string& padrao = "") {
    if (!dados.contains(campo) || dados[campo].is_null()) {
        return padrao;
    }
    return comoTexto(dados[campo]);
}

// Escapa curingas do LIKE (%, _ e \) para que a busca trate o termo literalmente.
inline std::string escaparLike(const std::string& texto) {
    std::string saida;
    saida.reserve(texto.size());
    for (char c : texto) {
        if (c == '\\' || c == '%' || c == '_') {
            saida += '\\';
        }
        saida += c;
    }
    return saida;
}

}  // namespace parametros
