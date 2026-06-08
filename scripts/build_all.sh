#!/bin/bash
# v-ics.le/scripts/build_all.sh
set -e

echo "===== Building v-ics.le Co-Simulation Stack ====="

#!/bin/bash
# v-ics.le/scripts/build_all.sh
set -e

# 1. Build V-ICS Modbus server
echo "Building V-ICS Modbus server..."
cd V-ICS/modelica-rust-modbus-server
cargo build --release
cd ../..

# 2. Rumoca Build (Placeholder for next steps)
# echo "Building Rumoca components..."
# cd rumoca-directory # (Update this once your Rumoca setup is initialized)
# cargo build --release
# cd ..

# 5. Build V-ICS Modbus server
echo "Building V-ICS Modbus server..."
cd V-ICS/space-modbus-server
cargo build --release
cd ../..

echo "===== Build Complete! ====="
echo ""
echo "Run co-simulation:"
echo "  1. Start Modbus Server: cd V-ICS/modelica-rust-modbus-server && cargo run --release &"
echo "  2. Start OpenPLC / SCADA tools to connect to the Modbus server."
echo "  3. (Pending) Start Rumoca simulation to pipe physics data."