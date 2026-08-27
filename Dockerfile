# node 20, not upstream's 18: transitive deps (brace-expansion@5) now require
# "20 || >=22" and the image fails `yarn install` on 18.
#
# Debian slim, not Alpine: Prisma 4.13's query/migration engines link against
# OpenSSL 1.1, and current Alpine ships OpenSSL 3. On alpine the engine fails to
# load and every `prisma db push` dies with
#   "Could not parse migration engine response: ... 'Error load'... is not valid JSON"
# Debian bookworm has an engine target Prisma 4.13 supports.
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production

ENV DATABASE_URL=${DATABASE_URL}
ENV INFURA_API_KEY=${INFURA_API_KEY}
ENV ALCHEMY_ARBITRUM_API_KEY=${ALCHEMY_ARBITRUM_API_KEY}
ENV ALCHEMY_SEPOLIA_API_KEY=${ALCHEMY_SEPOLIA_API_KEY}
ENV ALCHEMY_OPTIMISM_GOERLI_API_KEY=${ALCHEMY_OPTIMISM_GOERLI_API_KEY}
ENV CHAIN_ID=${CHAIN_ID}
# Robinhood Chain reads its endpoint from the environment — see chainConfigs.ts.
ENV ROBINHOOD_RPC_URL=${ROBINHOOD_RPC_URL}
ENV DISABLE_LISTENER=${DISABLE_LISTENER}
ENV POLLING_INTERVAL=${POLLING_INTERVAL}

COPY . .

COPY entrypoint.sh /app/entrypoint.sh
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client openssl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN chmod +x /app/entrypoint.sh
RUN yarn install
ENTRYPOINT ["/app/entrypoint.sh"]
EXPOSE 4000
