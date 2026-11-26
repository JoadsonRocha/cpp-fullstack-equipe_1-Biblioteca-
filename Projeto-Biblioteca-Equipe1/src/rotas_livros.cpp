// rotas_livros.cpp - Endpoints REST do recurso "livros" (entidade principal).
#include "rotas_livros.hpp"

#include <string>

#include <nlohmann/json.hpp>

#include "autor_repositorio.hpp"
#include "http_util.hpp"
#include "livro_repositorio.hpp"
#include "validacao.hpp"

using nlohmann::json;

namespace {

// Acumula todos os problemas de validação do livro para responder 422 de uma única vez.
json validarLivro(const json& dados) {
    json erros = json::array();
    validacao::textoObrigatorio(dados, "titulo", 150, erros);
    validacao::inteiroEmFaixa(dados, "autor_id", 1, 4294967295LL, true, erros);
    validacao::textoOpcional(dados, "genero", 50, erros);
    validacao::inteiroEmFaixa(dados, "ano_publicacao", 1000, 2100, false, erros);
    validacao::textoOpcional(dados, "isbn", 20, erros);
    validacao::inteiroEmFaixa(dados, "exemplares", 0, 1000000, false, erros);
    return erros;
}

// Extrai e valida os filtros opcionais da URL (?busca=...&genero=...&autor_id=...).
FiltrosLivro lerFiltros(const httplib::Request& req, json& erros) {
    FiltrosLivro filtros;
    filtros.busca = req.get_param_value("busca");
    filtros.genero = req.get_param_value("genero");

    if (req.has_param("autor_id") && !req.get_param_value("autor_id").empty()) {
        const std::string texto = req.get_param_value("autor_id");
        // Converte para número apenas quando tiver só dígitos; caso contrário passa texto para inteiroEmFaixa recusar.
        const bool soDigitos = texto.size() <= 10 && texto.find_first_not_of("0123456789") == std::string::npos;
        json recebido = json::object();
        recebido["autor_id"] = soDigitos ? json(std::stoll(texto)) : json(texto);
        validacao::inteiroEmFaixa(recebido, "autor_id", 1, 4294967295LL, false, erros);
        if (recebido["autor_id"].is_number_integer() && erros.empty()) {
            filtros.autorId = std::to_string(recebido["autor_id"].get<long long>());
        }
    }
    return filtros;
}

// Checa a existência do autor antes do INSERT/UPDATE para devolver 422 claro em vez de 409 genérico da FK.
bool autorExiste(Conexao& banco, const json& dados) {
    return !AutorRepositorio(banco).buscar(dados.at("autor_id").get<long long>()).is_null();
}

// Traduz erro 1062 (ISBN único) para uma mensagem amigável ao usuário.
template <typename Fn>
void comConflitoIsbn(httplib::Response& res, Fn&& operacao) {
    try {
        operacao();
    } catch (const ErroBanco& erro) {
        if (erro.chaveDuplicada()) {
            util::enviarErro(res, 409, "Ja existe um livro cadastrado com este ISBN.");
            return;
        }
        throw;
    }
}

}  // namespace

void registrarRotasLivros(httplib::Server& servidor, const Config& config) {
    // LISTAR (com filtros opcionais: ?busca=...&genero=...&autor_id=...)
    servidor.Get("/api/livros", [&config](const httplib::Request& req, httplib::Response& res) {
        json erros = json::array();
        const FiltrosLivro filtros = lerFiltros(req, erros);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Filtros invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            LivroRepositorio repositorio(banco);
            util::enviarJson(res, repositorio.listar(filtros));
        });
    });

    // RESUMO do acervo: precisa ser registrada ANTES de /api/livros/:id para "resumo" não cair no ":id".
    servidor.Get("/api/livros/resumo", [&config](const httplib::Request&, httplib::Response& res) {
        util::comBanco(config, res, [&](Conexao& banco) {
            LivroRepositorio repositorio(banco);
            util::enviarJson(res, repositorio.resumo());
        });
    });

    // BUSCAR UM: retorna o livro com autor_nome, 400 se ID inválido ou 404 se inexistente.
    servidor.Get("/api/livros/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            LivroRepositorio repositorio(banco);
            json livro = repositorio.buscar(id);
            if (livro.is_null()) {
                util::enviarErro(res, 404, "Livro nao encontrado");
                return;
            }
            util::enviarJson(res, livro);
        });
    });

    // CRIAR: valida dados, confirma autor_id e insere (ISBN duplicado -> 409 via util::comBanco).
    servidor.Post("/api/livros", [&config](const httplib::Request& req, httplib::Response& res) {
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        validacao::apararTextos(dados);
        json erros = validarLivro(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            if (!autorExiste(banco, dados)) {
                util::enviarErro(res, 422, "Dados invalidos", json::array({"autor_id nao existe"}));
                return;
            }
            comConflitoIsbn(res, [&]() {
                LivroRepositorio repositorio(banco);
                util::enviarJson(res, repositorio.criar(dados), 201);
            });
        });
    });

    // ATUALIZAR: valida entrada, confirma autor_id e substitui todos os campos do livro.
    servidor.Put("/api/livros/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        json dados;
        if (!util::lerCorpoObjeto(req, res, dados)) {
            return;
        }
        validacao::apararTextos(dados);
        json erros = validarLivro(dados);
        if (!erros.empty()) {
            util::enviarErro(res, 422, "Dados invalidos", erros);
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            if (!autorExiste(banco, dados)) {
                util::enviarErro(res, 422, "Dados invalidos", json::array({"autor_id nao existe"}));
                return;
            }
            comConflitoIsbn(res, [&]() {
                LivroRepositorio repositorio(banco);
                json atualizado = repositorio.atualizar(id, dados);
                if (atualizado.is_null()) {
                    util::enviarErro(res, 404, "Livro nao encontrado");
                    return;
                }
                util::enviarJson(res, atualizado);
            });
        });
    });

    // REMOVER: responde 204 (sem corpo) em caso de sucesso ou 404 se não existir.
    servidor.Delete("/api/livros/:id", [&config](const httplib::Request& req, httplib::Response& res) {
        long long id = 0;
        if (!util::lerId(req, res, id)) {
            return;
        }
        util::comBanco(config, res, [&](Conexao& banco) {
            LivroRepositorio repositorio(banco);
            if (!repositorio.remover(id)) {
                util::enviarErro(res, 404, "Livro nao encontrado");
                return;
            }
            res.status = 204;
        });
    });
}
