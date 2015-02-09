`timescale 1ns/1ps

//Clock divider

module clkdivider (clk,
                   slow_clk
				   );

  input  wire clk;
  output wire slow_clk;
 
  reg [14:0] count;
  
  always @(posedge clk) begin //{
      count <= count + 1'b1;
  end //}

 assign slow_clk = count[14]; 
 initial 
   count <= 15'h0;
 
 endmodule

//Ackermann using stack ram
module ackermann (clk,
				  reset,
				  m,
				  n,
				  anode_seg,
                  seven_seg,
                  led_out
				  );

parameter MSIZE = 3                    ;
parameter NSIZE = 4                    ;

input   wire                clk        ;
input   wire                reset      ;
input   wire [MSIZE-1'b1:0] m          ;
input   wire [NSIZE-1'b1:0] n          ;
output  reg  [3:0]          anode_seg  ;
output  reg  [6:0]          seven_seg  ;
output  wire [7:0]          led_out    ;

wire    [15:0]  m_temp           ;
wire    [15:0]  n_temp           ;
wire            slow_clk         ;
wire            gated_clock      ;
wire    [5:0]   pc_1             ;
wire    [5:0]   pc_2             ;
wire    [15:0]  ack_out          ;

reg             done             ;
reg     [5:0 ]  pc               ;
reg     [2:0]   state            ;
reg     [15:0]  out              ;
reg     [15:0]  stack [63:0]     ;

clkdivider I_clk_div (clk,slow_clk);

assign pc_1     = pc + 6'h1;
assign pc_2     = pc + 6'h2;
assign ack_out  = out;

assign m_temp = reset ? m : stack[pc];
assign n_temp = reset ? n : stack[pc_1];

assign led_out = m_temp[7:0];

always@(posedge slow_clk) begin //{
 
 if (reset) begin//{
   out            =  16'h0000   ;
	 pc             =  6'd0       ;
   done           =  1'b0       ;
   stack[0]       =  m          ; 
   stack[1]       =  n          ; 
 end//}
 else begin //{
  if(~done) begin //{ 
    if (~|m_temp) begin //{ check if m_temp is 0, if m_temp is 0, value of n_temp is don't care
      stack[pc]  = n_temp+1'b1  ;
      
      //if pc > 0 decrement the pc else assign the output
      if(~|pc)   begin out = stack[pc]; done = 1'b1; end
      else       begin pc  = pc-1'b1  ;              end
	  end //}

    else if (|m_temp && ~|n_temp) begin //{ m_temp > 0 and n_temp is 0
      stack[pc]      = m_temp-1'b1  ;
	    stack[pc_1]	   = 16'h0001     ;
    end //}	      
 
    else begin //{ m_temp > 1 and n_temp > 1 condition 
      stack[pc]         = m_temp-1'b1    ;
      stack[pc_1]       = m_temp         ;
      stack[pc_2]       = n_temp-1'b1    ;
      pc                = pc_1           ;        
    end //}

   end //} //done loop end
 end //} else loop end

 end//} always loop end


function [6:0] seg_value;
    input [3:0] inp;
    case (inp)
      4'h0 : seg_value = 7'b1000000;
      4'h1 : seg_value = 7'b1111001;
      4'h2 : seg_value = 7'b0100100;
      4'h3 : seg_value = 7'b0110000;
      4'h4 : seg_value = 7'b0011001;
      4'h5 : seg_value = 7'b0010010;
      4'h6 : seg_value = 7'b0000010;
      4'h7 : seg_value = 7'b1111000;
      4'h8 : seg_value = 7'b0000000;
      4'h9 : seg_value = 7'b0010000;
      4'hA : seg_value = 7'b0001000;
      4'hB : seg_value = 7'b0000011;
      4'hC : seg_value = 7'b1000110;
      4'hD : seg_value = 7'b0100001;
      4'hE : seg_value = 7'b0000110;
      4'hF : seg_value = 7'b0001110;
      
     endcase
  endfunction

  always @(posedge slow_clk) begin //{
   
    if(reset) begin //{
      anode_seg <= 4'b1111;
      seven_seg <= 7'b1111111;
      state     <= 3'b000;
    end //}
    else begin //{

      case(state)
        3'b000 : begin 
              anode_seg  <= 4'b1110;
              seven_seg  <= seg_value(ack_out[3:0]);
              state <= 3'b001;
             end
        3'b001:  begin
              anode_seg  <= 4'b1101;
              seven_seg  <= seg_value(ack_out[7:4]);
              state <= 3'b010;
             end
        3'b010: begin
              anode_seg  <= 4'b1011;
              seven_seg  <= seg_value(ack_out[11:8]);
              state <= 3'b011;
             end
        3'b011: begin
              anode_seg  <= 4'b0111;
              seven_seg  <= seg_value(ack_out[15:12]);
              state <= 3'b000;
             end
        default : begin anode_seg <= 4'b1111; end
      endcase
    end //}

  end //}

 endmodule

			

