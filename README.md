# PayLink — tUSD8 payment links on QDay Aevum

**Entry for the Aevum Builder Challenge #1 (QDay) on DoraHacks.**
Problem: paying someone on a new testnet today means copying addresses and amounts
by hand and hoping the other side sent the right token, the right amount, to the
right address. PayLink turns a payment into a link.

A merchant creates an on-chain **payment request** (amount + memo) in tUSD8, shares
a URL, and the payer opens it, connects a wallet, and pays — the exact amount is
pulled straight from payer to merchant by the contract. The contract never holds
funds, so there is nothing to custody, freeze, or drain.

## How it works

```
Merchant ──createRequest(amount, memo)──▶ PayLink contract (Aevum)
                                              │  emits RequestCreated(id)
Payer opens ?contract=…&pay=<id>              │
Payer ──approve(tUSD8) + pay(id)─────────────▶│  transferFrom(payer → merchant)
                                              └─ marks request paid, emits RequestPaid
Merchant dashboard reads RequestCreated logs + getRequest(id) for live status.
```

## Components

| Piece | Path |
|---|---|
| Payment-request contract | `src/PayLink.sol` |
| Tests (mock tUSD8) | `test/PayLink.t.sol` |
| Deploy script | `script/Deploy.s.sol` |
| Single-file web dApp (merchant + payer) | `web/index.html` |

## Network — QDay Aevum testnet

| Item | Value |
|---|---|
| Chain ID | 44005 (0xABE5) |
| RPC | https://rpc-test.qday.info |
| Explorer | https://explorer-test.qday.info |
| Faucet (tQDAY gas) | https://faucet.qday.info |
| tUSD8 | `0x456569838f1d43009A91ebA4263147Afd7233483` (6 decimals) |
| PayLink deployment | _pending — the on-chain faucet contract is currently paused and the web faucet gates fresh wallets (see the workspace `SUBMIT-CHECKLIST.md`); address recorded here at deploy time_ |
| Live dApp | https://zhanghaozhi001.github.io/aevum-paylink/ (add `?contract=<deployment>`; payers use `&pay=<id>`) |

## Run it

```bash
# tests
forge test

# get testnet gas: open https://faucet.qday.info with a fresh EOA

# deploy to Aevum
forge script script/Deploy.s.sol --rpc-url aevum --broadcast --private-key $PRIVATE_KEY

# verify on the explorer (Blockscout-compatible API) — see explorer-test.qday.info

# use the dApp: serve web/ statically and open
#   index.html?contract=<deployed address>            (merchant view)
#   index.html?contract=<deployed address>&pay=<id>   (payer view)
```

## Design choices

- **No custody**: `pay()` is a direct `transferFrom` payer → merchant. The contract
  stores only request state, eliminating the largest smart-contract risk class.
- **No external dependencies** in the contract (a 3-function ERC-20 interface is
  inlined), so the deployed bytecode is small and the audit surface is one file.
- **One flow, done well**: create → share link → pay → dashboard status, with
  on-chain events as the audit trail (judging criteria: verifiable on-chain
  activity, clear demo, comprehensive docs).

## Roadmap

- Request expiry + partial payments; QR codes for in-person payments.
- Stablecoin-paymaster integration (fees in tUSD8) once QDay ships the tooling.
- Mainnet version for the QDay mainnet launch (Q1 2027), incl. ERC-8004 merchant
  identity.

## License

MIT
