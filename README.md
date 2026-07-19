# bsrp-ambulancejob

EMS / death / laststand system for **BSRP** (no `qb-core`).

## Stack

| Resource | Role |
|----------|------|
| `bsrp` | Framework (jobs, duty, money, metadata) |
| `ox_inventory` | Lockers, first aid, bandage consume |
| `ox_target` | Hospital / garage targets |
| `ox_lib` | Menus / progress |
| `ps-dispatch` | **Optional** injured / deceased / EMS-down alerts |
| `ps-mdt` | **Optional** MDT from EMS menu |

`ps-dispatch` and `ps-mdt` are **not** hard dependencies.

## server.cfg

```cfg
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure bsrp
ensure bsrp-ambulancejob
# optional:
# ensure ps-dispatch
# ensure ps-mdt
```

## Features

- Laststand → death timers with futuristic death HUD
- G request help (soft dispatch + on-duty EMS notify)
- Hold E to respawn / give up → hospital bed treatment
- Check-in when few medics online (bills bank/cash)
- EMS duty, locker, garage, helicopter
- Revive / heal / status / put in vehicle
- F6 EMS menu + player ox_target
- Soft `ps-dispatch` InjuriedPerson / DeceasedPerson / EmsDown

## Commands

| Command | Who |
|---------|-----|
| `/emsmenu` or **F6** | EMS menu |
| `/revive [id]` | Admin full revive, or EMS interaction |

## Items

`firstaid`, `bandage`, `painkillers` (see ox_inventory items).
