# Brainrot Diner Tycoon — Setup Guide

## Prerequisites

- Roblox Studio (already installed)
- [Rojo](https://rojo.space/) — syncs this repo into Studio in real time

---

## 1. Install Rojo

### Rojo CLI (one-time)

```bash
# with Foreman (recommended)
foreman install
# OR via aftman
aftman install
```

If you don't have Foreman/Aftman yet:

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Roblox/foreman/main/install.sh | bash
# Windows: download from https://github.com/Roblox/foreman/releases
```

Then install Rojo:

```bash
# aftman.toml is already configured; just run:
aftman install
```

### Rojo Studio Plugin (one-time)

1. Open Roblox Studio
2. Go to **Plugins → Manage Plugins → Search "Rojo"**
3. Install the official Rojo plugin

---

## 2. Sync the Project

```bash
# In the repo root:
rojo serve default.project.json
```

Then in Studio: **Plugins → Rojo → Connect** (it auto-detects localhost:34872).

---

## 3. Add Placeholder Models to ServerStorage

Rojo doesn't auto-create 3D models — you need to add them in Studio manually:

1. In Studio's **Explorer**, add a `Folder` under `ServerStorage` named `EmployeeModels`.
2. Inside it, create 3 `Model` objects named exactly:
   - `tung_tung_sahur`
   - `tralalero_tralala`
   - `ballerina_cappuccina`
3. Add a `Folder` named `FurnitureModels` with `Part` objects for each furniture type
   (or leave them out — the code uses colored brick fallbacks automatically).
4. Add a `Folder` named `CustomerModels` with models for each customer type (optional).

---

## 4. Set Real Developer Product / Game Pass IDs

Open `src/ServerScriptService/PurchaseHandler.server.lua` and replace the
placeholder IDs in `DEV_PRODUCT_IDS` and `GAMEPASS_IDS` with the real IDs
from your Roblox Creator Dashboard.

---

## 5. Playtesting

- Press **Play** in Studio to test locally.
- Press **Play Here** → **Start Server** to test multiplayer with 2+ clients.

---

## File Map

```
src/
├── ReplicatedStorage/Modules/   — Shared Lua modules (constants, helpers)
├── ServerScriptService/         — Server scripts (game logic, AI, data)
└── StarterGui/                  — Client scripts (HUD, menus, building)
```

## Key Remotes (all under ReplicatedStorage/Remotes)

| Name              | Type             | Direction        | Purpose                         |
|-------------------|------------------|------------------|---------------------------------|
| UpdateBalance     | RemoteEvent      | Server → Client  | Push new IGC balance            |
| SpendMoney        | RemoteEvent      | Client → Server  | Request a spend                 |
| PlaceObject       | RemoteFunction   | Client → Server  | Place furniture (validated)     |
| DeleteObject      | RemoteEvent      | Client → Server  | Delete placed object            |
| Expand            | RemoteFunction   | Client → Server  | Buy expansion                   |
| HireEmployee      | RemoteEvent      | Client → Server  | Hire an employee                |
| FireEmployee      | RemoteEvent      | Client → Server  | Fire an employee                |
| UpdateLeaderboard | RemoteEvent      | Server → Client  | Push leaderboard data           |
| Notification      | RemoteEvent      | Server → Client  | Toast messages                  |
| GetPlayerData     | RemoteFunction   | Client → Server  | Fetch initial player data       |
