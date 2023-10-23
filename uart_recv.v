//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved	                               
//----------------------------------------------------------------------------------------
// File name:           uart_recv
// Last modified Date:  2019/10/9 9:56:36
// Last Version:        V1.1
// Descriptions:        UART���ڽ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/10/9 9:56:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module uart_recv#(
    parameter  CLK_FREQ = 50000000,                //ϵͳʱ��Ƶ��
    parameter  UART_BPS = 9600,                    //���ڲ�����
    parameter   DATAWIDTH  =16,
    parameter   CNT_NUM    =2
)
(
    input			  sys_clk,                  //ϵͳʱ��
    input             sys_rst_n,                //ϵͳ��λ���͵�ƽ��Ч
    
    input             uart_rxd,                 //UART���ն˿�
//    output  reg       uart_done,                //����һ֡������ɱ�־
//    output  reg       rx_flag,                  //���չ��̱�־�ź�
//    output  reg [ 3:0] rx_cnt,                  //�������ݼ�����
//    output  reg [ 7:0] rxdata,
//    output  reg [7:0] uart_data                 //���յ�����
    output  reg   uart_all_done,                        
    output  reg   [DATAWIDTH-1:0]    uart_all_data
    );
    
//parameter define
/*parameter  CLK_FREQ = 50000000;                //ϵͳʱ��Ƶ��
parameter  UART_BPS = 9600;                    //���ڲ�����
parameter   DATAWIDTH  =16;
parameter   CNT_NUM    =2;*/
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;       //Ϊ�õ�ָ�������ʣ�
                                                //��Ҫ��ϵͳʱ�Ӽ���BPS_CNT��
//reg define
reg        uart_rxd_d0;
reg        uart_rxd_d1;
reg [15:0] clk_cnt;                              //ϵͳʱ�Ӽ�����

reg       uart_done;
reg       rx_flag;  
reg [ 3:0] rx_cnt;
reg [ 7:0] rxdata;  
reg [7:0] uart_data ;

//wire define
wire       start_flag;

//new var
wire        clk_cnt_mid_flag;
wire        clk_cnt_end_flag;
wire       byte_flag;
reg         [5:0]  num_cnt;
//reg       uart_all_done;
//reg       [DATAWIDTH-1:0]    uart_all_data;
reg       [DATAWIDTH-1:0]    temp_data;
reg         recv_flag;
//clk_cnt_mid_flag
assign clk_cnt_mid_flag  = (clk_cnt == BPS_CNT/2)   ?   1:0;
assign clk_cnt_end_flag  = (clk_cnt == BPS_CNT-1)   ?   1:0;
//byte_flag
assign byte_flag  = (rx_cnt == 4'd9 && clk_cnt_mid_flag==1)   ?   1:0;
//num_cnt
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        num_cnt <= 0;                     
    else if(num_cnt < CNT_NUM)
        if ( byte_flag ==1 ) begin       
            num_cnt <= num_cnt + 1;           
        end
        else begin
            num_cnt <= num_cnt;
        end
    else  begin                          		
        num_cnt <= 0;
    end						
end
//uart_all_done
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n) begin                              
        uart_all_done <= 1'b0;
    end
    else if(rx_cnt == 4'd9 && rx_flag==1 && num_cnt == CNT_NUM-1) begin                    ;                   
        uart_all_done <= 1'b1;                 
    end
    else begin                                   
        uart_all_done <= 1'b0; 
    end    
end
//uart_all_data
always @(*) begin        
    if (!sys_rst_n) begin                               
        uart_all_data = 0;
    end
    else if(rx_cnt == 4'd9 && rx_flag==1 && num_cnt == CNT_NUM-1) begin               //�������ݼ�����������ֹͣλʱ           
        uart_all_data = temp_data;
    end
    else begin
        uart_all_data = 0;                                   
    end    
end
//temp_data
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n) begin
        temp_data <= 0;                               
    end
    else if(recv_flag == 1) begin
        if(rx_cnt == 4'd8 && clk_cnt_end_flag==1) begin             
            temp_data[DATAWIDTH - 1:DATAWIDTH - 8] <= rxdata;
	        temp_data[DATAWIDTH - 9:0] <= temp_data[DATAWIDTH - 1:8];                   
        end
        else begin
            temp_data <= temp_data;
        end
    end
    else begin
        temp_data <= 0;                                   
    end    
end
//recv_flag          
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                                  
        recv_flag <= 1'b0;
    else begin
        if(start_flag)                          //��⵽��ʼλ
            recv_flag <= 1'b1;                    //������չ��̣���־λrx_flag����
                                                //������ֹͣλ�м�ʱ��ֹͣ���չ���
        else if((rx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2) && num_cnt==CNT_NUM-1)
            recv_flag <= 1'b0;                    //���չ��̽�������־λrx_flag����
        else
            recv_flag <= recv_flag;
    end
end
//*****************************************************
//**                    main code
//*****************************************************
//������ն˿��½���(��ʼλ)���õ�һ��ʱ�����ڵ������ź�
assign  start_flag = uart_rxd_d1 & (~uart_rxd_d0);    

//��UART���ն˿ڵ������ӳ�����ʱ������
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if (!sys_rst_n) begin 
        uart_rxd_d0 <= 1'b0;
        uart_rxd_d1 <= 1'b0;          
    end
    else begin
        uart_rxd_d0  <= uart_rxd;                   
        uart_rxd_d1  <= uart_rxd_d0;
    end   
end

//�������ź�start_flag����ʱ��������չ���           
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                                  
        rx_flag <= 1'b0;
    else begin
        if(start_flag)                          //��⵽��ʼλ
            rx_flag <= 1'b1;                    //������չ��̣���־λrx_flag����
                                                //������ֹͣλ�м�ʱ��ֹͣ���չ���
        else if((rx_cnt == 4'd9) && (clk_cnt == BPS_CNT/2))
            rx_flag <= 1'b0;                    //���չ��̽�������־λrx_flag����
        else
            rx_flag <= rx_flag;
    end
end

//������չ��̺�����ϵͳʱ�Ӽ�����
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if ( rx_flag ) begin                   //���ڽ��չ���
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;               	//��ϵͳʱ�Ӽ�����һ�����������ں�����
    end
    else                              				
        clk_cnt <= 16'd0;						//���չ��̽���������������
end

//������չ��̺������������ݼ�����
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        rx_cnt  <= 4'd0;
    else if ( rx_flag ) begin                   //���ڽ��չ���
        if (clk_cnt == BPS_CNT - 1)				//��ϵͳʱ�Ӽ�����һ������������
            rx_cnt <= rx_cnt + 1'b1;			//��ʱ�������ݼ�������1
        else
            rx_cnt <= rx_cnt;       
    end
	 else
        rx_cnt  <= 4'd0;						//���չ��̽���������������
end

//���ݽ������ݼ��������Ĵ�uart���ն˿�����
always @(posedge sys_clk or negedge sys_rst_n) begin 
    if ( !sys_rst_n)  
        rxdata <= 8'd0;                                     
    else if(rx_flag)                            //ϵͳ���ڽ��չ���
        if (clk_cnt == BPS_CNT/2) begin         //�ж�ϵͳʱ�Ӽ���������������λ�м�
            case ( rx_cnt )
             4'd1 : rxdata[0] <= uart_rxd_d1;   //�Ĵ�����λ���λ
             4'd2 : rxdata[1] <= uart_rxd_d1;
             4'd3 : rxdata[2] <= uart_rxd_d1;
             4'd4 : rxdata[3] <= uart_rxd_d1;
             4'd5 : rxdata[4] <= uart_rxd_d1;
             4'd6 : rxdata[5] <= uart_rxd_d1;
             4'd7 : rxdata[6] <= uart_rxd_d1;
             4'd8 : rxdata[7] <= uart_rxd_d1;   //�Ĵ�����λ���λ
             default:;                                    
            endcase
        end
        else 
            rxdata <= rxdata;
    else
        rxdata <= 8'd0;
end

//���ݽ�����Ϻ������־�źŲ��Ĵ�������յ�������
/*always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n) begin
        uart_data <= 8'd0;                               
        uart_done <= 1'b0;
    end
    else if(rx_cnt == 4'd9) begin               //�������ݼ�����������ֹͣλʱ           
        uart_data <= rxdata;                    //�Ĵ�������յ�������
        uart_done <= 1'b1;                      //����������ɱ�־λ����
    end
    else begin
        uart_data <= 8'd0;                                   
        uart_done <= 1'b0; 
    end    
end*/

endmodule	