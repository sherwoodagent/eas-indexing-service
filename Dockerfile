# node 20, not upstream's 18: transitive deps (brace-expansion@5) now require
# "20 || >=22" and the image fails `yarn install` on 18.
FROM node:20-alpine
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
RUN apk update && apk add --no-cache postgresql-client
RUN chmod +x /app/entrypoint.sh
RUN yarn install
ENTRYPOINT ["/app/entrypoint.sh"]
EXPOSE 4000
