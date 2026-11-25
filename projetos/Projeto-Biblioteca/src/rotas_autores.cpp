#include "rotas_autores.hpp"

#include <string>

#include <nlohmann/json.hpp>

#include "autor_repositorio.hpp"
#include "http_util.hpp"
#include "livro_repositorio.hpp"
#include "validacao.hpp"

using nlohmann::json;

namespace {

json validarAutor(const json& dados) {
    json erros = json::array();
    validacao::textoObrigatorio(dados, "nome", 100, erros);
    validacao::textoOpcional(dados, "nacionalidade", 50, erros);
    return erros;
}

}  // namespace

void registrarRotasAutores(httplib::Server& servidor, const Config& config) {
    // LISTAR
    servidor.Get("/api/autores", [&config](const httplib::Request& req, httplib::Response& res) {
        const std::string busca = req.get_param_value("busca");
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            util::enviarJson(res, repositorio.listar(busca));
        });
    });

    // LISTAR LIVROS DO AUTOR
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

    // BUSCAR UM
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

    // CRIAR
    servidor.Post("/api/autores", [&config](const httplib::Request& req, httplib::Response& res) {
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        json erros = validarAutor(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            util::enviarJson(res, repositorio.criar(dados), 201);
        });
    });

    // ATUALIZAR
    servidor.Put("/api/autores/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        json erros = validarAutor(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            json atualizado = repositorio.atualizar(id, dados);
            if (atualizado.is_null()) {
                util::enviarErro(res, 404, "Autor nao encontrado");
                return;
            }
            util::enviarJson(res, atualizado);
        });
    });

    // REMOVER
    servidor.Delete("/api/autores/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            AutorRepositorio repositorio(banco);
            if (!repositorio.remover(id)) {
                util::enviarErro(res, 404, "Autor nao encontrado");
                return;
            }
            res.status = 204;
        });
    });
}
