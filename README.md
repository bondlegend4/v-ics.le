# v-ics.le

**Virtual Industrial Control Systems - Learning Environment**

A simulation platform combining realistic physics simulation with industrial control system (ICS) security testing and education.

## Architecture Overview

We have migrated from bare-metal Modelica/HELICS to **Rumoca** to streamline the physics simulation and focus heavily on SCADA network interactions.

```text
┌─────────────────────────────────────────────────────────────┐
│                    Rumoca (Physics/Simulation)              │
└──────────────────────────────┬──────────────────────────────┘
                               │
                          Modbus TCP
                               │
                 ┌─────────────▼──────────────┐
                 │ modelica-rust-modbus-server│
                 │ (State Synchronization)    │
                 └─────────────┬──────────────┘
                               │
                          Modbus TCP
                               │
                 ┌─────────────▼──────────────┐
                 │ OpenPLC / SCADA Tools      │
                 │ (ICS Control Environment)  │
                 └────────────────────────────┘

```

## Components Status

### ✅ 1. modelica-rust-modbus-server (Active)

The core bridge for ICS integration. It provides a standalone Modbus TCP server that exposes simulation states to external PLCs and SCADA systems.

* **Status:** WORKING
* **Role:** Handles all standard Modbus TCP requests, acting as the interface between the simulation environment and control logic.

### 🔄 2. Rumoca Integration (In Progress)

Replacing the legacy `modelica-rust-ffi` and `modelica-helics-federate` components. Rumoca will handle the execution of system dynamics (thermal, power, life support) and pipe data directly to the Modbus server.

### 🗑️ 3. Legacy Components (Removed)

To reduce overhead and maintain a strict focus on ICS/SCADA security, the following components have been deprecated and removed:

* `godot-colony-sim` (Visualizations)
* `modelica-helics-federate`
* `modelica-rust-ffi`

## Getting Started

### Prerequisites

1. **Rust** - For building the Modbus server and Rumoca environment.
2. **OpenModelica** - Required by Rumoca for compilation.

### Building

```bash
# Clone the repository
git clone [https://github.com/bondlegend4/v-ics.le.git](https://github.com/bondlegend4/v-ics.le.git)
cd v-ics.le

# Build the Modbus server
cd V-ICS/modelica-rust-modbus-server
cargo build --release

```

## Development Roadmap

* **Phase 1:** Complete Rumoca migration and establish stable data piping to `modelica-rust-modbus-server`.
* **Phase 2:** Connect OpenPLC via Modbus TCP and validate bidirectional state control.
* **Phase 3:** Develop containerized attack/defense scenarios and SCADA network traffic analysis.

```

---

### **Step 3: Update `PROJECT_STATUS.md`**
Replace your `PROJECT_STATUS.md` with this clean slate so you know exactly where you stand.