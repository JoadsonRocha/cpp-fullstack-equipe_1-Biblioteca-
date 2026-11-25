# Multi-stage build para a API em C++17 da Biblioteca
FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends g++ libmariadb-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY libs ./libs
COPY src ./src
COPY build.sh ./

RUN sed -i 's/\r$//' build.sh && chmod +x build.sh && ./build.sh

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libmariadb3 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /app/build/servidor ./servidor
COPY public ./public

EXPOSE 8080
CMD ["./servidor"]
