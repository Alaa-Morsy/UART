
module frame_gen(
input rst,
 input [7:0] data_in,
 input parity_out,
 input [1:0]parity_type,
 input stop_bits,        //low 1
 input data_length, 
output [11:0]frame_out);

reg [10:0] frame_out_reverse ;//reverse the bits order
reg [10:0]frame_outreg;
reg [7:0] data_in_use ;

integer i;

always@(frame_outreg )//for reverse the frame
begin
for(i=0;i<11;i=i+1)
frame_out_reverse[i]=frame_outreg[10-i];
end




always @(rst or data_in or parity_type or stop_bits or data_length)


if (rst) 
 frame_outreg = 12'b1111_1111_1111;
else
 begin
frame_outreg = 11'b1111_1111_111;
data_in_use= data_in;
case (parity_type)


2'b01,2'b10:
 begin
   if (~data_length)//7 bits
    begin
    
     frame_outreg[10]=1'b0;//start bit
    frame_outreg [9:2]= {data_in_use[6:0],parity_out};
    
     end
   else
     begin

     frame_outreg[10]=1'b0;//start bit
      frame_outreg [9:1]= {data_in_use,parity_out};//11:10 bits for 8 bits data,  
     end                                                                              
end

default:
 begin
   if (~data_length)//7 bits
    begin

     frame_outreg[10]=1'b0;//start bit
      frame_outreg [9:3]= data_in_use[6:0];
     end

   else
      begin

      frame_outreg[10]=1'b0;//start bit
      frame_outreg [9:2]= data_in_use;
end
 end
endcase
end
assign frame_out = frame_out_reverse;

endmodule 


/************test bench ********************/
module test_frame_gen ();
 reg rst;
 reg [7:0] data_in;
 reg parity_out;
 reg [1:0]parity_type;
 reg stop_bits;        //low 1
 reg data_length; 

wire [10:0]frame_out;

initial
 begin
  #2
 rst=1;
 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b00;      //no parity
  stop_bits = 1'b0;        //1 stop bit
  data_length = 1'b0;      //7 bits
  data_in = 7'b 110_0110;  // the expected output : 1_0110_011_0 #4

  #2
 rst=1;
 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b01;   //have parity
  stop_bits = 1'b0;        //1 stop bit
  data_length = 1'b0;    //7bits
  data_in = 7'b 110_0110; //the expected output : 0_110_0110_1_1-->11_0110_011_0 #8
 #2
 rst=1;
 #2
 rst=0;
  parity_out = 1'b1;
  parity_type = 2'b00;      //no parity
  stop_bits = 1'b0;        //1 stop bit
  data_length = 1'b1;      //8 bits
  data_in = 8'b 1101_0110;  // the expected output : 0_1101_0110_1-->1011010110 #12
 #2
 rst=1;
 
 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b01;   //have parity
  stop_bits = 1'b0;        //1 stop bit
  data_length = 1'b1;    //8bits
  data_in = 8'b 1101_0110; //the expected output : 0_1101_0110_1_1-->11011010110 #16
  #2
 rst=1;
 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b00;      //no parity
  stop_bits = 1'b1;        //2 stop bit
  data_length = 1'b0;      //7 bits
  data_in = 7'b 110_0110;  // the expected output : 0_110_0110_11-->1101100110 #20
 
 #2
 rst=1;
 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b01;   //have parity
  stop_bits = 1'b1;        //2 stop bit
  data_length = 1'b0;    //7bits
  data_in = 7'b 110_0110; //the expected output : 0_110_0110_1_11-->11101100110 #24
 #2
 rst=1;

 #2
  rst=0;
  parity_out = 1'b1;
  parity_type = 2'b00;      //no parity
  stop_bits = 1'b1;        //2 stop bit
  data_length = 1'b1;      //8 bits
  data_in = 8'b 1101_0110;  // the expected output : 0_1101_0110_11-->11011010110 #28

  #2
 rst=1;
 #2
  rst=0;
  parity_out = 1'b0;
  parity_type = 2'b01;   //have parity
  stop_bits = 1'b1;        //2 stop bit
  data_length = 1'b1;    //8bits
  data_in = 8'b 1101_0110; //the expected output : 0_1101_0110_0_1-->10011010110 #32


end
frame_gen	frame_gen1  (rst, data_in, parity_out, parity_type, stop_bits, data_length, frame_out);
	
initial
$monitor ($time ,,"//the expected output : %b",frame_out);
endmodule
