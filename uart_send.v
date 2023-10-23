//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved	                               
//----------------------------------------------------------------------------------------
// File name:           uart_send
// Last modified Date:  2019/10/9 10:07:36
// Last Version:        V1.1
// Descriptions:        UART���ڷ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/10/9 10:07:36
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module uart_send#(
    parameter  CLK_FREQ = 200000000,                //ϵͳʱ��Ƶ��
    parameter  UART_BPS = 115200,                    //���ڲ�����
    parameter   DATAWIDTH  =16,
    parameter   CNT_NUM    =2
)
(
    input	      sys_clk,                  //ϵͳʱ��
    input         sys_rst_n,                //ϵͳ��λ���͵�ƽ��Ч
    
    input         uart_en,                  //����ʹ���ź�
    input  [DATAWIDTH-1:0]  uart_din,                 //����������
    output        uart_tx_busy,             //����æ״̬��־ 
    output        en_flag     ,
    output  reg   tx_flag,                  //���͹��̱�־�ź�
    output  reg [ DATAWIDTH-1:0] tx_data,             //�Ĵ淢������
    output  reg [ 3:0] tx_cnt,              //�������ݼ�����
    output  reg   uart_txd                  //UART���Ͷ˿�
    );
    
//parameter define
localparam  BPS_CNT  = CLK_FREQ/UART_BPS;   //Ϊ�õ�ָ�������ʣ���ϵͳʱ�Ӽ���BPS_CNT��

//reg define
reg        uart_en_d0; 
reg        uart_en_d1;  
reg [15:0] clk_cnt;                           //ϵͳʱ�Ӽ�����

//wire define
//wire       en_flag;
//new var
wire        clk_cnt_mid_flag;
wire        clk_cnt_end_flag;
wire        clk_cnt_16_flag;
wire       byte_flag;
reg         [5:0]  num_cnt;
//reg       uart_all_done;
//reg       [DATAWIDTH-1:0]    uart_all_data;
reg       [DATAWIDTH-1:0]    temp_data;
reg         sending_flag;
//clk_cnt_mid_flag
assign clk_cnt_mid_flag  = (clk_cnt == BPS_CNT/2)   ?   1:0;
assign clk_cnt_end_flag  = (clk_cnt == BPS_CNT-1)   ?   1:0;
assign clk_cnt_16_flag  = (clk_cnt == BPS_CNT - (BPS_CNT/16))   ?   1:0;
//byte_flag
assign byte_flag  = (tx_cnt == 4'd9 && clk_cnt_16_flag==1)   ?   1:0;
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
//sending_flag
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        sending_flag <= 1'b0;
    end 
    else if (en_flag) begin                 //��⵽����ʹ��������                      
            sending_flag <= 1'b1;                //���뷢�͹��̣���־λtx_flag����
        end                                           //������ֹͣλ����ʱ��ֹͣ���͹���
        else if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16)) && num_cnt == CNT_NUM-1) begin                                       
            sending_flag <= 1'b0;
        end
        else begin
            sending_flag <= sending_flag;        
        end 
end
//temp_data
/*always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n) begin
        temp_data <= 0;                               
    end
    else if(sending_flag == 1) begin
        if(tx_cnt == 4'd8 && clk_cnt_end_flag==1) begin             
            temp_data[DATAWIDTH - 1:DATAWIDTH - 8] <= tx_data;
	        temp_data[DATAWIDTH - 9:0] <= temp_data[DATAWIDTH - 1:8];                   
        end
        else begin
            temp_data <= temp_data;
        end
    end
    else begin
        temp_data <= 0;                                   
    end    
end*/
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
       // temp_data <= 0;
        tx_data <= 0;
    end 
    else if (en_flag) begin
        tx_data <= uart_din;
    end
    else if (sending_flag) begin
        if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16))) begin                                                                                              
            tx_data[DATAWIDTH - 9:0] <= tx_data[DATAWIDTH - 1:8];
        end
        else begin
            tx_data <= tx_data;
        end 
    end
    else begin
        tx_data <= 0;                                   
    end
end
//*****************************************************
//**                    main code
//*****************************************************
//�ڴ��ڷ��͹����и���æ״̬��־
assign uart_tx_busy = sending_flag;

//����uart_en�����أ��õ�һ��ʱ�����ڵ������ź�
assign en_flag = (~uart_en_d1) & uart_en_d0;

//�Է���ʹ���ź�uart_en�ӳ�����ʱ������
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin
        uart_en_d0 <= 1'b0;                                  
        uart_en_d1 <= 1'b0;
    end                                                      
    else begin                                               
        uart_en_d0 <= uart_en;                               
        uart_en_d1 <= uart_en_d0;                            
    end
end

//�������ź�en_flag����ʱ,�Ĵ�����͵����ݣ������뷢�͹���          
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n) begin                                  
        tx_flag <= 1'b0;
 //       tx_data <= 8'd0;
    end 
    else if (en_flag) begin                 //��⵽����ʹ��������                      
                tx_flag <= 1'b1;                //���뷢�͹��̣���־λtx_flag����
//                tx_data <= uart_din;            //�Ĵ�����͵�����
    end
    else if (sending_flag) begin
        //if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT - (BPS_CNT/16))) begin  
        if ((tx_cnt == 4'd9) && (clk_cnt == BPS_CNT-1)) begin                                      
                tx_flag <= 1'b0;                //���͹��̽�������־λtx_flag����
 //               tx_data <= 8'd0;
        end
        else if (tx_cnt == 4'd10) begin
            tx_flag <= 1'b1;
        end
        else begin
                tx_flag <= tx_flag;
 //               tx_data <= tx_data;
        end 
    end
    else begin
        tx_flag <= 0;
    end
     
end

//���뷢�͹��̺�����ϵͳʱ�Ӽ�����
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        clk_cnt <= 16'd0;                                  
    else if (tx_flag) begin                 //���ڷ��͹���               //tx_flag�ĳ���sending_flag
        if (clk_cnt < BPS_CNT - 1)
            clk_cnt <= clk_cnt + 1'b1;
        else
            clk_cnt <= 16'd0;               //��ϵͳʱ�Ӽ�����һ�����������ں�����
    end
    else                             
        clk_cnt <= 16'd0; 				    //���͹��̽���
end

//���뷢�͹��̺������������ݼ�����
always @(posedge sys_clk or negedge sys_rst_n) begin         
    if (!sys_rst_n)                             
        tx_cnt <= 4'd0;
    else if (tx_flag) begin                 //���ڷ��͹���
        if (clk_cnt == BPS_CNT - 1)			//��ϵͳʱ�Ӽ�����һ������������
            tx_cnt <= tx_cnt + 1'b1;		//��ʱ�������ݼ�������1
        else
            tx_cnt <= tx_cnt;       
    end
    else                              
        tx_cnt  <= 4'd0;				    //���͹��̽���
end

//���ݷ������ݼ���������uart���Ͷ˿ڸ�ֵ
always @(posedge sys_clk or negedge sys_rst_n) begin        
    if (!sys_rst_n)  
        uart_txd <= 1'b1;        
    else if (sending_flag)
        case(tx_cnt)
            4'd0: uart_txd <= 1'b0;         //��ʼλ 
            4'd1: uart_txd <= tx_data[0];   //����λ���λ
            4'd2: uart_txd <= tx_data[1];
            4'd3: uart_txd <= tx_data[2];
            4'd4: uart_txd <= tx_data[3];
            4'd5: uart_txd <= tx_data[4];
            4'd6: uart_txd <= tx_data[5];
            4'd7: uart_txd <= tx_data[6];
            4'd8: uart_txd <= tx_data[7];   //����λ���λ
            4'd9: uart_txd <= 1'b1;         //ֹͣλ
            default: uart_txd <= 1'b1;
        endcase
    else 
        uart_txd <= 1'b1;                   //����ʱ���Ͷ˿�Ϊ�ߵ�ƽ
end

endmodule	          