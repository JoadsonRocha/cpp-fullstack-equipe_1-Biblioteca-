-- schema.sql - Cria o banco de dados do projeto Biblioteca (autores + livros).
--
-- Este arquivo é executado AUTOMATICAMENTE pelo Docker, uma única vez, quando o container do banco é criado
-- pela primeira vez (volume vazio):   docker compose up -d --wait
--
-- Depois de alterar este arquivo, aplique de novo apagando os dados do container e subindo outra vez:
--     docker compose down -v
--     docker compose up -d --wait

SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS projeto_iteam
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE projeto_iteam;

-- ===================== Projeto Final: Biblioteca =====================
-- Entidade de apoio: autores (nome UNICO).
-- Entidade principal: livros (cada livro pertence a um autor).

CREATE TABLE IF NOT EXISTS autores (
    id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nome          VARCHAR(100)  NOT NULL,
    nacionalidade VARCHAR(50)   NULL,
    criado_em     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_autores_nome (nome)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS livros (
    id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    titulo         VARCHAR(150)  NOT NULL,
    autor_id       INT UNSIGNED  NOT NULL,
    genero         VARCHAR(50)   NULL,
    ano_publicacao SMALLINT      NULL,
    isbn           VARCHAR(20)   NULL,
    exemplares     INT           NOT NULL DEFAULT 1,
    criado_em      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_livros_isbn (isbn),
    CONSTRAINT fk_livros_autor FOREIGN KEY (autor_id) REFERENCES autores (id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_livros_ano CHECK (ano_publicacao IS NULL OR ano_publicacao BETWEEN 1000 AND 2100),
    CONSTRAINT ck_livros_exemplares CHECK (exemplares >= 0)
) ENGINE = InnoDB;

-- Dados de exemplo (executados apenas se as tabelas estiverem vazias).
INSERT INTO autores (nome, nacionalidade)
SELECT * FROM (
    SELECT 'Machado de Assis' AS nome, 'Brasileira' AS nacionalidade
    UNION ALL SELECT 'Clarice Lispector', 'Brasileira'
    UNION ALL SELECT 'George Orwell', 'Britânica'
    UNION ALL SELECT 'Gabriel García Márquez', 'Colombiana'
    UNION ALL SELECT 'J. R. R. Tolkien', 'Britânica'
) AS exemplo
WHERE NOT EXISTS (SELECT 1 FROM autores);

INSERT INTO livros (titulo, autor_id, genero, ano_publicacao, isbn, exemplares)
SELECT l.titulo, a.id, l.genero, l.ano_publicacao, l.isbn, l.exemplares
FROM (
    SELECT 'Machado de Assis' AS autor, 'Dom Casmurro' AS titulo, 'Romance' AS genero, 1899 AS ano_publicacao, '9788535910663' AS isbn, 3 AS exemplares
    UNION ALL SELECT 'Machado de Assis', 'Memórias Póstumas de Brás Cubas', 'Romance', 1881, '9788535911660', 2
    UNION ALL SELECT 'Machado de Assis', 'O Alienista', 'Conto', 1882, NULL, 1
    UNION ALL SELECT 'Clarice Lispector', 'A Hora da Estrela', 'Romance', 1977, '9788532530875', 4
    UNION ALL SELECT 'Clarice Lispector', 'Laços de Família', 'Conto', 1960, NULL, 0
    UNION ALL SELECT 'George Orwell', '1984', 'Distopia', 1949, '9788535914849', 5
    UNION ALL SELECT 'George Orwell', 'A Revolução dos Bichos', 'Ficção Política', 1945, '9788535909555', 2
    UNION ALL SELECT 'Gabriel García Márquez', 'Cem Anos de Solidão', 'Realismo Mágico', 1967, '9788501012074', 3
    UNION ALL SELECT 'J. R. R. Tolkien', 'O Hobbit', 'Fantasia', 1937, '9788595084742', 0
    UNION ALL SELECT 'J. R. R. Tolkien', 'O Senhor dos Anéis: A Sociedade do Anel', 'Fantasia', 1954, '9788595084759', 2
) AS l
JOIN autores a ON a.nome = l.autor
WHERE NOT EXISTS (SELECT 1 FROM livros);

ALTER TABLE autores AUTO_INCREMENT = 1;
ALTER TABLE livros AUTO_INCREMENT = 1;
