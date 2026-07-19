# 🚑 BSRP Ambulance Job

A modern emergency medical service system built exclusively for the **BSRP Framework**.

BSRP Ambulance Job provides a complete EMS experience, allowing medical personnel to respond to emergencies, provide patient care, and manage ambulance operations while integrating directly with the BSRP ecosystem. Designed for immersive roleplay, performance, and reliability, it serves as the foundation for emergency medical services across BSRP resources.

---

## Features

* 🚑 EMS job system
* 🏥 Medical response system
* 👨‍⚕️ EMS duty management
* 🚨 Emergency call response
* 🩺 Patient treatment system
* 💉 Medical interactions
* 🚑 Ambulance vehicle support
* 📍 Hospital integration
* ⚡ Optimized performance
* 🔗 Full BSRP Framework integration

---

## Framework Requirements

This resource requires:

* BSRP Framework
* oxmysql
* ox_lib

Recommended:

* ox_inventory
* bsrp-characters
* bsrp-phone
* bsrp-dispatch
* bsrp-vehicles

---

## Installation

### 1. Place Resource

```text
resources/
└── bsrp-ambulancejob/
```

### 2. Ensure Dependencies

```cfg
ensure oxmysql
ensure ox_lib

ensure bsrp
ensure bsrp-ambulancejob
```

> BSRP Ambulance Job must start after the `bsrp` core resource.

---

## Database

Import the provided SQL file if included:

```sql
sql/bsrp-ambulancejob.sql
```

If automatic database initialization is enabled, required tables will be created automatically.

---

## Configuration

Configuration options can be found in:

```text
config.lua
```

Available settings may include:

* EMS job settings
* Ambulance locations
* Hospital locations
* Medical items
* Treatment options
* Vehicle settings
* Permissions
* Notification settings

---

## EMS System

### Medical Response

EMS members can:

* Respond to emergency calls
* Locate injured players
* Provide medical assistance
* Transport patients
* Complete medical reports

---

### Patient Treatment

EMS members can:

* Assess patient conditions
* Perform medical actions
* Stabilize injured players
* Provide emergency care
* Transport patients to hospitals

---

### Ambulance Operations

Supports:

* Ambulance vehicles
* Emergency response
* Hospital services
* EMS equipment
* Medical roleplay interactions

---

## Medical Data

Patient information may include:

* Character Identifier
* Patient Status
* Injuries
* Treatment Records
* Medical Actions
* Transport Information

---

## Framework Integration

### Get Player

```lua
local player = exports.bsrp:GetPlayer(source)

if player then
    print(player.PlayerData.citizenid)
end
```

---

### Check EMS Job

```lua
if player.PlayerData.job.name == "ambulance" then
    -- EMS actions
end
```

---

### Check Character Loaded

```lua
if player and player.loaded then
    -- Character is active
end
```

---

## Ambulance Events

Example usage:

```lua
RegisterNetEvent('bsrp:patientTreated', function()
    print('Patient treatment completed.')
end)
```

```lua
RegisterNetEvent('bsrp:emsDutyChanged', function(state)
    print('EMS duty status:', state)
end)
```

> Event names may vary depending on implementation.

---

## Permissions

Administrative EMS actions can utilize the BSRP permission system:

```lua
if exports.bsrp:IsAdmin(source, 2) then
    -- EMS administration actions
end
```

---

## Compatibility

| Resource          | Supported |
| ----------------- | --------- |
| BSRP Framework    | ✅         |
| oxmysql           | ✅         |
| ox_lib            | ✅         |
| ox_inventory      | ✅         |
| bsrp-characters   | ✅         |
| bsrp-phone        | ✅         |
| bsrp-dispatch     | ✅         |
| bsrp-vehicles     | ✅         |

---

## EMS Lifecycle

### Player Joins

1. Player connects to the server
2. Character data loads
3. EMS job information is synchronized
4. Medical services become available

---

### Emergency Response

1. Emergency call is received
2. EMS unit responds
3. Patient location is identified
4. Medical treatment is provided
5. Patient is transported if required

---

### Data Saving

EMS information is saved during:

* Patient interactions
* Character switching
* Player logout
* Server restart

---

## Development

When creating resources that depend on EMS data:

```lua
local player = exports.bsrp:GetPlayer(source)

if not player then
    return
end

if player.PlayerData.job.name == "ambulance" then
    -- EMS resource logic
end
```

Always verify player permissions and medical actions server-side before processing EMS operations.
