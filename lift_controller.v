`timescale 1ns / 1ns

module lift_controller(

    input clk, rst,
    input [3:0] cabin_requests,
    input [5:0] hall_requests,
    input emergency_stop,
    input overload_sensor,
    input open_button, close_button,
    // cabin requests are the floor requests that a person inside a lift wishes to go to
    // hall requests are the requests a person makes while he is waiting outside the lift
    
    output reg idle, move_up, move_down, door_open, door_close,  // these are our states
    output reg [1:0] current_floor,
    output [6:0] debug_state,
    output reg overload
    
    );
    
    // request_above does not mean that someone wants to go up. 
    // it means that some physical work is pending up.
    
    reg [6:0] present_state, next_state;
    reg request_above, request_below, request_current;
    reg [3:0] pending_cabin_requests;
    reg [5:0] pending_hall_requests;
    reg direction;
    reg [3:0] new_cabin_requests;
    reg [5:0] new_hall_requests;
    reg [2:0] door_timer; // 3 bits are enough for 0-7 count
    
    // direction = 0 means down and direction = 1 means up
    
    /*
        pending hall requests:
        6'b000001 = up at gnd floor
        6'b000010 = up at 1st floor
        6'b000100 = up at 2nd floor 
        6'b001000 = down at 3rd floor
        6'b010000 = down at 2nd floor
        6'b100000 = down at 1st floor
        
    */
    
    // this pending cabin request helps to remember which floors are pending.
    /* We need to make an internal register that will track my pending cabin requests, 
    even if I moved till where I wanted, I will remain stuck at one state only 
    until my pending cabin request are not cleared. */
    
    parameter idle_state = 7'b0000001;
    parameter move_up_state = 7'b0000010;
    parameter move_down_state = 7'b0000100;
    parameter door_open_state = 7'b0001000;
    parameter door_close_state = 7'b0010000;
    parameter emergency_state = 7'b0100000;
    parameter rst_state = 7'b1000000;
    //    parameter gnd_floor = 4'b0001;
    //    parameter first_floor = 4'b0010;
    //    parameter second_floor = 4'b0100;
    //    parameter third_floor = 4'b1000;
    
    assign debug_state = present_state;
    
                
                
                
            
        // REQUEST HANDLING
        always @(*) begin
        
            request_above = 0;
            request_below = 0;
            request_current = 0;
        
            if (current_floor == 2'b00) begin
                request_below = 0;
                if (pending_cabin_requests[1] || pending_cabin_requests[2] || pending_cabin_requests[3]) request_above = 1;
                if (pending_cabin_requests[0]) request_current = 1;
                if (pending_hall_requests[0]) begin
                    request_current = 1;
                end
                if (pending_hall_requests[1] || pending_hall_requests[2] ) request_above = 1;
                if (pending_hall_requests[3] || pending_hall_requests[4] || pending_hall_requests[5]) request_above = 1;
                // if we press gnd up button, the lift needs to know that we need to open at gnd floor and then go up.
                // since we have initialised the conditions, we dont need to explicitly do for request_above = 0 case
            end
            
            else if (current_floor == 2'b01) begin
                if (pending_cabin_requests[0]) request_below = 1;
                if (pending_cabin_requests[2] || pending_cabin_requests[3]) request_above = 1;
                if (pending_cabin_requests[1]) request_current = 1;
                if (pending_hall_requests[1] && (direction == 1 || present_state == idle_state)) begin
                    request_current = 1;
                    request_above = 1;
                end
                if (pending_hall_requests[5] && (direction == 0 || present_state == idle_state)) begin
                    request_current = 1;
                    request_below = 1;
                end
                if (pending_hall_requests[0]) request_below = 1;
                if (pending_hall_requests[2] || pending_hall_requests[3] || pending_hall_requests[4]) request_above = 1;
                
            end
            
            else if (current_floor == 2'b10) begin
                if (pending_cabin_requests[3]) request_above = 1;
                if (pending_cabin_requests[0] || pending_cabin_requests[1]) request_below = 1;
                if (pending_cabin_requests[2]) request_current = 1;
                if (pending_hall_requests[2] && (direction == 1 || present_state == idle_state)) begin
                    request_current = 1;
                    request_above = 1;
                end
                if (pending_hall_requests[4] && (direction == 0 || present_state == idle_state)) begin
                    request_current = 1;
                    request_below = 1;
                end
                if (pending_hall_requests[0] || pending_hall_requests[1] || pending_hall_requests[5]) request_below = 1;
                if (pending_hall_requests[3]) request_above = 1;
            end
            
            else if (current_floor == 2'b11) begin
                request_above = 0;
                if (pending_cabin_requests[0] || pending_cabin_requests[1] || pending_cabin_requests[2]) request_below = 1;
                if (pending_cabin_requests[3]) request_current = 1;
                if (pending_hall_requests[3] && present_state == idle_state) begin
                    request_current = 1;
                end
                if (pending_hall_requests[0] || pending_hall_requests[1] || pending_hall_requests[2]) request_below = 1;
                if (pending_hall_requests[4] || pending_hall_requests[5]) request_below = 1;
            end
            
        end
        
        
        
        
        
        // SEQUENTIAL LOGIC with SYNCHRONOUS RESET
        always @(posedge clk) begin
        
            // If reset, then remain idle wherever we are and flush out all the floor requests
            
            if (rst) begin
                present_state <= rst_state;
                pending_cabin_requests <= 4'b0000;
                pending_hall_requests <= 6'b000000;
                direction <= 0;
                door_timer <= 0;
                current_floor <= 2'b00;
                // I cant initialise current floor to 0 because if I am at the 3rd floor, 
                // and rst is activated, then my lift cant teleport immediately from
                // 3rd floor to gnd floor.

            end
            
            // else if (emergency_stop) present_state <= emergency_state;
            
            else begin
                present_state <= next_state;
                
                if (present_state == rst_state && current_floor != 2'b00) current_floor <= current_floor - 1;
                
                else if (present_state == move_up_state && next_state == move_up_state && current_floor != 2'b11) begin
                    current_floor <= current_floor + 1;
                    direction <= 1;
                end
                else if (present_state == move_down_state && next_state == move_down_state && current_floor != 2'b00) begin
                    current_floor <= current_floor - 1;
                    direction <= 0;
                end
                // else if (present_state == idle_state) current_floor <= current_floor;
                
                // Pending cabin requests is also memory, so we can't assign them in combinational block.
                new_cabin_requests = pending_cabin_requests | cabin_requests;
                new_hall_requests = pending_hall_requests | hall_requests;
                /* 
                    Suppose initially we have cabin_requests = 1010, now we also press 2nd floor, so it will
                   update itself to 1110.
                */
                
                if (present_state == door_open_state) door_timer <= door_timer + 1;
                else door_timer <= 0;
            
                if (present_state == door_open_state && request_current) begin

                    if (current_floor == 2'b00) begin
                        new_cabin_requests[0] = 0;
                        new_hall_requests[0] = 0;
                    end
                
                    else if (current_floor == 2'b01) begin
                        new_cabin_requests[1] = 0;
                        if (direction) new_hall_requests[1] = 0;
                        else new_hall_requests[5] = 0;
                    end
                
                    else if (current_floor == 2'b10) begin
                        new_cabin_requests[2] = 0;
                        if (direction) new_hall_requests[2] = 0;
                        else new_hall_requests[4] = 0;
                    end
                
                    else if (current_floor == 2'b11) begin
                        new_cabin_requests[3] = 0;
                        new_hall_requests[3] = 0;
                    end
                
                end
                
                pending_cabin_requests <= new_cabin_requests;
                pending_hall_requests <= new_hall_requests;
                    
                    /* 
                       if we are at floor 2 and the lift opened, suppose we were going up and both up 
                       and down were pressed, if we do this, then both the requests are cleared, but 
                       we have to fulfil the down request when we will movedown in the next turn.
                       so, we also put the condition that if moving up, then only clear up request.
                    */
            
                end 
            
            // if (request_current) pending_cabin_requests[current_floor] <= 0;
            // If we had a request for some floor and we reach there, then after fulfilling it, clear it.
            // if we do the second last line, then pending_cabin_requests will both update at the same clk edge, 
            // and only the last assignment wins. so we need to do something else. 
            
            end
        
        
        
        
        
        
        // NEXT STATE LOGIC
        always @(*) begin
        
            next_state = present_state;
            
            if (rst) next_state = rst_state;
            else if (emergency_stop) next_state = emergency_state;
            // This will ensure that the door remains open until emergency behaviour is not disabled.
            
            else begin 
                
                if (present_state == rst_state) begin
                    if (current_floor == 2'b00) next_state = idle_state;
                    else next_state = rst_state;
                end
                else if (present_state == emergency_state) next_state = emergency_state;
//                else if (overload_sensor) next_state = door_open_state;
                else if (present_state == idle_state) begin
                    if (request_current) next_state = door_open_state;
                    else if (request_above) next_state = move_up_state;
                    else if (request_below) next_state = move_down_state;
                    else next_state = idle_state; 
                end
                    
                /* first, in if we wrote above because if we did if(below) and else if(above), 
                   then it would first cover the below requests and not go in the same direction.
                */
                // continue in same direction as long as work exists there
                
                // now, we can open door when we move up or down and we encounter any current_requests.
                else if (present_state == move_up_state) begin
                    if (request_current) next_state = door_open_state;
                    else if (request_above) next_state = move_up_state;
                    else if (request_below) next_state = move_down_state;
                    else next_state = idle_state;
                end
                
                else if (present_state == move_down_state) begin
                    if (request_current) next_state = door_open_state;
                    else if (request_below) next_state = move_down_state;
                    else if (request_above) next_state = move_up_state;
                    else next_state = idle_state;
                end        
                
                else if (present_state == door_open_state) begin
                    if (overload_sensor) next_state = door_open_state;
                    else if (close_button) next_state = door_close_state;
                    else if (door_timer == 3'd7) next_state = door_close_state;
                    else next_state = door_open_state; // jb tb 8 cycles na ho, keep the door open
                    // open the lift for 8 cycles, before it closes. 
                    // we also have a door_close button in case someone wants to close the lift before 8 cycles.
                end
                
                else if (present_state == door_close_state) begin
                    if (open_button) next_state = door_open_state;
                    // continue upward if already going upward
                    else if (direction == 1 && request_above) next_state = move_up_state;
                   // continue downward if already going downward
                    else if (direction == 0 && request_below) next_state = move_down_state;
                    // if same-direction requests finished, then reverse
                    else if (request_above) next_state = move_up_state;
                    else if (request_below) next_state = move_down_state;
                    else next_state = idle_state;
                
                end
        
            end
        end
        
        
        
        
        
        // OUTPUT LOGIC
        always @(*) begin
        
            idle = 0;
            move_up = 0;
            move_down = 0;
            door_open = 0;
            door_close = 1;
            overload = 0;
            
            if (present_state == rst_state) begin
                if (current_floor != 2'b00) move_down = 1;
                else move_down = 0;
                move_up = 0;
                door_open = 0;
                door_close = 1;
            end
            
            else if (present_state == emergency_state) begin
                idle = 0;
                move_up = 0;
                move_down = 0;
                door_open = 1;
                door_close = 0;
            end
        
            // When the lift is idle, or is moving up or down, the door needs to be closed
            else if (present_state == idle_state) begin
                idle = 1;
                move_up = 0;
                move_down = 0;
                door_open = 0;
                door_close = 1;
            end
            else if (present_state == move_up_state) begin
                idle = 0;
                move_up = 1;
                move_down = 0;
                door_close = 1;
            end
            else if (present_state == move_down_state) begin
                idle = 0;
                move_up = 0;
                move_down = 1;
                door_close = 1;
            end
            else if (present_state == door_open_state) begin
                door_open = 1;
                door_close = 0;
            end
            else if (present_state == door_close_state) begin
                door_open = 0;
                door_close = 1;
            end
            if (present_state == door_open_state && overload_sensor) overload = 1;
        end
        
        endmodule 
