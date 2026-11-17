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
| PayLink deployment | `0x938E4882443ec1AD1F5af36D19D72aa2f8e521c7` ([explorer](https://explorer-test.qday.info/address/0x938E4882443ec1AD1F5af36D19D72aa2f8e521c7)) |
| Live dApp | https://zhanghaozhi001.github.io/aevum-paylink/ (defaults to the deployment above; override with `?contract=<address>`, payers use `&pay=<id>`) |

## Deployment & on-chain proof (Aevum testnet, 2026-11-17)

End-to-end run with two wallets — merchant `0x5A9e…2cDC`, payer `0x17D6…20E`:

| Step | Tx | Result |
|---|---|---|
| Deploy PayLink | [0x3c49…e05c](https://explorer-test.qday.info/tx/0x3c49cdd5de3513aef9f90e3e3c8f07436ab1049977fbc7be7b3f09ed1d88e05c) | contract created |
| Merchant creates request #1 (0.5 tUSD8, "Invoice #1 - demo coffee") | [0xfa21…0a8b](https://explorer-test.qday.info/tx/0xfa213fcdad0c25652d599ef8a3e4742840fda13c36291ac9bae1e6fe95050a8b) | `RequestCreated(1, …, 500000, …)` |
| Payer approves 0.5 tUSD8 | [0x54b9…2302](https://explorer-test.qday.info/tx/0x54b9be6038d92a566e602b01a272a5de8d9e6997db9e39415e062ded07612302) | allowance = 500000 |
| Payer pays request #1 | [0x4691…1d75](https://explorer-test.qday.info/tx/0x469190b4a7967a9aa11acb1bbdf158971dcd16898c58a92529b87b3c0cf51d75) | `RequestPaid` + tUSD8 Transfer payer → merchant, exactly 500000 |

Final state, read back on-chain: `getRequest(1)` = merchant `0x5A9e…2cDC`, amount
500000, memo "Invoice #1 - demo coffee", payer `0x17D6…20E`, **paid = true**.
Full evidence pack: [`submission-assets/ONCHAIN-PROOF.md`](submission-assets/ONCHAIN-PROOF.md).

**Build note (chain compatibility).** The first deployment (solc default EVM target,
Cancun) worked for writes, but `getRequest` reverted in `eth_call` with
`invalid opcode: MCOPY` — Aevum's EVM does not implement the Cancun MCOPY opcode.
The production deployment above is therefore compiled with `evm_version = "shanghai"`
(pinned in `foundry.toml`), and every function — reads included — is verified working
on-chain. The superseded Cancun deployment is `0x9aB9…eC88`.

**Source verification.** The explorer's verification service currently verifies
*nothing* — its verified-contract list is empty, including the official tUSD8 token
(checked 2026-11-17); two correctly formed submissions (forge + manual API with
`evmversion=shanghai`) both returned "Fail - Unable to verify". As a substitute
proof, the deployed runtime bytecode matches the local build of this exact source
byte-for-byte (compared with the immutable token address normalised) — anyone can
reproduce: `forge build` with the committed `foundry.toml`, then compare
`out/PayLink.sol/PayLink.json` `deployedBytecode` against `cast code <address>`.

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
