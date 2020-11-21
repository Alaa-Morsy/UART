//Use this as a template design, follow the information available here, 
//follow the port names, widths, and data provided for them.
//For any unclear information, please refer to other documents provided in this folder. 


/*-------------------------------------------parity_type-------------------------------------------*/
// 00	no parity.										
// 01	odd parity.										
// 10	even parity.									
// 11	use the output parity_out as an odd parity bit and no parity in the serial frame(like 00). 
/*-------------------------------------------------------------------------------------------------*/

/*----baud_rate----*/
// 00	2400 baud.										
// 01	4800 baud.										
// 10	9600 baud.									
// 11	19.2K baud. 
/*----------------*/

//Assume the system clock frequency, for frequency division, is 50MHz.


module parity(
input [1:0] parity_type, 
input [7:0]data_in,
input rst,
output parity_out );
reg parity_out_temp;
assign parity_out = parity_out_temp;
always @(*) 
	if (rst == 1)
		parity_out_temp= 1;
	else
	case(parity_type)
		2'b00: begin//no parity
			 parity_out_temp = 1;
		end 
		
		2'b01:begin // odd parity
			 parity_out_temp =  ~^data_in;// xnor
		end
		
		2'b10:begin // even parity
			 parity_out_temp = ^data_in;// xor
		end 
		
		2'b11: begin // odd parity but not in frame generator
			 parity_out_temp =  ~^data_in;// xnor
		end
		
	endcase
endmodule 


module baud_gen (rst, clock, baud_rate, baud_out);
input clock , rst; // Clock input & Reset input
input [1:0] baud_rate; //user selection
output  baud_out;
reg  counter;
reg [10:0] count;
integer i;

assign baud_out = counter;


always @(baud_rate)
begin
 if (baud_rate == 2'b00)
  begin
     
        i=1302;     
          
  end
 else if(baud_rate == 2'b01)
  begin
         
        i=651;  

  end
else if (baud_rate == 2'b10)
  begin
         
   i=326;
     
  end
 else
  begin
         
   i=163;
       
  end
end

initial
begin
count <= 10'b0;
counter <= 1'b0;
end

always @(posedge clock or posedge rst)
begin
if(rst == 1)
 count <= 10'b0;
else
 count <= count + 10'b1;
end
/*---------------------------------------*/
always @(count)
begin
if((count%i) == 0)
 counter <= ~counter;
else
 counter <= counter ;
end
endmodule


module frame_gen(
input rst,
 input [7 :0] data_in,
 input parity_out,
 input [1:0]parity_type,
 input stop_bits,        //low 1
 input data_length, 
output [11:0]frame_out);

reg [8:0] frame_out_nostop ;//without stop bits
reg [11:0]frame_outreg;
reg [7:0] data_in_use ;


always @(rst or data_in or parity_type or stop_bits or data_length or parity_out)

if (rst) 
 frame_outreg = 12'b1111_1111_1111;
else
 begin
data_in_use = data_in ;
case (parity_type)

2'b01,2'b10:
 begin
   if (~data_length)//7 bits
    begin
     // data_in_use ={data_in_use, parity_out};
      frame_out_nostop = { 1'b0 , {data_in_use, parity_out} }; //8 bits
      frame_outreg = stop_bits ?{frame_out_nostop,2'b11}:{frame_out_nostop,1'b1} ; //10 : 9 bits for 7 bits data,
     end
   else
     begin
      frame_out_nostop = { 1'b0 , data_in_use ,parity_out }; //9bits
      frame_outreg = stop_bits ?{frame_out_nostop,2'b11}:{frame_out_nostop,1'b1} ; //11:10 bits for 8 bits data,  
     end                                                                              
end

default:
 begin
   if (~data_length)//7 bits
    begin
       // {data_in_use,1'b1}; //adding the 1st stop bit
       frame_out_nostop = { 1'b0 , {data_in_use,1'b1} }; //8 bits
      if(stop_bits)//want 2 stop bits
        frame_outreg ={frame_out_nostop ,1'b1};
      else
       frame_outreg = frame_out_nostop ;
    end
   else
      begin
        frame_out_nostop = { 1'b0 , data_in_use}; //9bits
      frame_outreg = stop_bits ?{ frame_out_nostop,2'b11}:{ frame_out_nostop,1'b1};   
      end
 end
endcase
end
assign frame_out = frame_outreg;
endmodule 

module piso(rst, frame_out,parity_out, parity_type,stop_bits, data_length, send, baud_out, data_out, p_parity_out, tx_active, tx_done);
input rst;           //if rst=1 will rst
input[11:0] frame_out;   //data_in+parity out
input parity_out;
input [1:0] parity_type;	//refer to the block comment above. 
input stop_bits;     //low when using 1 stop bit, high when using two stop bits
input data_length;   //low when using 7 data bits, high when using 8
input  send;
input baud_out;
output reg data_out;     //Serial data_out
output reg p_parity_out; //parallel odd parity output, low when using the frame parity.
output reg tx_active;
output reg tx_done;

reg[11:0]in;
reg[3:0]count;

initial  //initial_conditions
begin
  count=4'b0000;
  in=frame_out;
  data_out=1'b1;

if (parity_type==2'b11)
begin
data_out= parity_out;              //odd parity
end
end

always@(posedge baud_out)//for count
begin
 if(send)
  begin
   count=count+1'b1;
  end
end

always@(baud_out )//for tx_done
begin
 if((count==4'b1011 ) && (data_length==0))//7bit
  begin
   tx_done=1'b1;
   tx_active=1'b0;
 end
 if((count==4'b1100) &&( data_length==1))//8bit
  begin
   tx_done=1'b1;
   tx_active=1'b0;
  end
end


always@(posedge baud_out)//for rst
begin
 if(rst)
  begin
   count<=4'b0000;
   data_out<=1'b1;
   p_parity_out<=1'b0;
   tx_active<=1'b0;
   tx_done<=1'b0;
  end
end


always@(posedge baud_out)//for shift
begin


if((send==1)&&(count<4'b1100)&&(rst==0))
begin
tx_active<=1'b1;
case(parity_type)//parity case

2'b00,2'b10,2'b01:begin
if(tx_done==0)//not complete data
begin
p_parity_out=1'b0;
data_out=in[0];
in<=in>>1'b1;
end//for if statement (tx_done)

//else
//begin
//data_out=1'b1;
//end//for else

end //for first case

2'b11:begin
if(tx_done==0)
begin
  p_parity_out=1'b1;
 
  data_out=in[0];
  in<=in>>1'b1;
end
//else
//begin
//data_out=1'b1;
//end
end//second case

default:begin
data_out<=1'b1;
end//default

endcase//for case
end//for if
else//send==0
begin
data_out<=1'b1;
tx_active<=1'b0;
tx_done<=1'b0;
end//for else

end//for always

endmodule

module uart_tx(
	//DO NOT EDIT any part of this port declaration
	input 		clock, rst, send,
	input [1:0]	baud_rate,
	input [7:0]     data_in, 
	input [1:0]    parity_type, 	//refer to the block comment above. 
	input 		stop_bits, 		//low when using 1 stop bit, high when using two stop bits
	input 		data_length, 	//low when using 7 data bits, high when using 8.
	
	output  	data_out, 		//Serial data_out
	output 	  	p_parity_out, 	//parallel odd parity output, low when using the frame parity.
	output  	tx_active, 		//high when Tx is transmitting, low when idle.
	output  	tx_done 		//high when transmission is done, low when not.
	);

	//You MAY EDIT these signals, or module instantiations.
	wire parity_out;
	wire  [11:0] frame_out;
	
	//sub_modules
	
	parity		parity_gen1 (.rst(rst), .data_in(data_in), .parity_type(parity_type), .parity_out(parity_out));
	frame_gen	frame_gen1  (.rst(rst), .data_in(data_in),  .parity_out(parity_out), .parity_type(parity_type), .stop_bits(stop_bits), .data_length(data_length), .frame_out(frame_out));
	baud_gen	baud_gen1	(.rst(rst), .clock(clock), .baud_rate(baud_rate), .baud_out(baud_out));	
	piso		shift_reg1	(.rst(rst), .frame_out(frame_out), .parity_out(parity_out),.parity_type(parity_type),.stop_bits(stop_bits), .data_length(data_length), .send(send),.baud_out(baud_out), .data_out(data_out), .p_parity_out(p_parity_out), .tx_active(tx_active), .tx_done(tx_done));
	
 
endmodule 
module UART_test ;
        reg	clock, rst, send;
	reg [1:0] buad_rate;
	reg [7:0] data_in; 
	reg [1:0] parity_type;	//refer to the block comment above. 
	reg 	stop_bits;		//low when using 1 stop bit, high when using two stop bits
	reg 	data_length; 	//low when using 7 data bits, high when using 8.
	
	wire 	data_out;		//Serial data_out
	wire 	p_parity_out; 	//parallel odd parity output, low when using the frame parity.
	wire 	tx_active;		//high when Tx is transmitting, low when idle.
	wire 	tx_done;

initial
begin
  clock =0;
  forever #20 clock =~clock;
end

initial
 begin
   rst=1;
/*********1st*********/
#5
        rst=0;
        send =1'b1;
        buad_rate =2'b11; //19.2k
	data_in =7'b110_1010; 
	 parity_type = 2'b00; //no parity	 
	stop_bits =1'b0;//1 stop		
	data_length =1'b0;//7bits
// the expected output:
//*********************0_110_1010_1**** 	

#500 /****2nd*****/
        send =1'b1;
        buad_rate =2'b11; //19.2k
	data_in =7'b110_1010; 
	 parity_type = 2'b01; //odd parity	 
	stop_bits =1'b0;//1 stop		
	data_length =1'b0;//7bits
// the expected output:
//*********************0_110_1010_1_1**** 	

#500  /******3rd*****/
        send =1'b1;
        buad_rate =2'b11; //19.2k
	data_in =7'b110_1010; 
	 parity_type = 2'b10; //even parity	 
	stop_bits =1'b1;//2 stop		
	data_length =1'b0;//7bits
// the expected output:
//*********************0_110_1010_0_11**** 	
#20
   rst=1;

#500 /******4th*****/
        rst=0;
        send =1'b1;
        buad_rate =2'b01; //4800
	data_in =8'b1100_1010; 
	 parity_type = 2'b11; //odd out parity	 
	stop_bits =1'b0;//1 stop		
	data_length =1'b1;//8bits
// the expected output:
//*********************0_1100_1010_1 and 1 **** 	




end
uart_tx tst1(
	//inputs
	clock, rst, send,buad_rate, data_in,  parity_type, 	
        stop_bits,data_length, 	
	//outputs
	data_out,p_parity_out, tx_active,tx_done );

initial
begin
   $display(,,"\t\t rst  data_in",,"  data_out  p_parity_out   tx_active  tx_done");
   $monitor($time,,"%b     %h        %b     %b     %b     %b",rst,data_in,data_out,p_parity_out, tx_active,tx_done);
end
endmodule
