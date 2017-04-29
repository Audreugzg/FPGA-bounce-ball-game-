/*
Copyright by Henry Ko and Nicola Nicolici
Developed for the Digital Systems Design course (COE3DQ4)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`default_nettype none

module exercise1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[9:0] VGA_RED_O,              // VGA red
		output logic[9:0] VGA_GREEN_O,            // VGA green
		output logic[9:0] VGA_BLUE_O              // VGA blue
);

logic system_resetn;
logic Clock_50, Clock_25, Clock_25_locked;

// For VGA	case (change)

logic [9:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

assign system_resetn = ~(SWITCH_I[17] || ~Clock_25_locked);

// PLL for clock generation
CLOCK_25_PLL CLOCK_25_PLL_inst (
	.areset(SWITCH_I[17]),
	.inclk0(CLOCK_50_I),
	.c0(Clock_50),
	.c1(Clock_25),
	.locked(Clock_25_locked)
);

// VGA unit
VGA_Controller VGA_unit(
	.Clock(Clock_25),
	.Resetn(system_resetn),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	//	VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O),
	.oVGA_CLOCK()	

);
logic [7:0]counter;
logic[1:0]VHS;
logic[1:0]blink;
//logic VGA_VSYNC_buf;
logic VGA_VSYNC_buf;
logic change;
logic shift;
logic [7:0]limit;
//always_ff @(posedge Clock_25 or negedge system_resetn) begin
//	if(system_resetn==0) begin
//		VHS <= 2'b00;
//	end else begin
//		  if(change==0)begin
//			VHS<= {SWITCH_I[1],SWITCH_I[0]};
//		  end else begin
//
//	end
//end
//end
always_ff @(posedge Clock_25 or negedge system_resetn) begin
	if(system_resetn==0) begin
	   //VGA_VSYNC_buf<=0;
		VGA_VSYNC_buf<=0;
		counter <= 0;
		shift <=0;
	end else begin
		VGA_VSYNC_buf<=VGA_VSYNC_O;
	   VHS={SWITCH_I[1],SWITCH_I[0]};	
		if(counter<limit)begin
		   if(VGA_VSYNC_buf&&!VGA_VSYNC_O)begin
			    counter<=counter+8'd1;
			end
		end else begin
		shift<=~shift;
		counter<=0;
		end
	end	  
end




always_comb begin
   if(SWITCH_I[2]==1'b1)begin
	   change=1;
	end else begin
	   change=0;
	end

end


always_ff @(posedge Clock_25 or negedge system_resetn) begin
   if(system_resetn==0) begin
	   limit<=8'd0;
	end else begin
	   if(change==1)begin
		blink= {SWITCH_I[4],SWITCH_I[3]};
		    case (blink)
		    2'b00: begin
			       limit=8'd30;	
				     end
		    2'b01: begin
					 limit=8'd60;
				     end
		    2'b10: begin
					 limit=8'd90;
				     end
		    2'b11: begin
					 limit=8'd120;
				     end
	      endcase	
      end
end
end
always_comb begin
   if(change==0)begin
	case (VHS)
		2'b00: begin
					VGA_red ={10{~pixel_X_pos[7]}};
					VGA_green ={10{~pixel_X_pos[6]}} ;
					VGA_blue = {10{~pixel_X_pos[5]}} ;
				 end
		2'b01: begin
					VGA_red = {10{~pixel_Y_pos[7]}};
					VGA_green = {10{~pixel_Y_pos[6]}};
					VGA_blue = {10{~pixel_Y_pos[5]}};
				 end
		2'b10: begin
					VGA_red = {10{~pixel_X_pos[8]}};
					VGA_green = {10{~pixel_X_pos[7]}};
					VGA_blue = {10{~pixel_X_pos[6]}};
				 end
		2'b11: begin
					VGA_red = {10{~pixel_Y_pos[8] }};
					VGA_green = {10{~pixel_Y_pos[7] }};
					VGA_blue = {10{~pixel_Y_pos[6] }};
				 end
	endcase
	end else begin
	
		 if(shift==1)begin
	    if(SWITCH_I[1]==0)begin
		   VGA_red = {10{~pixel_Y_pos[7]}};
			VGA_green = {10{~pixel_Y_pos[6]}};
		   VGA_blue = {10{~pixel_Y_pos[5]}};
		 end else begin
		   VGA_red = {10{~pixel_Y_pos[8] }};
			VGA_green = {10{~pixel_Y_pos[7] }};
		   VGA_blue = {10{~pixel_Y_pos[6] }};
		 end
	  end else begin
	     if(SWITCH_I[1]==0)begin
		   VGA_red = {10{~pixel_X_pos[7]}};
			VGA_green = {10{~pixel_X_pos[6]}};
		   VGA_blue = {10{~pixel_X_pos[5]}};
		  end else begin
		   VGA_red = {10{~pixel_X_pos[8] }};
			VGA_green = {10{~pixel_X_pos[7] }};
		   VGA_blue = {10{~pixel_X_pos[6] }};
		  end
	end
end
end
//always_comb begin
//	case (blink)
//		    2'b00: begin
//			       limit=8'd30;	
//				     end
//		    2'b01: begin
//					 limit=8'd60;
//				     end
//		    2'b10: begin
//					 limit=8'd90;
//				     end
//		    2'b11: begin
//					 limit=8'd120;
//				     end
//	      endcase	
//			
//end

assign VGA_CLOCK_O = CLOCK_50_I;

//assign VGA_red = {10{~pixel_X_pos[7]}}; // signal concatenation through replication:
//assign VGA_green = {10{~pixel_X_pos[6]}}; // ~pixel_X_pos[i] is replicated 10 times
//assign VGA_blue = {10{~pixel_X_pos[5]}}; // to create a 10 bit signal 

endmodule
