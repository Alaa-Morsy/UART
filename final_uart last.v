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
input rst,
input [7:0]data_in,
input [1:0] parity_type, 
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
reg [10:0] count1;
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
         
   i=2;
       
  end
end

initial
begin
count1 = 10'b0000_0000_00;//change
counter = 1'b0;
end

always @(posedge clock or posedge rst)
begin
if(rst == 1)
 count1 <= 10'b0;
else
 count1 <= count1 + 1'b1; //change from 10'b1 to 1'b1
end
/*---------------------------------------*/
always @(count1)
begin
if((count1%i) == 0)
 counter <= ~counter;
else
 counter <= counter ;
end
endmodule


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

module piso(rst, frame_out, parity_out, parity_type,stop_bits, data_length, send, baud_out, data_out, p_parity_out, tx_active, tx_done);
input rst;           //if rst=1 will rst
input  [10:0]frame_out;   //data_in+parity out
input parity_out;
input [1:0] parity_type;	//refer to the block comment above. 
input stop_bits;     //low when using 1 stop bit, high when using two stop bits
input data_length;   //low when using 7 data bits, high when using 8
input  send;
input baud_out;
output  data_out;     //Serial data_out
output   p_parity_out; //parallel odd parity output, low when using the frame parity.
output   tx_active;
output   tx_done;


reg tx_active_reg;
assign tx_active=tx_active_reg;
reg data_out_reg;
assign data_out=data_out_reg;
reg tx_done_reg;
assign tx_done=tx_done_reg;
reg p_parity_out_reg;
assign p_parity_out=p_parity_out_reg;




reg[10:0]in;
reg[3:0]count;



initial  //initial_conditions
begin
 
  count=4'b0000;
 // in=frame_out;
  data_out_reg=1'b1;
  tx_done_reg=1'b0;
  tx_active_reg=1'b0;
  p_parity_out_reg=1'b0;
 
 $monitor("%b,%b,%b,%b,%b",frame_out,in,data_out_reg,parity_out,baud_out);

if (parity_type==2'b11)
begin
data_out_reg= parity_out;              //odd parity
end
end

always @(frame_out) begin
  in <= frame_out;
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
   tx_done_reg=1'b1;
   tx_active_reg=1'b0;
 end
 if((count==4'b1100) &&( data_length==1))//8bit
  begin
   tx_done_reg=1'b1;
   tx_active_reg=1'b0;
  end
end





always@(posedge baud_out)//for rst
begin
 if(rst)
  begin
   count<=4'b0000;
   data_out_reg<=1'b1;
   p_parity_out_reg<=1'b0;
   tx_active_reg<=1'b0;
   tx_done_reg<=1'b0;


  end
end


always@(posedge baud_out)//for shift
begin


if((send==1)&&(count<=4'b1100)&&(rst==0))
begin
tx_active_reg<=1'b1;
case(parity_type)//parity case

2'b00,2'b10,2'b01:begin
                //  if(tx_done==0)//not complete data
                 // begin
                   p_parity_out_reg<=1'b0;//c
                   data_out_reg=in[0];//c
                   in=in>>1;
                  // in={0,in[11:1]};
// $display("%b,%b",in,data_out_reg);
                //  end//for if statement (tx_done)

                //  else
                //  begin
                //   data_out=1'b1;
                 // end//for else
                  end //for first case

2'b11:begin
  //    if(tx_done==0)
   //   begin
       p_parity_out_reg=parity_out;
       data_out_reg=in[0];
       in=in>>1;
      //in={0,in[11:1]};
    //  end
    //  else
    //  begin
     // data_out=1'b1;
     // end
      end//second case

default:begin
       data_out_reg<=1'b1;
       end//default

endcase//for case
end//for if

else//send==0
begin
data_out_reg<=1'b1;
tx_active_reg<=1'b0;
tx_done_reg<=1'b0;
end//for else

end//for always

//always@(posedge baud_out)
//$display("%b,%b,%b",in,frame_out,data_out);

endmodule


module uart_tx(clock, rst, send,baud_rate,data_in,parity_type,stop_bits,data_length,data_out,p_parity_out,tx_active,tx_done);


        input 		clock, rst, send;
	input [1:0]	baud_rate;
	input [7:0]     data_in;
	input [1:0]    parity_type; 	//refer to the block comment above. 
	input 		stop_bits; 		//low when using 1 stop bit, high when using two stop bits
	input 		data_length; 	//low when using 7 data bits, high when using 8.
	
	output       data_out; 		//Serial data_out
	output       p_parity_out; 	//parallel odd parity output, low when using the frame parity.
	output       tx_active;		//high when Tx is transmitting, low when idle.
	output       tx_done ;	//high when transmission is done,

	//You MAY EDIT these signals, or module instantiations.
	wire parity_out;
	wire[11:0] frame_out;
        wire baud_out;
	//sub_modules
initial
begin
	//$monitor("%b,%b,%b,%b",frame_out,data_out,parity_out,baud_out);
end
	
	parity		parity_gen1 (rst, data_in, parity_type, parity_out);
	baud_gen	baud_gen1   (rst, clock, baud_rate, baud_out);
       frame_gen	frame_gen1  (rst, data_in, parity_out, parity_type, stop_bits, data_length, frame_out);
	piso		shift_reg1  (rst, frame_out,parity_out, parity_type,stop_bits, data_length, send, baud_out, data_out, p_parity_out, tx_active, tx_done);
endmodule 



/*module uart_tb();

	reg 		clock, rst, send;
	reg [1:0]	baud_rate;
	reg [7:0]     data_in;
	reg [1:0]    parity_type; 	//refer to the block comment above. 
	reg 		stop_bits;		//low when using 1 stop bit, high when using two stop bits
	reg 		data_length;	//low when using 7 data bits, high when using 8.
	
	  wire	data_out,		//Serial data_out
	   	p_parity_out, 	//parallel odd parity output, low when using the frame parity.
	  	tx_active, 		//high when Tx is transmitting, low when idle.
	  	tx_done ;	


uart_tx     g1(
	 		clock, rst, send,
	 	baud_rate,
	     data_in, 
	    parity_type, 	//refer to the block comment above. 
	 		stop_bits, 		//low when using 1 stop bit, high when using two stop bits
	 		data_length, 	//low when using 7 data bits, high when using 8.
	
	  	data_out, 		//Serial data_out
	   	p_parity_out, 	//parallel odd parity output, low when using the frame parity.
	  	tx_active, 		//high when Tx is transmitting, low when idle.
	  	tx_done ,		//high when transmission is done, low when not.

                baud_out
	);
always
forever #100 clock=~clock;

initial begin
$monitor ("%t   baud_out=%b data=%h     clk= %b      parity_type= %h      stop=%b       length =%b      out=%b", $time,baud_out ,data_in , clock, parity_type, stop_bits, data_length, data_out);

	rst<=0;
	send<=1;
	clock <=0;
	baud_rate<=11;
	parity_type<=1;
	stop_bits<=0;
	data_length<=1;
	data_in<= 8'b0100_0010;
	
end
endmodule*/
module UART_test1 ;
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
//*********************0_110_1010_1**** 6a
//#490 rst=1;
#1900 /****2nd*****/
    rst=0;    
        send =1'b1;
        buad_rate =2'b11; //19.2k
	data_in =7'b101_1010; 
	 parity_type = 2'b01; //odd parity	 
	stop_bits =1'b0;//1 stop		
	data_length =1'b0;//7bits
// the expected output:
//*********************0_101_1010_1_1**** 5a	
//#490 rst=1;
#1900 /******3rd*****/
        rst=0;
        send =1'b1;
        buad_rate =2'b11; //19.2k
	data_in =7'b110_1001; 
	 parity_type = 2'b10; //even parity	 
	stop_bits =1'b1;//2 stop		
	data_length =1'b0;//7bits
// the expected output:
//*********************0_110_1010_0_11****69 	
#1900
   rst=1;

#5 /******4th*****/
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
    $display(,,"\t rst  data_in",,"  data_out  p_parity_out   tx_active  tx_done");
   $monitor($time,,"%b     %h        %b     %b     %b     %b ",rst,data_in,data_out,p_parity_out, tx_active,tx_done);
end
endmodule
