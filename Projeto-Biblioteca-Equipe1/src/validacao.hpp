// validacao.hpp - Funções reutilizáveis para validar os campos JSON recebidos pela API.
#pragma once

#include <cstddef>
#include <string>

#include <nlohmann/json.hpp>

namespace validacao {

using nlohmann::json;

inline bool temValor(const json& dados, const char* campo) {
    return dados.contains(campo) && !dados[campo].is_null();
}

inline bool apenasEspacos(const std::string& texto) {
    return texto.find_first_not_of(" \t\r\n") == std::string::npos;
}

// Remove espacos, tabs e quebras de linha das pontas de um texto.
inline std::string aparar(const std::string& texto) {
    const std::size_t inicio = texto.find_first_not_of(" \t\r\n");
    if (inicio == std::string::npos) {
        return "";
    }
    const std::size_t fim = texto.find_last_not_of(" \t\r\n");
    return texto.substr(inicio, fim - inicio + 1);
}

// Aplica aparar() em todos os campos de texto do objeto, ANTES de validar e gravar.
// Assim "  Dom Casmurro  " e "   " se comportam igual vindo do front-end ou do curl.
inline void apararTextos(json& dados) {
    for (auto& item : dados.items()) {
        if (item.value().is_string()) {
            item.value() = aparar(item.value().get<std::string>());
        }
    }
}

// Conta caracteres UTF-8 (e nao bytes): "ç" e "é" ocupam 2 bytes, mas sao 1 caractere para o usuario e para o VARCHAR.
inline std::size_t contarCaracteres(const std::string& texto) {
    std::size_t total = 0;
    for (unsigned char c : texto) {
        if ((c & 0xC0) != 0x80) {  // ignora bytes de continuacao (10xxxxxx)
            ++total;
        }
    }
    return total;
}

// Texto obrigatório: presente, string, não vazio/só espaços e com até "max" bytes.
inline void textoObrigatorio(const json& dados, const char* campo, std::size_t max, json& erros) {
    const std::string nome = campo;
    if (!temValor(dados, campo) || !dados[campo].is_string()) {
        erros.push_back(nome + " e obrigatorio");
        return;
    }
    const std::string valor = dados[campo].get<std::string>();
    if (valor.empty() || apenasEspacos(valor)) {
        erros.push_back(nome + " e obrigatorio");
    } else if (contarCaracteres(valor) > max) {
        erros.push_back(nome + " deve ter no maximo " + std::to_string(max) + " caracteres");
    }
}

// Texto opcional: se presente e não null, precisa ser string com até "max" bytes.
inline void textoOpcional(const json& dados, const char* campo, std::size_t max, json& erros) {
    if (!temValor(dados, campo)) {
        return;
    }
    const std::string nome = campo;
    if (!dados[campo].is_string()) {
        erros.push_back(nome + " deve ser texto");
    } else if (contarCaracteres(dados[campo].get<std::string>()) > max) {
        erros.push_back(nome + " deve ter no maximo " + std::to_string(max) + " caracteres");
    }
}

// Número inteiro entre "minimo" e "maximo". Se "obrigatorio" for false, ausente ou null é aceito.
inline void inteiroEmFaixa(const json& dados, const char* campo, long long minimo, long long maximo,
                           bool obrigatorio, json& erros) {
    const std::string nome = campo;
    if (!temValor(dados, campo)) {
        if (obrigatorio) {
            erros.push_back(nome + " e obrigatorio");
        }
        return;
    }
    const json& valor = dados[campo];
    if (!valor.is_number_integer() || valor.get<long long>() < minimo || valor.get<long long>() > maximo) {
        erros.push_back(nome + " deve ser um numero inteiro de " + std::to_string(minimo) + " a " +
                        std::to_string(maximo));
    }
}

}  // namespace validacao
