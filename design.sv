//DESIGN OF 8- BIT ALU
//DEVELOPED BY: AASHI SRIVASTAVA
//DATE: 10-07-24
//---------------------------------------------------------------
module alu_8bit(in1,in2,out,sel,clk,rst);
  input [7:0] in1,in2;
  output reg [7:0] out;
  input [1:0] sel;
  input clk,rst;
  
  always @(posedge clk)begin
    if(rst)
      out<=0;
    else begin
      if(sel==2'd0)
        out<=in1+in2;
      else if(sel==2'd1)
        out<=in1-in2;
      else if(sel==2'd2)
        out<=in1*in2;
      else
        out<=in1/in2;
    end
  end
endmodule

interface intf(input clk,rst);
  logic [7:0] in1,in2;
  logic [7:0] out;
  logic [1:0] sel;
endinterface
      