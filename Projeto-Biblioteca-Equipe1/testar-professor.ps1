param(
    [switch]$ResetBanco,
    [switch]$ComBuildLocal
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$PastaProjeto = Split-Path -Parent $MyInvocation.MyCommand.Path
$PastaRaiz = Split-Path -Parent $PastaProjeto
$BaseUrl = if ($env:API_URL) { $env:API_URL.TrimEnd("/") } else { "http://127.0.0.1:8080" }

$Script:Passou = 0
$Script:Falhou = 0
$Script:Avisos = 0
$Script:AutorCriadoId = $null
$Script:LivrosCriadosIds = New-Object System.Collections.Generic.List[int]

function Escrever-Titulo([string]$Texto) {
    Write-Host ""
    Write-Host "=== $Texto ===" -ForegroundColor Cyan
}

function Registrar-Pass([string]$Nome, [string]$Detalhe = "") {
    $Script:Passou++
    if ($Detalhe) {
        Write-Host "  [PASS] $Nome ($Detalhe)" -ForegroundColor Green
    } else {
        Write-Host "  [PASS] $Nome" -ForegroundColor Green
    }
}

function Registrar-Fail([string]$Nome, [string]$Detalhe = "") {
    $Script:Falhou++
    if ($Detalhe) {
        Write-Host "  [FAIL] $Nome -> $Detalhe" -ForegroundColor Red
    } else {
        Write-Host "  [FAIL] $Nome" -ForegroundColor Red
    }
}

function Registrar-Aviso([string]$Nome, [string]$Detalhe = "") {
    $Script:Avisos++
    if ($Detalhe) {
        Write-Host "  [AVISO] $Nome ($Detalhe)" -ForegroundColor Yellow
    } else {
        Write-Host "  [AVISO] $Nome" -ForegroundColor Yellow
    }
}

function Chamar-Api {
    param(
        [string]$Metodo,
        [string]$Caminho,
        [string]$CorpoJson = ""
    )

    $url = "$BaseUrl$Caminho"
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Method = $Metodo
    $req.Timeout = 10000
    $req.Accept = "application/json, text/html, */*"

    if (($Metodo -eq "POST" -or $Metodo -eq "PUT" -or $Metodo -eq "PATCH") -and -not [string]::IsNullOrEmpty($CorpoJson)) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($CorpoJson)
        $req.ContentType = "application/json; charset=utf-8"
        $req.ContentLength = $bytes.Length
        $stream = $req.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }

    $status = 0
    $texto = ""
    try {
        $resp = [System.Net.HttpWebResponse]$req.GetResponse()
        $status = [int]$resp.StatusCode
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream(), [System.Text.Encoding]::UTF8)
        $texto = $reader.ReadToEnd()
        $reader.Close()
        $resp.Close()
    } catch [System.Net.WebException] {
        if ($_.Exception.Response) {
            $errResp = [System.Net.HttpWebResponse]$_.Exception.Response
            $status = [int]$errResp.StatusCode
            $reader = New-Object System.IO.StreamReader($errResp.GetResponseStream(), [System.Text.Encoding]::UTF8)
            $texto = $reader.ReadToEnd()
            $reader.Close()
            $errResp.Close()
        } else {
            throw
        }
    }

    $json = $null
    if ($texto -and ($texto.TrimStart().StartsWith("{") -or $texto.TrimStart().StartsWith("["))) {
        try {
            $json = $texto | ConvertFrom-Json
        } catch {
            $json = $null
        }
    }

    return @{
        Status = $status
        Body   = $texto
        Json   = $json
    }
}

function Verificar-Status {
    param(
        [string]$Nome,
        [hashtable]$Resp,
        [int]$Esperado
    )
    if ($Resp.Status -eq $Esperado) {
        Registrar-Pass $Nome "HTTP $($Resp.Status)"
        return $true
    } else {
        Registrar-Fail $Nome "esperado HTTP $Esperado, recebeu $($Resp.Status): $($Resp.Body)"
        return $false
    }
}

function Servidor-Ativo {
    try {
        $r = Chamar-Api -Metodo "GET" -Caminho "/api/saude"
        return ($r.Status -eq 200)
    } catch {
        return $false
    }
}

Push-Location $PastaProjeto
try {
    Write-Host "============================================================" -ForegroundColor White
    Write-Host "  Bateria de Testes do Professor — Biblioteca (Equipe 1)" -ForegroundColor White
    Write-Host "  Alvo: $BaseUrl" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor White

    # ------------------------------------------------------------------
    # 1. Infraestrutura Docker (subir do zero se pedido ou se offline)
    # ------------------------------------------------------------------
    Escrever-Titulo "1. Banco de dados e Servidor"
    if ($ResetBanco) {
        Write-Host "  Recriando banco do zero (docker compose down -v + up -d --build --wait)..." -ForegroundColor Gray
        & docker compose --profile fullstack down -v
        if ($LASTEXITCODE -ne 0) { throw "Falha ao executar docker compose down -v" }
        & docker compose --profile fullstack up -d --build --wait
        if ($LASTEXITCODE -ne 0) { throw "Falha ao subir docker compose --profile fullstack" }
        Registrar-Pass "Banco recriado do zero via schema.sql + stack fullstack"
    } elseif (-not (Servidor-Ativo)) {
        Write-Host "  Servidor offline em $BaseUrl. Subindo stack Docker..." -ForegroundColor Gray
        & docker compose --profile fullstack up -d --build --wait
        if ($LASTEXITCODE -ne 0) { throw "Falha ao subir docker compose --profile fullstack" }
        Registrar-Pass "Stack Docker iniciada automaticamente"
    } else {
        Registrar-Pass "Servidor ja em execucao em $BaseUrl"
    }

    # ------------------------------------------------------------------
    # 2. Auditoria de Codigo C++ e SQL com '?'
    # ------------------------------------------------------------------
    Escrever-Titulo "2. Auditoria de Codigo C++17, RAII e SQL Parametrizado"
    $repoArquivos = @("src\autor_repositorio.cpp", "src\livro_repositorio.cpp")
    $sqlSeguro = $true
    foreach ($arq in $repoArquivos) {
        $conteudo = Get-Content -Path $arq -Raw -Encoding UTF8
        if ($conteudo -match "\+\s*(autor|livro|filtro|dados)\." -or $conteudo -match 'fmt::format') {
            $sqlSeguro = $false
        }
    }
    if ($sqlSeguro) {
        Registrar-Pass "Repositorios usam placeholders '?' sem concatenacao de valores"
    } else {
        Registrar-Fail "Possivel concatenacao de valores em SQL detectada"
    }

    $livroRepo = Get-Content -Path "src\livro_repositorio.cpp" -Raw -Encoding UTF8
    if ($livroRepo -match "NULLIF\(\?, ''\)") {
        Registrar-Pass "Uso de NULLIF(?, '') para campos opcionais (ISBN unico)"
    } else {
        Registrar-Fail "NULLIF(?, '') nao encontrado em livro_repositorio.cpp"
    }

    $bancoCpp = Get-Content -Path "src\banco.cpp" -Raw -Encoding UTF8
    if ($bancoCpp -match "~Impl\(" -and $bancoCpp -match "mysql_close" -and $bancoCpp -match "mysql_stmt_close") {
        Registrar-Pass "RAII implementado em Conexao e Instrucao (src/banco.cpp)"
    } else {
        Registrar-Fail "Destrutores RAII esperados nao encontrados em src/banco.cpp"
    }

    $gppEncontrado = Get-Command g++ -ErrorAction SilentlyContinue
    if (-not $gppEncontrado -and (Test-Path "C:\msys64\ucrt64\bin\g++.exe")) {
        $env:PATH = "C:\msys64\ucrt64\bin;$env:PATH"
        $gppEncontrado = Get-Command g++ -ErrorAction SilentlyContinue
    }

    if ($ComBuildLocal -or $gppEncontrado) {
        $tempLog = Join-Path $env:TEMP "bib_build_check.log"
        & cmd /c "build.bat > `"$tempLog`" 2>&1"
        $exitBuild = $LASTEXITCODE
        $saidaBuild = if (Test-Path $tempLog) { Get-Content $tempLog -Raw } else { "" }
        if ($exitBuild -eq 0 -and $saidaBuild -notmatch "warning:") {
            Registrar-Pass "Compilacao local g++ -std=c++17 -Wall -Wextra sem avisos"
        } elseif ($exitBuild -eq 0) {
            Registrar-Fail "Compilou, mas houve avisos do compilador" $saidaBuild
        } else {
            Registrar-Fail "Falha na compilacao local (build.bat)" $saidaBuild
        }
    } else {
        Registrar-Aviso "g++ local nao encontrado no PATH; compilacao com -Wall -Wextra garantida no Dockerfile"
    }

    # ------------------------------------------------------------------
    # 3. Saude e Arquivos Front-end
    # ------------------------------------------------------------------
    Escrever-Titulo "3. Saude da API, Banco e Paginas Front-end"
    $r = Chamar-Api -Metodo "GET" -Caminho "/api/saude"
    if ((Verificar-Status "GET /api/saude" $r 200) -and $r.Json.status -ne "ok") {
        Registrar-Fail "GET /api/saude JSON inesperado" $r.Body
    }

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/saude/banco"
    if ((Verificar-Status "GET /api/saude/banco" $r 200) -and $r.Json.banco -ne "ok") {
        Registrar-Fail "GET /api/saude/banco JSON inesperado" $r.Body
    }

    $paginas = @("/index.html", "/autores.html", "/resumo.html", "/api.html", "/app.js", "/config.js", "/config-autores.js", "/resumo.js", "/api.js", "/estilo.css", "/favicon.svg")
    $paginasOk = $true
    foreach ($p in $paginas) {
        $rp = Chamar-Api -Metodo "GET" -Caminho $p
        if ($rp.Status -ne 200) {
            Registrar-Fail "GET $p" "HTTP $($rp.Status)"
            $paginasOk = $false
        }
    }
    if ($paginasOk) {
        Registrar-Pass "Todas as telas e assets estaticos respondem HTTP 200 ($($paginas.Count) arquivos)"
    }

    $rAutores = Chamar-Api -Metodo "GET" -Caminho "/api/autores"
    if (Verificar-Status "GET /api/autores (seed inicial)" $rAutores 200) {
        $qtdAutores = @($rAutores.Json).Count
        if ($qtdAutores -ge 5) {
            Registrar-Pass "Seed inicial de autores presente ($qtdAutores autores)"
        } else {
            Registrar-Fail "Esperado ao menos 5 autores iniciais" "encontrado $qtdAutores"
        }
    }

    $rLivros = Chamar-Api -Metodo "GET" -Caminho "/api/livros"
    if (Verificar-Status "GET /api/livros (seed inicial + JOIN)" $rLivros 200) {
        $listaLivros = @($rLivros.Json)
        if ($listaLivros.Count -ge 10 -and $listaLivros[0].autor_nome) {
            Registrar-Pass "Seed de livros presente com autor_nome via JOIN ($($listaLivros.Count) livros)"
        } else {
            Registrar-Fail "Esperado >= 10 livros com autor_nome" $rLivros.Body
        }
    }

    # ------------------------------------------------------------------
    # 4. Validacao e Codigos de Erro (400, 404, 422)
    # ------------------------------------------------------------------
    Escrever-Titulo "4. Validacao e Codigos de Erro (400, 404, 422)"
    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson "{json_invalido"
    Verificar-Status "POST /api/livros com JSON malformado -> 400" $r 400 | Out-Null

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros/abc"
    Verificar-Status "GET /api/livros/abc (ID nao numerico) -> 400" $r 400 | Out-Null

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros/99999"
    Verificar-Status "GET /api/livros/99999 (nao existe) -> 404" $r 404 | Out-Null

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/autores/99999"
    Verificar-Status "GET /api/autores/99999 (nao existe) -> 404" $r 404 | Out-Null

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson '{"autor_id":1,"ano_publicacao":2020}'
    if (Verificar-Status "POST /api/livros sem titulo -> 422" $r 422) {
        if ($r.Json.detalhes -and $r.Json.detalhes.Count -ge 1) {
            Registrar-Pass "Erro 422 retorna array 'detalhes' em JSON"
        } else {
            Registrar-Fail "Erro 422 nao retornou array 'detalhes'" $r.Body
        }
    }

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson '{"titulo":"Teste Ano","autor_id":1,"ano_publicacao":3000}'
    Verificar-Status "POST /api/livros com ano_publicacao 3000 -> 422" $r 422 | Out-Null

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson '{"titulo":"Teste Neg","autor_id":1,"exemplares":-1}'
    Verificar-Status "POST /api/livros com exemplares -1 -> 422" $r 422 | Out-Null

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson '{"titulo":"Autor Inexistente","autor_id":99999}'
    if (Verificar-Status "POST /api/livros com autor_id inexistente -> 422" $r 422) {
        if ($r.Body -match "autor_id nao existe") {
            Registrar-Pass "Mensagem clara 'autor_id nao existe' retornada"
        } else {
            Registrar-Fail "Mensagem esperada 'autor_id nao existe' nao encontrada" $r.Body
        }
    }

    # ------------------------------------------------------------------
    # 5. CRUD de Autores + Conflito 409
    # ------------------------------------------------------------------
    Escrever-Titulo "5. CRUD de Autores e Unicidade (201, 200, 409)"
    $sufixo = Get-Date -Format "yyyyMMddHHmmss"
    $nomeAutor = "Jorge Amado QA $sufixo"
    $payloadAutor = (@{ nome = $nomeAutor; nacionalidade = "Brasileira" } | ConvertTo-Json -Compress)

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/autores" -CorpoJson $payloadAutor
    if (Verificar-Status "POST /api/autores (criar autor) -> 201" $r 201) {
        $Script:AutorCriadoId = [int]$r.Json.id
    }

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/autores" -CorpoJson $payloadAutor
    Verificar-Status "POST /api/autores com nome duplicado -> 409" $r 409 | Out-Null

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/autores/$($Script:AutorCriadoId)"
    Verificar-Status "GET /api/autores/:id -> 200" $r 200 | Out-Null

    $payloadAutorEdit = (@{ nome = $nomeAutor; nacionalidade = "Baiana" } | ConvertTo-Json -Compress)
    $r = Chamar-Api -Metodo "PUT" -Caminho "/api/autores/$($Script:AutorCriadoId)" -CorpoJson $payloadAutorEdit
    if (Verificar-Status "PUT /api/autores/:id -> 200" $r 200) {
        if ($r.Json.nacionalidade -eq "Baiana") {
            Registrar-Pass "Nacionalidade atualizada no PUT /api/autores/:id"
        } else {
            Registrar-Fail "Nacionalidade nao foi atualizada" $r.Body
        }
    }

    # ------------------------------------------------------------------
    # 6. CRUD de Livros + ISBN Duplicado 409 + Dois Livros Sem ISBN
    # ------------------------------------------------------------------
    Escrever-Titulo "6. CRUD de Livros, ISBN Unico (409) e NULLIF sem ISBN"
    $isbnTeste = "978$($sufixo.Substring($sufixo.Length - 10))"
    $livro1Json = (@{
        titulo = "Capitaes QA $sufixo"
        autor_id = $Script:AutorCriadoId
        genero = "Romance"
        ano_publicacao = 1937
        isbn = $isbnTeste
        exemplares = 0
    } | ConvertTo-Json -Compress)

    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson $livro1Json
    if (Verificar-Status "POST /api/livros (com ISBN e 0 exemplares) -> 201" $r 201) {
        $Script:LivrosCriadosIds.Add([int]$r.Json.id)
    }

    $livroDupJson = (@{
        titulo = "Livro ISBN Repetido"
        autor_id = $Script:AutorCriadoId
        genero = "Romance"
        ano_publicacao = 1950
        isbn = $isbnTeste
        exemplares = 1
    } | ConvertTo-Json -Compress)
    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson $livroDupJson
    Verificar-Status "POST /api/livros com mesmo ISBN -> 409" $r 409 | Out-Null

    $livroSemIsbn1 = (@{
        titulo = "Livro Sem ISBN A $sufixo"
        autor_id = $Script:AutorCriadoId
        genero = "Conto"
        ano_publicacao = 1940
        isbn = ""
        exemplares = 2
    } | ConvertTo-Json -Compress)
    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson $livroSemIsbn1
    if (Verificar-Status "POST /api/livros #1 sem ISBN -> 201" $r 201) {
        $Script:LivrosCriadosIds.Add([int]$r.Json.id)
    }

    $livroSemIsbn2 = (@{
        titulo = "Livro Sem ISBN B $sufixo"
        autor_id = $Script:AutorCriadoId
        genero = "Conto"
        ano_publicacao = 1942
        isbn = ""
        exemplares = 3
    } | ConvertTo-Json -Compress)
    $r = Chamar-Api -Metodo "POST" -Caminho "/api/livros" -CorpoJson $livroSemIsbn2
    if (Verificar-Status "POST /api/livros #2 sem ISBN (NULLIF) -> 201" $r 201) {
        $Script:LivrosCriadosIds.Add([int]$r.Json.id)
    }

    $idLivro1 = $Script:LivrosCriadosIds[0]
    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros/$idLivro1"
    if (Verificar-Status "GET /api/livros/:id -> 200" $r 200) {
        if ($r.Json.autor_nome -eq $nomeAutor) {
            Registrar-Pass "GET /api/livros/:id traz autor_nome correto"
        } else {
            Registrar-Fail "autor_nome incorreto em GET /api/livros/:id" $r.Body
        }
    }

    $livroEditJson = (@{
        titulo = "Capitaes QA $sufixo"
        autor_id = $Script:AutorCriadoId
        genero = "Romance"
        ano_publicacao = 1937
        isbn = $isbnTeste
        exemplares = 4
    } | ConvertTo-Json -Compress)
    $r = Chamar-Api -Metodo "PUT" -Caminho "/api/livros/$idLivro1" -CorpoJson $livroEditJson
    if (Verificar-Status "PUT /api/livros/:id (exemplares 0 -> 4) -> 200" $r 200) {
        if ([int]$r.Json.exemplares -eq 4) {
            Registrar-Pass "Exemplares atualizado para 4"
        } else {
            Registrar-Fail "Exemplares nao atualizado" $r.Body
        }
    }

    # ------------------------------------------------------------------
    # 7. Busca, Filtros e Rotas Extras
    # ------------------------------------------------------------------
    Escrever-Titulo "7. Busca, Filtros e Rotas Extras"
    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros?busca=Machado"
    if (Verificar-Status "GET /api/livros?busca=Machado -> 200" $r 200) {
        $achados = @($r.Json).Count
        if ($achados -ge 1) {
            Registrar-Pass "Busca por 'Machado' retornou $achados registro(s)"
        } else {
            Registrar-Fail "Busca por 'Machado' veio vazia"
        }
    }

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros?genero=Romance&autor_id=$($Script:AutorCriadoId)"
    if (Verificar-Status "GET /api/livros?genero=Romance&autor_id=:id -> 200" $r 200) {
        $filtrados = @($r.Json).Count
        if ($filtrados -eq 1) {
            Registrar-Pass "Filtro combinado genero + autor_id retornou exatamente 1 livro"
        } else {
            Registrar-Fail "Esperado 1 livro no filtro combinado" "recebeu $filtrados"
        }
    }

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros?autor_id=abc"
    Verificar-Status "GET /api/livros?autor_id=abc -> 422" $r 422 | Out-Null

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/autores/$($Script:AutorCriadoId)/livros"
    if (Verificar-Status "GET /api/autores/:id/livros -> 200" $r 200) {
        $doAutor = @($r.Json).Count
        if ($doAutor -eq 3) {
            Registrar-Pass "Rota extra listou os 3 livros vinculados ao autor"
        } else {
            Registrar-Fail "Esperado 3 livros do autor" "recebeu $doAutor"
        }
    }

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros/resumo"
    if (Verificar-Status "GET /api/livros/resumo -> 200" $r 200) {
        if ($null -ne $r.Json.total_livros -and $null -ne $r.Json.total_exemplares -and $null -ne $r.Json.total_autores -and $null -ne $r.Json.esgotados -and $null -ne $r.Json.por_genero -and $null -ne $r.Json.por_autor) {
            Registrar-Pass "Resumo contem total_livros, total_exemplares, total_autores, esgotados, por_genero e por_autor"
        } else {
            Registrar-Fail "Estrutura de /api/livros/resumo incompleta" $r.Body
        }
    }

    # ------------------------------------------------------------------
    # 8. Regra ON DELETE RESTRICT (409) e Limpeza (204 -> 404)
    # ------------------------------------------------------------------
    Escrever-Titulo "8. Regra ON DELETE RESTRICT (409) e Exclusao (204)"
    $r = Chamar-Api -Metodo "DELETE" -Caminho "/api/autores/$($Script:AutorCriadoId)"
    Verificar-Status "DELETE /api/autores/:id com livros vinculados -> 409" $r 409 | Out-Null

    foreach ($lid in @($Script:LivrosCriadosIds)) {
        $r = Chamar-Api -Metodo "DELETE" -Caminho "/api/livros/$lid"
        if (Verificar-Status "DELETE /api/livros/$lid -> 204" $r 204) {
            $Script:LivrosCriadosIds.Remove($lid) | Out-Null
        }
    }

    $r = Chamar-Api -Metodo "GET" -Caminho "/api/livros/$idLivro1"
    Verificar-Status "GET livro excluido -> 404" $r 404 | Out-Null

    $r = Chamar-Api -Metodo "DELETE" -Caminho "/api/autores/$($Script:AutorCriadoId)"
    if (Verificar-Status "DELETE /api/autores/:id sem livros -> 204" $r 204) {
        $idTempAutor = $Script:AutorCriadoId
        $Script:AutorCriadoId = $null
        $r = Chamar-Api -Metodo "GET" -Caminho "/api/autores/$idTempAutor"
        Verificar-Status "GET autor excluido -> 404" $r 404 | Out-Null
    }

    # ------------------------------------------------------------------
    # 9. Documentacao e Entrega (Checklist do Professor)
    # ------------------------------------------------------------------
    Escrever-Titulo "9. Documentacao e Entrega"
    if ((Test-Path "README.md") -and (Test-Path "APRESENTACAO.md")) {
        Registrar-Pass "README.md e APRESENTACAO.md presentes em Projeto-Biblioteca-Equipe1/"
    } else {
        Registrar-Fail "README.md ou APRESENTACAO.md ausente"
    }

    $equipeMdPath = Join-Path $PastaRaiz "projetos\EQUIPE.md"
    if (Test-Path $equipeMdPath) {
        $equipeTexto = Get-Content -Path $equipeMdPath -Raw -Encoding UTF8
        if ($equipeTexto -match "\[Preencher") {
            Registrar-Aviso "projetos/EQUIPE.md ainda contem campos [Preencher] dos demais integrantes"
        } else {
            Registrar-Pass "projetos/EQUIPE.md totalmente preenchido"
        }
    } else {
        Registrar-Fail "projetos/EQUIPE.md nao encontrado"
    }

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $tags = & git -C $PastaRaiz tag -l "projeto-final" 2>$null
        if ($tags -match "projeto-final") {
            Registrar-Pass "Tag Git 'projeto-final' criada"
        } else {
            Registrar-Aviso "Tag Git 'projeto-final' ainda nao foi criada (criar antes da entrega final)"
        }
    }
} finally {
    # Garantia de limpeza caso algum teste intermediario falhe
    foreach ($lid in @($Script:LivrosCriadosIds)) {
        try { Chamar-Api -Metodo "DELETE" -Caminho "/api/livros/$lid" | Out-Null } catch {}
    }
    if ($null -ne $Script:AutorCriadoId) {
        try { Chamar-Api -Metodo "DELETE" -Caminho "/api/autores/$($Script:AutorCriadoId)" | Out-Null } catch {}
    }
    Pop-Location
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host ("  RESULTADO FINAL: {0} passaram | {1} falharam | {2} avisos" -f $Script:Passou, $Script:Falhou, $Script:Avisos) -ForegroundColor White
Write-Host "============================================================" -ForegroundColor White

if ($Script:Falhou -gt 0) {
    exit 1
}
exit 0
