# Home Assistant Matter Hub - AI Coding Agent Instructions

## Project Overview
Home Assistant Matter Hub bridges Home Assistant entities to Matter-compatible controllers (Alexa, Apple Home, Google Home) using local Matter protocol communication. **Note: Project entered maintenance mode (Jan 2026)** - focus on stabilization and bug fixes.

## Architecture

### Monorepo Structure
- **`packages/backend`**: Node.js CLI + REST API, Matter protocol, Home Assistant integration
- **`packages/common`**: Shared TypeScript types, schemas, data models
- **`packages/frontend`**: React UI for bridge management (Vite + MUI)
- **`apps/home-assistant-matter-hub`**: Packaging (Docker, standalone bundles)
- **`docs`**: Myst-based documentation

### Dependency Injection via Matter.js Environment
- **AppEnvironment** (`packages/backend/src/core/ioc/app-environment.ts`): Root container, manages global services (logging, storage, HA client, bridges)
- **BridgeEnvironment**: Isolated per-bridge container extending AppEnvironment, manages bridge-specific services (endpoints, entity tracking)
- **Service base class** (`packages/backend/src/core/ioc/service.ts`): All services extend this, support lifecycle (`initialize()`, `dispose()`)
- Pattern: `Environment.get(ServiceClass)` retrieves singletons; `Environment.load(ServiceClass)` awaits async initialization

### Critical Service Layer
- **BridgeService**: CRUD + lifecycle management for bridges; persists to storage
- **HomeAssistantClient**: WebSocket connection to HA, entity state monitoring via RxJS
- **BridgeEndpointManager**: Creates Matter device endpoints from HA entities (domain+type mapping in `@home-assistant-matter-hub/common`)
- **WebApi (Express)**: REST endpoints for bridge management, uses basic auth if configured
- **BridgeStorage**: JSON-based persistence with migration chain (v1→v2→v3→v4→v5)

## Key Patterns & Conventions

### Data Flow
1. **Entity Selection**: User configures filters in UI → stored in BridgeData
2. **Endpoint Generation**: BridgeEndpointManager reads BridgeRegistry (tracks HA entities) → creates Matter endpoints per entity
3. **State Sync**: HomeAssistantRegistry observes HA entity state changes → triggers endpoint attribute updates via `applyPatchState()`
4. **Actions**: Matter controller sends commands → WebApi proxies to HomeAssistantClient → HA service calls

### Naming Conventions
- Services suffixed with `Service` (BridgeService, etc.)
- Factories end with `Factory` (BridgeFactory, BridgeEnvironmentFactory)
- Registries track collections (BridgeRegistry, HomeAssistantRegistry)
- Data providers use `DataProvider` (BridgeDataProvider holds immutable config)
- Test files: `*.test.ts` with Vitest

### Type Safety
- All REST API schemas in `packages/common/src/schemas/` validated with Ajv
- Bridge config stored as typed `BridgeData` interface
- Home Assistant domains/clusters mapped in `packages/common/src/domains/` and `packages/common/src/clusters/`

## Developer Workflows

### Local Development
```bash
# Install & setup monorepo
pnpm install

# Develop backend with hot-reload
pnpm serve

# Or start frontend dev server (proxies to backend at :8482)
pnpm run -w --filter @home-assistant-matter-hub/frontend serve

# Run all tests
pnpm test

# Lint & format
pnpm lint:fix
```

### Build & Release
- **Backend**: TypeScript → esbuild bundled ESM (see `packages/backend/bundle.js`)
- **Frontend**: Vite builds to `packages/backend/frontend/` (embedded in backend binary)
- **Common**: Built first as prerequisite (`pnpm build:minimum`)
- Release workflow: `pnpm release` (semantic-release), version bump, pack, publish to npm

### Testing
- Framework: **Vitest** (configured per package)
- Pattern: Unit tests colocated (`*.test.ts`), no separate test folder
- Run specific package: `pnpm --filter @home-assistant-matter-hub/backend run test`

### Code Quality
- **Biome** linter/formatter (line width: 80, space indent: 2)
- Rule: `@mui/material` imports must use path imports (e.g., `import Alert from '@mui/material/Alert'`)
- No unused imports (`noUnusedImports: "error"`)
- Run: `pnpm lint:fix`

## Critical Integration Points

### Home Assistant API
- **Connection**: `home-assistant-js-websocket` with access token (env: `HAMH_HOME_ASSISTANT_ACCESS_TOKEN`)
- **State polling**: Configurable refresh interval (default/env: `HAMH_HOME_ASSISTANT_REFRESH_INTERVAL`)
- **Service calls**: HomeAssistantActions invokes `light.turn_on`, etc. via WebSocket

### Matter Protocol
- **Library**: @matter/main, @matter/nodejs, @matter/general (v0.16.7)
- **Node structure**: Each bridge creates a Matter server node with aggregator endpoint containing child endpoints for entities
- **Cluster mapping**: `packages/common/src/clusters/` defines supported clusters per entity type (BooleanState, ColorControl, DoorLock, FanControl, etc.)

### Storage & Migrations
- **Location**: `~/.home-assistant-matter-hub` (configurable via `HAMH_STORAGE_LOCATION`)
- **Format**: Matter.js custom storage provider managing namespaced contexts
- **Bridge config**: JSON with versioned schema, auto-migrate on load (`packages/backend/src/services/storage/migrations/bridge/`)

## Common Tasks

### Adding a New Cluster Type
1. Define cluster behavior in `packages/common/src/clusters/my-cluster.ts`
2. Add domain mapping in `packages/common/src/domains/`
3. Implement endpoint creation logic in BridgeEndpointManager
4. Test with Vitest

### Modifying Bridge Config Schema
1. Update `BridgeData` type in `packages/common/src/bridge-data.ts`
2. Create new migration file `v*-to-v*.ts`
3. Chain migration in `BridgeStorage` constructor

### API Endpoint Changes
1. Update schema in `packages/common/src/schemas/`
2. Modify WebApi route handler in `packages/backend/src/api/web-api.ts`
3. Update frontend Redux state if needed

## Gotchas & Important Notes
- **RxJS observables**: HomeAssistantClient uses RxJS; avoid `.subscribe()` without cleanup
- **Async init**: Services with `construction` promise must be awaited via `Environment.load()`
- **Bridge disposal**: Always call bridge.dispose() before removing from storage
- **Config immutability**: BridgeDataProvider holds read-only config; use BridgeStorage for mutations
- **Storage version**: Current bridge storage is v5; v1-v4 auto-migrate; check migrations if schema changes
