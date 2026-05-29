`timescale 1ns / 1ps

module important_testcases_tb();

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
    uut.current_floor = 2'b11;
    uut.direction = 2'b00;
    uut.present_state = uut.idle_state;
    clk = 0;
end
always #5 clk = ~clk;

initial begin

                        // ===============================================================
                                        // CASE 1: Reset / homing behavior
                        // ===============================================================    
    // we initially start with current floor = 2'b11 (3rd floor)
    rst = 1;
    cabin_requests = 0;
    hall_requests = 0;
    emergency_stop = 0;
    overload_sensor = 0;
    open_button = 0;
    close_button = 0;

    #50;
    rst = 0;
    
                        // ===============================================================
                                 // CASE 2: Single cabin request upward for third floor
                        // ===============================================================  
    #100; cabin_requests = 4'b1000;
    #10; cabin_requests = 4'b0000;
    
                        // ===============================================================
                                 // CASE 3: Multiple cabin requests in same direction
                        // =============================================================== 
    
    // first get the lift to ground floor
    #200; cabin_requests = 4'b0001;
    #10; cabin_requests = 4'b0000;
    
    // then, request for 1st, 2nd and 3rd floor
    #200; cabin_requests = 4'b1110;
    #10; cabin_requests = 4'b0000;
    
                        // ===============================================================
                                 // CASE 4: Direction priority with mixed requests
                        // =============================================================== 
    // again get back to gnd floor
    #400; cabin_requests = 4'b0001;
    #10; cabin_requests = 4'b0000;
    
    // now first request for 3rd floor, and then for 1st floor.
    #200; cabin_requests = 4'b1000;
    #10; cabin_requests = 4'b0000;
    
    #40; cabin_requests = 4'b0010;
    #10; cabin_requests = 4'b0000;
    
                        // ===============================================================
                        //          Case 5: Hall request direction handling
                        // =============================================================== 
    #300; hall_requests = 6'b010100;
    #10; hall_requests = 6'b000000;
    
                        // ===============================================================
                        //           Case 6: Door open / close button behavior: 
                        // =============================================================== 
    
    #300; cabin_requests = 4'b0001;
    #10; cabin_requests = 4'b0000;
    // we were already at 2nd floor now we try to bring it to the gnd floor.
    
    #100; cabin_requests = 4'b1010;
    #10; cabin_requests = 4'b0000;
    // we gave request for 1st and 3rd floor
    
    #60; close_button = 1;
    #10; close_button = 0;
    // while the lift would reach 1st floor and open, we pressed close_button.
    // the lift should continue to 3rd floor and not forget its pending requests.
    
    // now while the doors would be closing, we give open_button so that the doors remain open.
    #100; cabin_requests = 4'b0001;
    #10; cabin_requests = 4'b0000;
    
    #50; open_button = 1;
    #10; open_button = 0;
    
    #120; open_button = 1;
    #10; open_button = 0;
    
                        // ===============================================================
                        //           Case 7: safety cases: emergency and overload
                        // =============================================================== 
    
    #300; cabin_requests = 4'b1000;
    #10; cabin_requests = 4'b0000;
    
    #20; emergency_stop = 1;
    #10; emergency_stop = 0;
    
    #250; emergency_stop = 1;
    #10; emergency_stop = 0;
    
    #300; cabin_requests = 4'b0001; 
    #10; cabin_requests = 4'b0000;
    
    #20; overload_sensor = 1;
    #20; overload_sensor = 0;
    
    #150; overload_sensor = 1;
    #20; overload_sensor = 0;
    
    #100; overload_sensor = 1;
    #20; overload_sensor = 0;
    
    #400;
    $finish;
    
end

endmodule
