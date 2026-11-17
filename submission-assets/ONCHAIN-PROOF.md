# PayLink — On-chain proof pack (QDay Aevum testnet, chain 44005)

All values below were read back from the chain / explorer API on 2026-11-17
after the run — not copied from transaction submissions.

## Addresses

| Role | Address |
|---|---|
| PayLink (production, evm_version=shanghai) | `0x938E4882443ec1AD1F5af36D19D72aa2f8e521c7` |
| PayLink (superseded first deployment, Cancun build — `getRequest` reverts on Aevum with `invalid opcode: MCOPY`) | `0x9aB9C2C3C4F667ba9F0358F9B87FE4e83bFBeC88` |
| tUSD8 (official) | `0x456569838f1d43009A91ebA4263147Afd7233483` — `decimals()` read from the contract = **6** (an explorer token page said 18; the contract wins) |
| Merchant / deployer | `0x5A9ee0aBf4ff8f22937AA2b349615Ca4fEf12cDC` |
| Payer | `0x17D6804916676240E0363B4E33a05FD6B61eC20E` |

## Transactions (every one confirmed status = 1 via the explorer API)

| # | Step | Tx hash | Block |
|---|---|---|---|
| 0 | Gas funding: merchant → payer 0.1 tQDAY | `0x79fc19d9c65d6ecc0be076fe0b4a7b69685a3820585da3023e075e70fa1cbea5` | 3400948 |
| 1 | Deploy PayLink (production) | `0x3c49cdd5de3513aef9f90e3e3c8f07436ab1049977fbc7be7b3f09ed1d88e05c` | 3401223 |
| 2 | Merchant `createRequest(500000, "Invoice #1 - demo coffee")` → request #1 | `0xfa213fcdad0c25652d599ef8a3e4742840fda13c36291ac9bae1e6fe95050a8b` | 3401282 |
| 3 | Payer `approve(PayLink, 500000)` | `0x54b9be6038d92a566e602b01a272a5de8d9e6997db9e39415e062ded07612302` | 3401344 |
| 4 | Payer `pay(1)` | `0x469190b4a7967a9aa11acb1bbdf158971dcd16898c58a92529b87b3c0cf51d75` | 3401371 |

Explorer links: `https://explorer-test.qday.info/tx/<hash>` ·
contract: https://explorer-test.qday.info/address/0x938E4882443ec1AD1F5af36D19D72aa2f8e521c7

## State read back after the run

- `PayLink.token()` = tUSD8 address ✓
- `getRequest(1)` before pay: `(merchant, 500000, "Invoice #1 - demo coffee", 0x0, paid=false, cancelled=false)`
- `getRequest(1)` after pay: `(merchant, 500000, "Invoice #1 - demo coffee", payer, paid=true, cancelled=false)`
- Pay tx logs: `RequestPaid(1, payer, 500000)` + tUSD8 `Transfer(payer → merchant, 500000)` ✓
- tUSD8 balances (explorer API): merchant = 1,000,000 raw total (0.5 from the
  superseded deployment's identical e2e run + 0.5 from the production run);
  payer = 0 (started with the 1.0 tUSD8 faucet drip; spent exactly 2 × 0.5) ✓

## Bytecode identity

Deployed runtime bytecode at the production address equals the local build of
`src/PayLink.sol` under the committed `foundry.toml` (solc 0.8.26, optimizer
200 runs, evm_version shanghai), compared byte-for-byte after normalising the
immutable tUSD8 address word. Explorer source verification was attempted twice
(forge `verify-contract`, GUID `938e…6afc3698`; manual v1 API with explicit
`evmversion=shanghai`, GUID `938e…6afc375a`) and both times the explorer
returned "Fail - Unable to verify"; the explorer's verified-contract list is
empty instance-wide (the official tUSD8 is not verified either), so the
bytecode-identity check above is the verification of record.

## Screenshots / video

Not captured in the build environment: its headless Chromium cannot traverse
the sandbox egress proxy (`ERR_TUNNEL_CONNECTION_FAILED` for every page;
curl/cast traffic is unaffected). The tightened, ready-to-shoot recording
script with all real URLs/amounts is in the workspace `demo/DEMO-SCRIPT.md`
(6 shots, ≈3 minutes to record in any normal browser before submission).
