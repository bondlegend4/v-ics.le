# Project Architecture Documentation

## Overview

This project consists of three main components that can operate independently or together:

1. **shared-modelica-components** - Godot addon with physics simulation (standalone or Modbus-enabled)
2. **lunco-sim** - Mars colony simulation game using the addon
3. **V-ICS space-modbus-server** - Industrial control system learning environment

## Repository Structure

```
v-ics.le/
├── shared-modelica-components/          # GitHub addon repository
│   ├── plugin.cfg                       # Godot addon config
│   ├── plugin.gd                        # Addon entry point
│   ├── rust-lib/                        # Rust physics library
│   │   ├── Cargo.toml
│   │   ├── build.rs                     # Compiles Modelica models
│   │   ├── build_models.sh
│   │   ├── models/                      # Modelica source files
│   │   │   ├── SimpleThermalMVP.mo
│   │   │   ├── Habitat.mo
│   │   │   └── SolarPanel.mo
│   │   ├── build/                       # Compiled C code (gitignored)
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── runtime.rs               # Modelica runtime wrapper
│   │       └── components/
│   │           └── thermal_node.rs      # Godot-exposed node
│   ├── bin/                             # Compiled Rust libraries
│   │   ├── libshared_modelica_components.so
│   │   └── libshared_modelica_components.dylib
│   ├── integration/                     # High-level GDScript API
│   │   ├── thermal_component.gd         # Mode-aware wrapper
│   │   └── habitat_component.gd
│   ├── build_addon.sh                   # Build script
│   └── README.md
│
├── V-ICS/
│   └── space-modbus-server/
│       ├── Cargo.toml
│       ├── src/
│       │   ├── main.rs
│       │   └── thermal_registers.rs
│       ├── shared-modelica-components/  # Git submodule (rust-lib only)
│       └── modelica-rust-modbus-server/ # Generic Modbus server
│
└── godot-colony-sim/
    ├── lunco-sim/
    │   ├── addons/
    │   │   └── shared_modelica_components/  # Git submodule (full addon)
    │   ├── apps/
    │   │   └── modelica/
    │   │       ├── systems/             # Game-specific systems
    │   │       │   └── thermal_system.gd
    │   │       └── scenes/              # Test scenes
    │   │           └── thermal_habitat.tscn
    │   └── core/                        # LunCo core
    └── godot-modelica-rust-integration/ # DEPRECATED - no longer needed
```

## Architecture Principles

### 1. Standalone Operation
**lunco-sim can run completely independently:**
- Contains full physics simulation via addon
- No external dependencies required
- Perfect for game development and testing

### 2. Shared Component Library
**shared-modelica-components serves dual purpose:**
- **As Godot addon**: Full plugin with GDScript API
- **As Rust library**: Core physics engine for Modbus server

### 3. Optional Integration
**V-ICS connection is opt-in:**
- Set `mode = MODBUS_CLIENT` to connect to V-ICS
- Set `mode = MODBUS_SERVER` to expose physics via Modbus
- Set `mode = STANDALONE` for no network (default)

## Component Details

### shared-modelica-components (GitHub Addon)

**Purpose:** Reusable physics simulation addon

**Key Features:**
- ✅ **Three operation modes**: Standalone, Modbus Client, Modbus Server
- ✅ **GitHub-hosted**: Easy installation via git submodule
- ✅ **Self-contained**: Includes compiled physics library
- ✅ **Extensible**: Add new Modelica models easily

**Distribution:**
```bash
# Install in any Godot project
git submodule add https://github.com/bondlegend4/shared-modelica-components.git \
    addons/shared_modelica_components
```

**Directory Breakdown:**

- `plugin.cfg` / `plugin.gd` - Godot addon registration
- `rust-lib/` - Physics engine (also used by Modbus server)
- `bin/` - Compiled Rust libraries (.so/.dylib/.dll)
- `integration/` - High-level GDScript components

**Build Process:**
```bash
cd shared-modelica-components
./build_addon.sh
# 1. Compiles Modelica models to C
# 2. Builds Rust library
# 3. Copies library to bin/
```

### lunco-sim (Mars Colony Simulation)

**Purpose:** Standalone game using physics addon

**Key Changes from Old Architecture:**
- ✅ **No embedded models**: Uses addon instead
- ✅ **No build scripts**: Just uses the addon
- ✅ **Simpler structure**: Only game-specific code

**Structure:**
```
lunco-sim/
├── addons/
│   └── shared_modelica_components/      # Git submodule
├── apps/
│   └── modelica/
│       ├── systems/                     # Game systems using components
│       └── scenes/                      # Test/demo scenes
└── core/                                # LunCo core systems
```

**No longer includes:**
- ❌ `apps/modelica/models/` - Moved to addon
- ❌ `apps/modelica/build/` - Moved to addon
- ❌ `apps/modelica/build_models.sh` - Moved to addon
- ❌ `apps/modelica/integration/` - Moved to addon

**Usage:**
```gdscript
# Just use the addon components
var thermal = ThermalComponent.new()
thermal.mode = ThermalComponent.Mode.STANDALONE
add_child(thermal)
```

### V-ICS space-modbus-server

**Purpose:** Industrial control system learning environment

**Key Features:**
- Runs physics simulation
- Exposes via Modbus TCP
- Can be source of truth for lunco-sim

**Uses shared-modelica-components:**
```toml
# Cargo.toml
[dependencies]
shared-modelica-components = { path = "./shared-modelica-components/rust-lib" }
```

**Only uses `rust-lib/` directory:**
- No Godot plugin files needed
- Direct access to physics engine
- Same models as lunco-sim

## Operation Modes

### Mode 1: Standalone lunco-sim

```
┌─────────────────────────────────────┐
│         lunco-sim (Godot)           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ shared_modelica_components    │ │
│  │ (STANDALONE mode)              │ │
│  │                                │ │
│  │  • Runs physics locally        │ │
│  │  • No network required         │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Setup:**
```gdscript
var thermal = ThermalComponent.new()
thermal.mode = ThermalComponent.Mode.STANDALONE  # Default
add_child(thermal)
```

**Use Case:**
- Game development
- Testing
- Offline gameplay
- No ICS learning environment needed

### Mode 2: V-ICS as Source of Truth

```
┌────────────────────────────────┐      ┌─────────────────────────────────┐
│  V-ICS space-modbus-server     │      │      lunco-sim (Godot)          │
│                                │      │                                 │
│  ┌──────────────────────────┐ │      │  ┌───────────────────────────┐ │
│  │ shared-modelica-components│ │      │  │ shared_modelica_components│ │
│  │ (Rust library)            │ │      │  │ (MODBUS_CLIENT mode)      │ │
│  │                           │ │      │  │                           │ │
│  │  • Runs physics           │ │◄─────┼──┤  • Reads from Modbus      │ │
│  │  • Exposes Modbus TCP     │ │ TCP  │  │  • Visualizes only        │ │
│  └──────────────────────────┘ │      │  └───────────────────────────┘ │
└────────────────────────────────┘      └─────────────────────────────────┘
              ▲
              │
              │ Modbus TCP
              ▼
┌────────────────────────────────┐
│       SCADA/HMI Systems        │
│    (ScadaLTS, OpenPLC, etc.)   │
└────────────────────────────────┘
```

**Setup:**

**Terminal 1 - Run V-ICS:**
```bash
cd V-ICS/space-modbus-server
cargo run
# Listens on 0.0.0.0:502
```

**Terminal 2 - Run lunco-sim:**
```gdscript
# In lunco-sim
var thermal = ThermalComponent.new()
thermal.mode = ThermalComponent.Mode.MODBUS_CLIENT
thermal.modbus_host = "127.0.0.1"
thermal.modbus_port = 502
add_child(thermal)
```

**Use Case:**
- ICS learning environment
- Multiple clients visualizing same simulation
- Industrial control practice
- SCADA/HMI integration

### Mode 3: lunco-sim as Source of Truth

```
┌─────────────────────────────────────┐
│         lunco-sim (Godot)           │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ shared_modelica_components    │ │
│  │ (MODBUS_SERVER mode)          │ │
│  │                                │ │
│  │  • Runs physics locally       │ │
│  │  • Exposes Modbus TCP         │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
              ▲
              │ Modbus TCP
              ▼
┌────────────────────────────────┐
│    External Monitoring Tools   │
│  (SCADA, Python scripts, etc.) │
└────────────────────────────────┘
```

**Setup:**
```gdscript
var thermal = ThermalComponent.new()
thermal.mode = ThermalComponent.Mode.MODBUS_SERVER
thermal.modbus_port = 502
add_child(thermal)
```

**Use Case:**
- Game runs physics
- External tools monitor/control
- Educational demonstrations
- Integration testing

## Build Process

### Building shared-modelica-components Addon

```bash
cd shared-modelica-components

# Full build
./build_addon.sh
# Output: bin/libshared_modelica_components.{so,dylib,dll}

# Or step by step:
cd rust-lib
./build_models.sh              # Compile Modelica models
cargo build --release          # Build Rust library
cd ..
cp rust-lib/target/release/lib*.* bin/
```

**What happens:**
1. OpenModelica compiles .mo files → C code
2. Rust build.rs compiles C code → static library
3. Rust compiler links everything → shared library
4. Library copied to `bin/` for Godot

### Setting up lunco-sim

```bash
cd godot-colony-sim/lunco-sim

# Add addon as submodule (first time only)
git submodule add https://github.com/bondlegend4/shared-modelica-components.git \
    addons/shared_modelica_components

# Build addon
cd addons/shared_modelica_components
./build_addon.sh

# Return to lunco-sim
cd ../..

# Open in Godot
godot --editor .

# Enable plugin: Project → Project Settings → Plugins → ✓ Shared Modelica Components
```

### Setting up V-ICS Modbus Server

```bash
cd V-ICS/space-modbus-server

# Add shared components as submodule
git submodule add https://github.com/bondlegend4/shared-modelica-components.git

# Build models
cd shared-modelica-components/rust-lib
./build_models.sh
cargo build --release

# Return to server directory
cd ../..

# Build server
cargo build --release

# Run
cargo run
```

## Development Workflow

### Adding a New Modelica Model

**1. Add model to shared-modelica-components:**
```bash
cd shared-modelica-components/rust-lib/models
vim NewModel.mo
```

**2. Update build.rs to compile it:**
```rust
// In rust-lib/build.rs, add:
compile_component(&build_dir, "NewModel", &omc_include, &omc_gc_include);
generate_bindings(&build_dir, "NewModel", &omc_include, &omc_gc_include);
```

**3. Create Rust component:**
```bash
cd ../src/components
vim new_model_node.rs
```

**4. Create GDScript wrapper:**
```bash
cd ../../integration
vim new_model_component.gd
```

**5. Rebuild addon:**
```bash
cd ..
./build_addon.sh
```

**6. Commit and push:**
```bash
git add .
git commit -m "Add NewModel component"
git push
```

**7. Update in lunco-sim:**
```bash
cd lunco-sim/addons/shared_modelica_components
git pull
./build_addon.sh
```

**8. Update in V-ICS:**
```bash
cd V-ICS/space-modbus-server/shared-modelica-components
git pull
cd rust-lib
./build_models.sh
cargo build --release
```

### Updating an Existing Model

**1. Edit model in addon repo:**
```bash
cd shared-modelica-components/rust-lib/models
vim SimpleThermalMVP.mo
```

**2. Rebuild:**
```bash
cd ..
./build_models.sh
cargo build --release
cd ..
cp rust-lib/target/release/lib*.* bin/
```

**3. Commit and push:**
```bash
git add .
git commit -m "Update SimpleThermalMVP: improve heat loss calculation"
git push
```

**4. Update submodules in both projects:**
```bash
# In lunco-sim
cd addons/shared_modelica_components
git pull
./build_addon.sh

# In V-ICS
cd shared-modelica-components
git pull
cd rust-lib
./build_models.sh
cargo build --release
```

## File Organization

### What Goes Where

| Content | Location | Repository |
|---------|----------|------------|
| Modelica models (.mo) | `shared-modelica-components/rust-lib/models/` | shared-modelica-components |
| Physics engine (Rust) | `shared-modelica-components/rust-lib/src/` | shared-modelica-components |
| Godot nodes (Rust) | `shared-modelica-components/rust-lib/src/components/` | shared-modelica-components |
| GDScript wrappers | `shared-modelica-components/integration/` | shared-modelica-components |
| Game systems | `lunco-sim/apps/modelica/systems/` | lunco-sim |
| Test scenes | `lunco-sim/apps/modelica/scenes/` | lunco-sim |
| Modbus server | `V-ICS/space-modbus-server/src/` | space-modbus-server |

### What's Shared vs Project-Specific

**Shared (in addon):**
- ✅ Modelica models
- ✅ Physics simulation code
- ✅ Basic Godot nodes
- ✅ Component wrappers with mode support

**lunco-sim specific:**
- Game logic (thermostats, power management, etc.)
- UI/HUD elements
- Save/load systems
- Colony management

**V-ICS specific:**
- Modbus register mapping
- SCADA integration
- Industrial protocols
- Learning scenarios

## Migration from Old Architecture

### Old Structure (Deprecated)
```
lunco-sim/
├── apps/modelica/
│   ├── models/                    # ❌ Remove
│   ├── build/                     # ❌ Remove
│   ├── build_models.sh            # ❌ Remove
│   ├── integration/               # ❌ Remove
│   └── core/                      # ❌ Remove

godot-modelica-rust-integration/    # ❌ Entire directory deprecated
```

### New Structure
```
lunco-sim/
├── addons/
│   └── shared_modelica_components/  # ✅ Add as submodule
└── apps/modelica/
    ├── systems/                     # ✅ Keep
    └── scenes/                      # ✅ Keep
```

### Migration Steps

**1. Remove old structure:**
```bash
cd lunco-sim
rm -rf apps/modelica/models
rm -rf apps/modelica/build
rm -rf apps/modelica/integration
rm -rf apps/modelica/core
rm apps/modelica/build_models.sh
```

**2. Add new addon:**
```bash
git submodule add https://github.com/bondlegend4/shared-modelica-components.git \
    addons/shared_modelica_components
cd addons/shared_modelica_components
./build_addon.sh
```

**3. Update game systems:**
```gdscript
# Old way
var thermal = load("res://apps/modelica/integration/thermal_component.gd").new()

# New way
var thermal = ThermalComponent.new()  # Auto-loaded by addon
```

**4. Remove deprecated repos:**
```bash
cd godot-colony-sim
rm -rf godot-modelica-rust-integration
```

## Dependencies

### shared-modelica-components
- **OpenModelica** (≥1.26.0) - Model compilation
- **Rust** (≥1.70) - Library compilation
- **Godot** (≥4.2) - Game engine integration

### lunco-sim
- **Godot** (≥4.2) - Game engine
- **shared-modelica-components** - Physics addon (via submodule)

### V-ICS space-modbus-server
- **Rust** (≥1.70) - Server language
- **shared-modelica-components** - Physics library (via submodule)
- **tokio** - Async runtime
- **tokio-modbus** - Modbus protocol

## Troubleshooting

### Addon won't load in Godot

**Symptoms:** Plugin not visible or fails to enable

**Solutions:**
```bash
# 1. Check library exists
ls addons/shared_modelica_components/bin/

# 2. Rebuild addon
cd addons/shared_modelica_components
./build_addon.sh

# 3. Check Godot console for errors
# Look for "Cannot load GDExtension" messages

# 4. Verify plugin.cfg exists
cat plugin.cfg
```

### Models not compiling

**Symptoms:** `build_models.sh` fails

**Solutions:**
```bash
# 1. Check OpenModelica installed
which omc
omc --version

# 2. Check model syntax
cd rust-lib/models
omc -s SimpleThermalMVP.mo

# 3. Check for errors in output
```

### Modbus connection fails

**Symptoms:** Cannot connect in MODBUS_CLIENT mode

**Solutions:**
```gdscript
# 1. Check server is running
# Terminal: netstat -an | grep 502

# 2. Verify host/port settings
thermal.modbus_host = "127.0.0.1"
thermal.modbus_port = 502

# 3. Check firewall settings

# 4. Test with modbus tool:
# mbpoll -t 3 -r 0 -c 1 127.0.0.1
```

### Submodule issues

**Symptoms:** `git submodule update` fails

**Solutions:**
```bash
# 1. Initialize submodules
git submodule update --init --recursive

# 2. Update to latest
cd addons/shared_modelica_components
git pull origin main
cd ../..
git add addons/shared_modelica_components
git commit -m "Update addon"

# 3. If stuck, re-add submodule
git submodule deinit addons/shared_modelica_components
rm -rf .git/modules/addons/shared_modelica_components
git rm addons/shared_modelica_components
git submodule add https://github.com/bondlegend4/shared-modelica-components.git \
    addons/shared_modelica_components
```

## See Also

- [shared-modelica-components README](https://github.com/bondlegend4/shared-modelica-components)
- [LunCo Architecture](./LunCo-Architecture.md)
- [V-ICS Documentation](../V-ICS/README.md)
- [OpenModelica Documentation](https://openmodelica.org/doc/)
- [Godot GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/)