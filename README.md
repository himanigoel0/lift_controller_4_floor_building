# Advanced Lift Controller using FSM in Verilog HDL
## 1. Objective
The objective of this project is to design and implement an **Advanced Lift Controller using a Finite State Machine (FSM) in Verilog HDL**. The controller manages reset homing, lift movement, floor requests (both cabin and hall requests), door operations, direction control, overload protection, and emergency handling while ensuring safe and efficient operation.

## 2. Features
- Reset homing
- Four-floor lift system (Floors 0–3)
- Cabin request handling
- Hall request handling (Up/Down)
- Direction-based scheduling
- Automatic door opening and closing
- Emergency stop functionality
- Overload protection
- FSM-based control architecture
- Debug state monitoring
## 3. System Inputs

| Signal | Description |
|----------|------------|
| `clk` | System clock |
| `rst` | System reset |
| `cabin_requests[3:0]` | Floor requests from inside the lift cabin |
| `hall_requests[5:0]` | Up/Down hall requests from each floor |
| `emergency_stop` | Emergency trigger input |
| `overload_sensor` | Detects overload condition |
| `open_button` | Manual door open command |
| `close_button` | Manual door close command |

---

## 4. System Outputs

| Signal | Description |
|----------|------------|
| `idle` | Indicates idle state |
| `move_up` | Commands lift to move upward |
| `move_down` | Commands lift to move downward |
| `door_open` | Opens the lift door |
| `door_close` | Closes the lift door |
| `current_floor[1:0]` | Current floor position |
| `debug_state[6:0]` | FSM state monitoring output |
| `direction` | Current travel direction |
| `overload` | Overload status indication |
| `emergency` | Emergency status indication |

---

## 5. FSM States

| State | Description | State Encoding |
|---------|------------|---------------|
| idle_state | Waiting for requests | 7'b0000001 |
| move_up_state | Lift moving upward | 7'b0000010 |
| move_down_state | Lift moving downward | 7'b0000100 |
| door_open_state | Door is open for passenger entry/exit | 7'b0001000 |
| door_close_state | Door is closing before movement | 7'b0010000 |
| emergency_state | Emergency stop activated | 7'b0100001 |
| rst_state | Lift halted due to overload condition | 7'b1000000 |

---
