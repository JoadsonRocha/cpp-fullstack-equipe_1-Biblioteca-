// rotas_autores.cpp - Endpoints REST do recurso "autores" (entidade de apoio).
#include "rotas_autores.hpp"

#include <string>

#include <nlohmann/json.hpp>

#include "autor_repositorio.hpp"
#include "http_util.hpp"
#include "livro_repositorio.hpp"
#include "validacao.hpp"

using nlohmann::json;

namespace {

// Valida todos os campos de entrada do autor antes de acessar o banco (gera 422 se houver erros).
json validarAutor(const json& dados) {
    json erros = json::array();
    validacao::textoObrigatorio(dados, "nome", 100, erros);
    validacao::textoOpcional(dados, "nacionalidade", 50, erros);
    return erros;
}

// Traduz conflitos de banco (1062 nome único e 1451 FK de livros) para mensagens claras ao usuário.
template <typename Fn>
void comConflitoAutor(httplib::Response& res, Fn&& operacao) {
    try {
        operacao();
    } catch (const ErroBanco& erro) {
        if (erro.chaveDuplicada()) {
            util::enviarErro(res, 409, "Ja existe um autor cadastrado com este nome.");
            return;
        }
        if (erro.violacaoDeChaveEstrangeira()) {
            util::enviarErro(res, 409,
                             "Nao e possivel excluir este autor porque ele ainda possui livros cadastrados. "
                             "Exclua ou transfira os livros primeiro.");
            return;
        }
        throw;
    }
}

}  // namespace

void registrarRotasAutores(httplib::Server& servidor, const Config& config) {
    // LISTAR: aceita busca opcional (?busca=...) no nome ou na nacionalidade.
    servidor.Get("/api/autores", [&config](const httplib::Request& req, httplib::Response& res) {
        const std::string busca = req.get_param_value("busca");
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            util::enviarJson(res, repositorio.listar(busca));
        });
    });

    // LISTAR LIVROS DO AUTOR: rota extra para consultar o catálogo de um autor específico.
    servidor.Get("/api/autores/:id/livros", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio autores(banco);
            if (autores.buscar(id).is_null()) {
                util::enviarErro(res, 404, "Autor nao encontrado");
                return;
            }
            LivroRepositorio livros(banco);
            util::enviarJson(res, livros.listarPorAutor(id));
        });
    });

    // BUSCAR UM: devolve 400 se ":id" não for inteiro positivo, ou 404 se não existir.
    servidor.Get("/api/autores/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            json autor = repositorio.buscar(id);
            if (autor.is_null()) {
                util::enviarErro(res, 404, "Autor nao encontrado");
                return;
            }
            util::enviarJson(res, autor);
        });
    });

    // CRIAR: nome duplicado dispara erro 1062 no MariaDB -> responde 409 com mensagem clara.
    servidor.Post("/api/autores", [&config](const httplib::Request& req, httplib::Response& res) {
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        validacao::apararTextos(dados);
        json erros = validarAutor(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            comConflitoAutor(res, [&]() {
                AutorRepositorio repositorio(banco);
                util::enviarJson(res, repositorio.criar(dados), 201);
            });
        });
    });

    // ATUALIZAR: substitui nome e nacionalidade do autor informado.
    servidor.Put("/api/autores/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        validacao::apararTextos(dados);
        json erros = validarAutor(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            comConflitoAutor(res, [&]() {
                AutorRepositorio repositorio(banco);
                json atualizado = repositorio.atualizar(id, dados);
                if (atualizado.is_null()) {
                    util::enviarErro(res, 404, "Autor nao encontrado");
                    return;
                }
                util::enviarJson(res, atualizado);
            });
        });
    });

    // REMOVER: autor com livros vinculados dispara FK 1451 -> responde 409 explicando o motivo.
    servidor.Delete("/api/autores/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            comConflitoAutor(res, [&]() {
                AutorRepositorio repositorio(banco);
                if (!repositorio.remover(id)) {
                    util::enviarErro(res, 404, "Autor nao encontrado");
                    return;
                }
                res.status = 204;
            });
        });
    });
}
