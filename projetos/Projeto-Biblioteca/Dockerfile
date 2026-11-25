# Multi-stage build para a API em C++17 da Biblioteca:
# estágio 1 compila com g++ e libmariadb-dev; estágio 2 copia só o binário final e os arquivos estáticos.
FROM debian:bookworm-slim AS builder

# Ferramentas de compilação e cabeçalhos do MariaDB Connector/C
RUN apt-get update && \
    apt-get install -y --no-install-recommends g++ libmariadb-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY libs ./libs
COPY src ./src
COPY build.sh ./

# Remove possíveis quebras de linha CRLF do Windows antes de executar o script no Linux
RUN sed -i 's/\r$//' build.sh && chmod +x build.sh && ./build.sh

# Imagem final enxuta apenas com a biblioteca de runtime do MariaDB
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libmariadb3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/build/servidor ./servidor
COPY public ./public

EXPOSE 8080
CMD ["./servidor"]
