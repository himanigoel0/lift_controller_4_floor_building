# Advanced Lift Controller using FSM in Verilog HDL
## 2. Objective
The objective of this project is to design and implement an **Advanced Lift Controller using a Finite State Machine (FSM) in Verilog HDL**. The controller manages lift movement, floor requests, door operations, direction control, overload protection, and emergency handling while ensuring safe and efficient operation.
## 3. Features
- Four-floor lift system (Floors 0–3)
- Cabin request handling
- Hall request handling (Up/Down)
- Direction-based scheduling
- Automatic door opening and closing
- Emergency stop functionality
- Overload protection
- FSM-based control architecture
- Debug state monitoring
# 4. System Inputs
Signal	Description
clk	System clock
rst	System reset
cabin_requests[3:0]	Requests from inside lift
hall_requests[5:0]	Up/Down hall requests
emergency_stop	Emergency trigger
overload_sensor	Detects overload condition
open_button	Manual door open
close_button	Manual door close
5. System Outputs
Signal	Description
move_up	Lift moves upward
move_down	Lift moves downward
door_open	Opens lift door
door_close	Closes lift door
idle	Lift idle state
current_floor[1:0]	Current floor position
direction	Travel direction
overload	Overload indication
emergency	Emergency indication
debug_state[6:0]	Current FSM state
6. FSM States
Create a table:
State	Description
IDLE	Waiting for requests
MOVE_UP	Lift moving upward
MOVE_DOWN	Lift moving downward
DOOR_OPEN	Door opened
DOOR_CLOSE	Door closing
OVERLOAD	Lift halted due to overload
EMERGENCY	Emergency stop activated
