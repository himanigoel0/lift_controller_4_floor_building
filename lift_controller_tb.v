`timescale 1ns / 1ns

module lift_controller_tb();

reg clk, rst;
reg [3:0] cabin_requests;
reg [5:0] hall_requests;
reg emergency_stop, overload_sensor, open_button, close_button;

wire idle, move_up, move_down, door_open, door_close;
wire [1:0] current_floor;
wire [6:0] debug_state;
wire direction;
wire overload;
wire emergency;

lift_controller uut(
    .clk(clk),
    .rst(rst),
    .cabin_requests(cabin_requests),
    .hall_requests(hall_requests),
    .emergency_stop(emergency_stop),
    .overload_sensor(overload_sensor),
    .open_button(open_button),
    .close_button(close_button),
    .idle(idle),
    .move_up(move_up),
    .move_down(move_down),
    .door_open(door_open),
    .door_close(door_close),
    .current_floor(current_floor),
    .direction(direction),
    .debug_state(debug_state),
    .overload(overload),
    .emergency(emergency)
);

initial begin
    uut.current_floor = 2'b00;
    uut.direction = 2'b00;
    uut.present_state = uut.idle_state;
    clk = 0;
end
always #5 clk = ~clk;

initial begin 
    
    rst = 1;
    cabin_requests = 0;
    hall_requests = 0;
    emergency_stop = 0;
    overload_sensor = 0;
    open_button = 0;
    close_button = 0;

    #50;
    rst = 0;

    // Let the FSM stabilize for 1 cycle
    #10;
    
    //              ===============================================
    //                        BASIC FLOOR TO FLOOR MOVEMENT
    //              ===============================================
    
    
    // ----------------------------------------------------------------------
    // Testing to go at each floor, one by one, through cabin requests only
    // ----------------------------------------------------------------------
    
    // FLOOR 0 -> FLOOR 1

    cabin_requests = 4'b0010;   // request floor 1
    #10;cabin_requests = 4'b0000;   // release button
    // wait for: idle -> move_up -> door_open -> door_close -> idle
    
    // FLOOR 1 -> FLOOR 2
   
    #100; cabin_requests = 4'b0100;   // request floor 2
    #10; cabin_requests = 4'b0000;
    
    // FLOOR 2 -> FLOOR 3
    
    #100; cabin_requests = 4'b1000;   // request floor 3
    #10; cabin_requests = 4'b0000;
    
    // FLOOR 3 -> FLOOR 2
    
    #100; cabin_requests = 4'b0100;   // request floor 2
    #10; cabin_requests = 4'b0000;
    
    // FLOOR 2 -> FLOOR 1
    
    #100; cabin_requests = 4'b0010;   // request floor 1
    #10; cabin_requests = 4'b0000;
        
    // FLOOR 1 -> GROUND
    
    #100; cabin_requests = 4'b0001;   // request ground floor
    #10; cabin_requests = 4'b0000;
    
    #200;
    
    // ------------------------------------------------------------------------
    // Testing to go at each floor, one by one, through hall requests only (UP)
    // ------------------------------------------------------------------------
    
    // GROUND FLOOR UP REQUEST
    // Lift should open at ground floor and then start moving upward
    
    hall_requests = 6'b000001;
    #10; hall_requests = 6'b000000;
    
    // FLOOR 1 UP REQUEST
    // Lift should go from ground to floor 1
    
    #100; hall_requests = 6'b000010;
    #10; hall_requests = 6'b000000;
    
    // FLOOR 2 UP REQUEST
    // Lift should go from floor 1 to floor 2
    
    #100; hall_requests = 6'b000100;
    #10; hall_requests = 6'b000000;
    
    // ---------------------------------------------------------------------------
    // Testing to go at each floor, one by one, through hall requests only (DOWN)
    // ---------------------------------------------------------------------------
    
    // FLOOR 3 DOWN REQUEST
    // Lift should go from floor 2 to floor 3
    
    #100; hall_requests = 6'b001000;
    #10; hall_requests = 6'b000000;
    
    // FLOOR 2 DOWN REQUEST
    // Lift should go from floor 3 to floor 2
    
    #100; hall_requests = 6'b010000;
    #10; hall_requests = 6'b000000;
    
    // FLOOR 1 DOWN REQUEST
    // Lift should go from floor 2 to floor 1
    
    #100; hall_requests = 6'b100000;
    #10; hall_requests = 6'b000000;
    
    // TILL NOW WE HAVE VERIFIED THAT THE LIFT STOPS AND OPENS, THEN CLOSES AFTER 8 CLK CYCLES AT EACH FLOOR
    // IT IS WORKING FINE TO MOVE UP AND DOWN BOTH
    
    
    //              ===========================================================
    //                             MULTIPLE CABIN REQUESTS HANDLING
    //              ===========================================================
    

    // ------------------------------------------------------
    // TESTING MULTIPLE CABIN REQUESTS IN SAME DIRECTION (UP)
    // ------------------------------------------------------
    
    #200; cabin_requests = 4'b1110;   // floor 1,2,3 all requested together.
    #10; cabin_requests = 4'b0000;
    // We ae currently at first floor.
    // lift should go 1 -> 2 -> 3 with door open/close at each floor.
    
    // ---------------------------------------------------------
    // TESTING MULTIPLE CABIN REQUESTS IN SAME DIRECTION (DOWN)
    // ---------------------------------------------------------
    
    #400; cabin_requests = 4'b1111;   // floor 0,1,2,3 all requested together.
    #10; cabin_requests = 4'b0000;
    // lift should go 3 -> 2 -> 1 -> 0 with door open/close at each floor.
    
    // ----------------------------------------------------
    // TESTING MULTIPLE CABIN REQUESTS IN RANDOM DIRECTION
    // ----------------------------------------------------
    
    #500; cabin_requests = 4'b0100;   // first lets go to 2nd floor.
    #10; cabin_requests = 4'b0000;
    // when I directly go from gnd floor to 2nd, the lift should not open at the 1st floor.
    
    #200; cabin_requests = 4'b1111;   
    #10; cabin_requests = 4'b0000;
    // lift should go 2(open) -> 3 -> 2(not open) -> 1 -> 0 with door open/close at each floor.
    // main testing point is that lift should first go to 3rd floor (up) and not down.
    
    
    #500; cabin_requests = 4'b0010;   // now first lets go to 1st floor.
    #10; cabin_requests = 4'b0000;
    
    #100; cabin_requests = 4'b1111;   // lets order every floor through cabin requests.
    #10; cabin_requests = 4'b0000;
    // lift should go 1(open) -> 2 -> 3 -> 2(not open) -> 1(not open) -> gnd 
    // main testing point is that lift should first go up and then come down to prevent unnecessary direction changes.
    
    // now lets move up to 2nd floor and then go down to 1st floor, then give requests for all the floors.
    #500; cabin_requests = 4'b0100;   // now first lets go to 2nd floor.
    #10; cabin_requests = 4'b0000;
    
    #100; cabin_requests = 4'b0010;   // Then come down to 1st floor
    #10; cabin_requests = 4'b0000;
    
    #100; cabin_requests = 4'b1111;   // now lets order every floor through cabin requests.
    #10; cabin_requests = 4'b0000;
    // now what happens, we were moving down so we first complete request of gnd floor, then go to 2nd, 3rd floor.
    // this will prevent direction changes.
    
    // currently I am at third floor due to last condition, let me come to 2nd floor and then give 3rd and 1st floor.
    #500; cabin_requests = 4'b0100;
    #10; cabin_requests  = 4'b0000;
    
    #100; cabin_requests = 4'b1010;
    #10; cabin_requests = 4'b0000;
    // I go first to 1st floor, then to 3rd floor (direction changes minimise)
    
    // Now I again come to 2nd floor from 3rd floor and this time I got cabin requests for gnd and third floor
    #400; cabin_requests = 4'b0100;
    #10; cabin_requests  = 4'b0000;
    
    #100; cabin_requests = 4'b1001;
    #10; cabin_requests = 4'b0000;
    // direction is down, so I first go to gnd, then come back to 3rd

// _______________________________________________________________________________________________________
// Conclusion: The lift is prioritising direction based scheduling, instead of nearest floor scheduling.  
// _______________________________________________________________________________________________________

                            // ==============================================
                            //               SAFETY INTERLOCKS
                            // ==============================================
                            
// -------------------
// OVERLOAD DETECTION
// -------------------
                            
    // detecting overload when we are currrently in door open state (gates have not closed due to door timer till now).
    #200; overload_sensor = 1;
    #100; overload_sensor = 0;
    // The doors must remain open until the overload sensor doesnot indicate that overload is taken care of.
    // also, the overload signal should go high.
    
    // // detecting overload when we are currrently in door close state 
    #100; overload_sensor = 1;
    #100; overload_sensor = 0;
    
// ---------------------
// EMERGENCY DETECTION
// ---------------------
    #100; emergency_stop = 1;
    #100; emergency_stop = 0;
    
// -----------------------------------
// CLOSE AND OPEN BUTTON VERIFICATION
// -----------------------------------
    
    // lets start to move to 1st floor (last time we were at 3rd floor)
    #10; cabin_requests = 4'b0010;
    #100; cabin_requests = 4'b0000;
    // Now the doors will be opened for 8 clk cycles. we will try to use close button and lift should close before that
    #50; close_button = 1;
    #50; close_button = 0;
    
    // go to floor 2 and check for open button:
    #50; cabin_requests = 4'b0100;
    #10; cabin_requests = 4'b0000;
    // it was going to close, but now it should open
    #150; open_button = 1;
    #50; open_button = 0;
    
                    // ==========================================================
                    //               MULTIPLE HALL REQUESTS HANDLING
                    // ==========================================================    
    #100; hall_requests = 6'b111111;
    #10; hall_requests = 6'b000000;
    // the lift is presently at floor 2, in direction up.
    // so, it will first fulfil the request of 2 up.
    // then it will go up, direction reverses (3 down). 
    // then it serves all the down req, of 2 down, 1 down, then finally serves 1 up after direction change.
    // final state = floor 1 with direction up.
    
    #700; hall_requests = 6'b101100;
    #10; hall_requests = 6'b000000;
    // now it should go to 2nd floor up, then 3rd down, then 1st down, doors should not open at any other place.
        
    // now my condition is 1st floor down.
    // let me first get to gnd floor, then i will give 1 up and 2 down request.
    #500; cabin_requests = 4'b0001;
    #10; cabin_requests = 4'b0000;
    
    #100; hall_requests = 6'b100100;
    #10; hall_requests = 6'b000000;
    // now I was at the condition gnd down direction.
    // when I give 2 up and 1 down, it will change its direction to up and hence will go to 2 up first.
    // then, it again reverses its direction to come to 1 down and opens the doors.
    
// -----------------
// STOP SIMULATION
// -----------------
    #500;
    $finish;
    
end


endmodule
