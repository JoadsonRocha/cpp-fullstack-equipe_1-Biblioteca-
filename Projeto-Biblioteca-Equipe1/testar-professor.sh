#!/usr/bin/env bash
# testar-professor.sh - Bateria completa de testes da rubrica do professor (Linux/macOS/MSYS2).
#
# Uso:
#   ./testar-professor.sh          # roda todos os testes (sobe o Docker se o servidor estiver offline)
#   ./testar-professor.sh --reset  # recria o banco do zero (down -v + up) e roda tudo
set -euo pipefail
cd "$(dirname "$0")"

BASE_URL="${API_URL:-http://127.0.0.1:8080}"
RESET_BANCO=0
PASSOU=0
FALHOU=0
AVISOS=0
AUTOR_ID=""
LIVRO_IDS=()

for arg in "$@"; do
  case "$arg" in
    --reset) RESET_BANCO=1 ;;
    *) echo "Uso: $0 [--reset]" >&2; exit 2 ;;
  esac
done

pass() {
  PASSOU=$((PASSOU + 1))
  printf '  [PASS] %s%s\n' "$1" "${2:+ ($2)}"
}

fail() {
  FALHOU=$((FALHOU + 1))
  printf '  [FAIL] %s -> %s\n' "$1" "${2:-erro}"
}

aviso() {
  AVISOS=$((AVISOS + 1))
  printf '  [AVISO] %s\n' "$1"
}

api_call() {
  local metodo="$1"
  local caminho="$2"
  local corpo="${3:-}"
  local tmp_body
  tmp_body="$(mktemp)"
  local codigo
  if [[ -n "$corpo" ]]; then
    codigo=$(curl -sS -o "$tmp_body" -w "%{http_code}" -X "$metodo" \
      -H "Content-Type: application/json; charset=utf-8" \
      -d "$corpo" "$BASE_URL$caminho" || echo "000")
  else
    codigo=$(curl -sS -o "$tmp_body" -w "%{http_code}" -X "$metodo" \
      "$BASE_URL$caminho" || echo "000")
  fi
  API_STATUS="$codigo"
  API_BODY="$(cat "$tmp_body")"
  rm -f "$tmp_body"
}

check_status() {
  local nome="$1"
  local esperado="$2"
  if [[ "$API_STATUS" == "$esperado" ]]; then
    pass "$nome" "HTTP $API_STATUS"
    return 0
  else
    fail "$nome" "esperado HTTP $esperado, recebeu $API_STATUS: $API_BODY"
    return 1
  fi
}

extrair_id() {
  printf '%s' "$1" | sed -n 's/.*"id":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n1
}

limpar() {
  for lid in ${LIVRO_IDS[@]+"${LIVRO_IDS[@]}"}; do
    [[ -n "$lid" ]] && curl -sS -o /dev/null -X DELETE "$BASE_URL/api/livros/$lid" || true
  done
  if [[ -n "$AUTOR_ID" ]]; then
    curl -sS -o /dev/null -X DELETE "$BASE_URL/api/autores/$AUTOR_ID" || true
  fi
}
trap limpar EXIT

echo "============================================================"
echo "  Bateria de Testes do Professor — Biblioteca (Equipe 1)"
echo "  Alvo: $BASE_URL"
echo "============================================================"

echo ""
echo "=== 1. Banco de dados e Servidor ==="
if [[ "$RESET_BANCO" == 1 ]]; then
  docker compose --profile fullstack down -v
  docker compose --profile fullstack up -d --build --wait
  pass "Banco recriado do zero via schema.sql + stack fullstack"
elif ! curl -sf "$BASE_URL/api/saude" >/dev/null 2>&1; then
  docker compose --profile fullstack up -d --build --wait
  pass "Stack Docker iniciada automaticamente"
else
  pass "Servidor ja em execucao em $BASE_URL"
fi

echo ""
echo "=== 2. Auditoria de Codigo C++17, RAII e SQL Parametrizado ==="
if grep -q 'NULLIF(?, '\'''\'')' src/livro_repositorio.cpp; then
  pass "Uso de NULLIF(?, '') para campos opcionais (ISBN unico)"
else
  fail "NULLIF(?, '') nao encontrado em src/livro_repositorio.cpp"
fi

if grep -q '~Impl(' src/banco.cpp && grep -q 'mysql_close' src/banco.cpp && grep -q 'mysql_stmt_close' src/banco.cpp; then
  pass "RAII implementado em Conexao e Instrucao (src/banco.cpp)"
else
  fail "Destrutores RAII esperados nao encontrados em src/banco.cpp"
fi

if command -v g++ >/dev/null 2>&1; then
  if build_out="$(./build.sh 2>&1)" && ! printf '%s' "$build_out" | grep -qi 'warning:'; then
    pass "Compilacao local g++ -std=c++17 -Wall -Wextra sem avisos"
  else
    fail "Compilacao local falhou ou emitiu avisos" "$build_out"
  fi
else
  aviso "g++ local nao encontrado; compilacao validada pelo Dockerfile"
fi

echo ""
echo "=== 3. Saude da API, Banco e Paginas Front-end ==="
api_call GET /api/saude
check_status "GET /api/saude" 200 || true
api_call GET /api/saude/banco
check_status "GET /api/saude/banco" 200 || true

paginas_ok=1
for p in /index.html /autores.html /resumo.html /api.html /app.js /config.js /config-autores.js /resumo.js /api.js /estilo.css /favicon.svg; do
  api_call GET "$p"
  if [[ "$API_STATUS" != "200" ]]; then
    fail "GET $p" "HTTP $API_STATUS"
    paginas_ok=0
  fi
done
[[ "$paginas_ok" == 1 ]] && pass "Todas as telas e assets estaticos respondem HTTP 200"

api_call GET /api/autores
check_status "GET /api/autores (seed inicial)" 200 || true
api_call GET /api/livros
if check_status "GET /api/livros (seed inicial + JOIN)" 200; then
  if printf '%s' "$API_BODY" | grep -q '"autor_nome"'; then
    pass "Listagem traz autor_nome via JOIN"
  else
    fail "Campo autor_nome ausente em GET /api/livros"
  fi
fi

echo ""
echo "=== 4. Validacao e Codigos de Erro (400, 404, 422) ==="
api_call POST /api/livros '{json_invalido'
check_status "POST /api/livros JSON malformado -> 400" 400 || true
api_call GET /api/livros/abc
check_status "GET /api/livros/abc (ID nao numerico) -> 400" 400 || true
api_call GET /api/livros/99999
check_status "GET /api/livros/99999 -> 404" 404 || true
api_call GET /api/autores/99999
check_status "GET /api/autores/99999 -> 404" 404 || true

api_call POST /api/livros '{"autor_id":1,"ano_publicacao":2020}'
if check_status "POST /api/livros sem titulo -> 422" 422; then
  if printf '%s' "$API_BODY" | grep -q '"detalhes"'; then
    pass "Erro 422 retorna array detalhes em JSON"
  else
    fail "Array detalhes ausente no 422"
  fi
fi

api_call POST /api/livros '{"titulo":"Teste Ano","autor_id":1,"ano_publicacao":3000}'
check_status "POST /api/livros ano_publicacao 3000 -> 422" 422 || true
api_call POST /api/livros '{"titulo":"Teste Neg","autor_id":1,"exemplares":-1}'
check_status "POST /api/livros exemplares -1 -> 422" 422 || true
api_call POST /api/livros '{"titulo":"Autor Inexistente","autor_id":99999}'
check_status "POST /api/livros autor_id inexistente -> 422" 422 || true

echo ""
echo "=== 5. CRUD de Autores e Unicidade (201, 200, 409) ==="
SUFIXO="$(date +%Y%m%d%H%M%S)"
NOME_AUTOR="Jorge Amado QA $SUFIXO"
api_call POST /api/autores "{\"nome\":\"$NOME_AUTOR\",\"nacionalidade\":\"Brasileira\"}"
if check_status "POST /api/autores -> 201" 201; then
  AUTOR_ID="$(extrair_id "$API_BODY")"
fi

api_call POST /api/autores "{\"nome\":\"$NOME_AUTOR\",\"nacionalidade\":\"Brasileira\"}"
check_status "POST /api/autores duplicado -> 409" 409 || true

api_call GET "/api/autores/$AUTOR_ID"
check_status "GET /api/autores/:id -> 200" 200 || true

api_call PUT "/api/autores/$AUTOR_ID" "{\"nome\":\"$NOME_AUTOR\",\"nacionalidade\":\"Baiana\"}"
check_status "PUT /api/autores/:id -> 200" 200 || true

echo ""
echo "=== 6. CRUD de Livros, ISBN Unico (409) e NULLIF sem ISBN ==="
ISBN_TESTE="978${SUFIXO: -10}"
api_call POST /api/livros "{\"titulo\":\"Capitaes QA $SUFIXO\",\"autor_id\":$AUTOR_ID,\"genero\":\"Romance\",\"ano_publicacao\":1937,\"isbn\":\"$ISBN_TESTE\",\"exemplares\":0}"
if check_status "POST /api/livros com ISBN e 0 exemplares -> 201" 201; then
  LIVRO1_ID="$(extrair_id "$API_BODY")"
  LIVRO_IDS+=("$LIVRO1_ID")
fi

api_call POST /api/livros "{\"titulo\":\"ISBN Repetido\",\"autor_id\":$AUTOR_ID,\"isbn\":\"$ISBN_TESTE\"}"
check_status "POST /api/livros mesmo ISBN -> 409" 409 || true

api_call POST /api/livros "{\"titulo\":\"Sem ISBN A $SUFIXO\",\"autor_id\":$AUTOR_ID,\"genero\":\"Conto\",\"isbn\":\"\"}"
if check_status "POST /api/livros #1 sem ISBN -> 201" 201; then
  LIVRO_IDS+=("$(extrair_id "$API_BODY")")
fi

api_call POST /api/livros "{\"titulo\":\"Sem ISBN B $SUFIXO\",\"autor_id\":$AUTOR_ID,\"genero\":\"Conto\",\"isbn\":\"\"}"
if check_status "POST /api/livros #2 sem ISBN (NULLIF) -> 201" 201; then
  LIVRO_IDS+=("$(extrair_id "$API_BODY")")
fi

api_call GET "/api/livros/$LIVRO1_ID"
check_status "GET /api/livros/:id -> 200" 200 || true

api_call PUT "/api/livros/$LIVRO1_ID" "{\"titulo\":\"Capitaes QA $SUFIXO\",\"autor_id\":$AUTOR_ID,\"genero\":\"Romance\",\"ano_publicacao\":1937,\"isbn\":\"$ISBN_TESTE\",\"exemplares\":4}"
check_status "PUT /api/livros/:id (exemplares 0 -> 4) -> 200" 200 || true

echo ""
echo "=== 7. Busca, Filtros e Rotas Extras ==="
api_call GET "/api/livros?busca=Machado"
check_status "GET /api/livros?busca=Machado -> 200" 200 || true

api_call GET "/api/livros?genero=Romance&autor_id=$AUTOR_ID"
check_status "GET /api/livros?genero=Romance&autor_id=:id -> 200" 200 || true

api_call GET "/api/livros?autor_id=abc"
check_status "GET /api/livros?autor_id=abc -> 422" 422 || true

api_call GET "/api/autores/$AUTOR_ID/livros"
check_status "GET /api/autores/:id/livros -> 200" 200 || true

api_call GET "/api/livros/resumo"
if check_status "GET /api/livros/resumo -> 200" 200; then
  if printf '%s' "$API_BODY" | grep -q '"total_livros"' && printf '%s' "$API_BODY" | grep -q '"por_genero"' && printf '%s' "$API_BODY" | grep -q '"por_autor"'; then
    pass "Resumo contem total_livros, por_genero e por_autor"
  else
    fail "Estrutura de resumo incompleta" "$API_BODY"
  fi
fi

echo ""
echo "=== 8. Regra ON DELETE RESTRICT (409) e Exclusao (204) ==="
api_call DELETE "/api/autores/$AUTOR_ID"
check_status "DELETE /api/autores/:id com livros -> 409" 409 || true

NOVOS_IDS=()
for lid in ${LIVRO_IDS[@]+"${LIVRO_IDS[@]}"}; do
  api_call DELETE "/api/livros/$lid"
  if ! check_status "DELETE /api/livros/$lid -> 204" 204; then
    NOVOS_IDS+=("$lid")
  fi
done
if [[ ${#NOVOS_IDS[@]} -gt 0 ]]; then
  LIVRO_IDS=("${NOVOS_IDS[@]}")
else
  LIVRO_IDS=()
fi

api_call GET "/api/livros/$LIVRO1_ID"
check_status "GET livro excluido -> 404" 404 || true

api_call DELETE "/api/autores/$AUTOR_ID"
if check_status "DELETE /api/autores/:id sem livros -> 204" 204; then
  OLD_AUTOR_ID="$AUTOR_ID"
  AUTOR_ID=""
  api_call GET "/api/autores/$OLD_AUTOR_ID"
  check_status "GET autor excluido -> 404" 404 || true
fi

echo ""
echo "=== 9. Documentacao e Entrega ==="
if [[ -f "README.md" && -f "APRESENTACAO.md" ]]; then
  pass "README.md e APRESENTACAO.md presentes"
else
  fail "README.md ou APRESENTACAO.md ausente"
fi

if [[ -f "../projetos/EQUIPE.md" ]]; then
  if grep -q '\[Preencher' ../projetos/EQUIPE.md; then
    aviso "projetos/EQUIPE.md ainda contem campos [Preencher] dos demais integrantes"
  else
    pass "projetos/EQUIPE.md totalmente preenchido"
  fi
else
  fail "projetos/EQUIPE.md nao encontrado"
fi

if command -v git >/dev/null 2>&1; then
  if git -C .. tag -l "projeto-final" | grep -qx "projeto-final"; then
    pass "Tag Git 'projeto-final' criada"
  else
    aviso "Tag Git 'projeto-final' ainda nao foi criada (criar antes da entrega final)"
  fi
fi

echo ""
echo "============================================================"
echo "  RESULTADO FINAL: $PASSOU passaram | $FALHOU falharam | $AVISOS avisos"
echo "============================================================"
[[ "$FALHOU" -eq 0 ]]
