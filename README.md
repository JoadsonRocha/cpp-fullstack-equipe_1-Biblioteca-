# C++ Full Stack — ITEAM (2º semestre)

**Curso de Capacitação em Desenvolvimento Full Stack – ITEAM · Módulo 08 – Linguagem de Programação C++**  
Professor: Msc. Hygo Sousa De Oliveira

---

## Projeto Final da Equipe — 📚 Biblioteca (Equipe 1)

> Clique abaixo para acessar diretamente o projeto desenvolvido pela equipe, sua documentação completa e o roteiro da apresentação:

| Acesso rápido | Descrição | Link |
|---|---|---|
| 📚 **Projeto Biblioteca** | Código-fonte completo (C++17, MariaDB, Docker e Front-end) | **[`Projeto-Biblioteca-Equipe1/`](Projeto-Biblioteca-Equipe1/)** |
| 📖 **README do Projeto** | Guia profissional com arquitetura, rotas, exemplos `curl`, Docker e compilação | **[`Projeto-Biblioteca-Equipe1/README.md`](Projeto-Biblioteca-Equipe1/README.md)** |
| 🎤 **Apresentação** | Roteiro de 10–12 min para os 4 integrantes + perguntas e respostas da banca | **[`Projeto-Biblioteca-Equipe1/APRESENTACAO.md`](Projeto-Biblioteca-Equipe1/APRESENTACAO.md)** |
| 👥 **Equipe e Papéis** | Identificação da equipe, divisão de tarefas, decisões e checklist de entrega | **[`projetos/EQUIPE.md`](projetos/EQUIPE.md)** |

---

## Equipes e Entregas

| Equipe | Tema | Pasta do Projeto | Documentação | Situação |
|---|---|---|---|---|
| **Equipe 1** (Joadson Rocha, Eduardo Felipe) | 📚 Biblioteca (`livros` + `autores`) | [`Projeto-Biblioteca-Equipe1/`](Projeto-Biblioteca-Equipe1/) | [README do Projeto](Projeto-Biblioteca-Equipe1/README.md) · [Dados da Equipe](projetos/EQUIPE.md) | Em desenvolvimento / Testes em Docker OK |

---

## Material do Curso (Referência)

O repositório oficial do curso (`Hygo/c--fullstack-iteam-2sem`) é somente para leitura. As instruções de cópia e entrega estão em [COMO-OBTER-AS-ATIVIDADES.md](COMO-OBTER-AS-ATIVIDADES.md) e o cálculo da nota em [AVALIACAO.md](AVALIACAO.md).

| Pasta | Conteúdo | Atividades | Situação |
|-------|----------|------------|----------|
| [`unidade-01/`](unidade-01/) | Introdução ao C++ | 15 (5 🟢 · 5 🟡 · 5 🔴) | Liberado |
| [`unidade-02/`](unidade-02/) | Estruturas de controle | 15 (5 🟢 · 5 🟡 · 5 🔴) | Liberado |
| [`unidade-03/`](unidade-03/) | Funções e ponteiros | 15 (5 🟢 · 5 🟡 · 5 🔴) | Liberado |
| [`unidade-04/`](unidade-04/) | Programação orientada a objetos | 15 (5 🟢 · 5 🟡 · 5 🔴) | Liberado |
| [`unidade-05/`](unidade-05/) | Bibliotecas e recursos avançados | 15 (5 🟢 · 5 🟡 · 5 🔴) | Liberado |
| [`projetos/`](projetos/) | **Material de apoio do projeto final:** guias, starter kit, demo e rubrica | 1 projeto (3 temas) | Liberado |

## Como compilar as atividades

Todos os programas do curso usam **C++17** e devem ser compilados com avisos ativados:

```bash
g++ -std=c++17 -Wall -Wextra programa.cpp -o programa.exe
```

Verifique se o compilador está instalado com `g++ --version`. No Windows, recomendamos o **MSYS2 (UCRT64)**; o passo a passo está em [`projetos/guia/01-preparar-ambiente.md`](projetos/guia/01-preparar-ambiente.md). No VS Code, o atalho **Ctrl+Shift+B** compila o arquivo aberto (tarefa já configurada em `.vscode/tasks.json`).
