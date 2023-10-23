`timescale 1ns/1ps
module uart_tb();
	reg CLK;
	reg RSTn;
	reg rs232_rx;
	wire rs232_tx;



initial
 	begin
		RSTn = 0;
		rs232_rx = 1;
		#20
		RSTn = 1;
		#200
		tx_byte();
	end


initial 
 	begin
		CLK = 1;
		forever #2.5 CLK = ~CLK;
	end
task tx_byte();
    begin
			//tx_bit(mem[i]);
/*			tx_bit(8'h22);
			tx_bit(8'h33);
			tx_bit(8'h44);
			tx_bit(8'h55);*/
			tx_bit(8'h5a);
			//tx_bit(8'ha5);
			#100000
			tx_bit(8'h5a);
			//tx_bit(8'ha5);
//			tx_bit(8'ha5);
    end
endtask

task tx_bit(
	input [7:0] data
);
	integer i;
	for (i = 0; i < 10;i=i+1 )
		begin
			case(i)
				0:	rs232_rx <= 1'b0;
				1:	rs232_rx <= data [0];
				2:	rs232_rx <= data [1];
				3:	rs232_rx <= data [2];
				4:	rs232_rx <= data [3];
				5:	rs232_rx <= data [4];
				6:	rs232_rx <= data [5];
				7:	rs232_rx <= data [6];
				8:	rs232_rx <= data [7];
				9:	rs232_rx <= 1'b1;
			endcase
			#8675;
		end
endtask

uart_loopback_top uart_inst(
    .sys_clk       	(CLK),
	.sys_rst_n		(RSTn),
	.uart_rxd 		(rs232_rx),
	.uart_txd  		(rs232_tx));
endmodule
