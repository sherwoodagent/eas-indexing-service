# Sherwood fork — EAS indexer for Robinhood Chain

Fork of [`ethereum-attestation-service/eas-indexing-service`](https://github.com/ethereum-attestation-service/eas-indexing-service),
adding Robinhood Chain mainnet (4663). Design: `docs/superpowers/specs/2026-08-26-eas-robinhood-mainnet-design.md`
in `sherwoodagent/sherwood` (§7). Deployed EAS: `sherwoodagent/sherwood-protocol#278`.

## Why a fork rather than a subgraph

The GraphQL surface here is `typegraphql-prisma`-generated, which is where easscan's query
shape comes from. Sherwood's app (`app/src/lib/eas-queries.ts`) and CLI (`cli/src/lib/eas.ts`)
already emit exactly that shape, so they work against this service unchanged — only the URL
moves. A subgraph would have preserved field names but not query syntax.

The Graph's networks registry also lists Robinhood Chain with an EMPTY `services.subgraphs`,
so the decentralized network cannot serve a subgraph for 4663 at all.

## Divergence from upstream

| Change | Why |
|---|---|
| `chainConfigs.ts`: chain 4663 entry | EAS is not a predeploy on an Orbit chain; Sherwood deployed it |
| `chainConfigs.ts`: `rpcProvider` from `ROBINHOOD_RPC_URL` | Upstream hardcodes per-chain provider URLs with embedded keys |
| `utils.ts`: throw when that env var is missing | Otherwise a blank URL builds a provider that fails obscurely at first poll |
| `Dockerfile`: pass through the new env vars | Upstream only declares its own per-chain keys |
| `railway.json` | Deployment target |

No event signatures were changed: every signature upstream listens for is byte-identical to
EAS v1.4.0, including the V2 `Registered(bytes32,address,(bytes32,address,bool,string))`.

## `contractStartBlock` is exclusive

`utils.ts` scans from `fromBlock + 1`, so the config value is the block **before** the first
one you want indexed. Ours is `47096605`; the deploy landed in `47096606-47096607`.

Get this wrong and the failure is loud but confusing: `Attestation.schemaId` is a Prisma FK to
`Schema.id`, so skipping the `Registered` events makes every later attestation insert die with
`Attestation_schemaId_fkey`. Verified by reproducing it.

## Env

```
DATABASE_URL=postgresql://…
CHAIN_ID=4663
ROBINHOOD_RPC_URL=https://robinhood-mainnet.g.alchemy.com/v2/<key>
DISABLE_LISTENER=true     # the ethers filter listener is wrong for 100ms blocks
POLLING_INTERVAL=15000
BATCH_SIZE=5000
```

`DISABLE_LISTENER=true` matters: Robinhood produces ~10 blocks/second, so the event-filter
subscription upstream opens alongside the poller is the wrong shape. Poll instead.

## Verified locally

Against a clean Postgres, chain 4663: all six Sherwood schemas index with correct UIDs,
revocability, and `resolver = 0`; backfill from the deploy block to head (~620k blocks) runs
at ~15–19k blocks/s. Attestation decode was proven against an unrelated EAS deployment on the
same chain — `decodedDataJson` populates. The app's exact query runs unmodified:

```graphql
attestations(where: { schemaId: { equals: $s }, recipient: { equals: $r } }
             orderBy: [{ time: desc }] take: 50) { id attester recipient time data txid revoked }
```
