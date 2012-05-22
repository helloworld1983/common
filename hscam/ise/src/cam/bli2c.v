module bli2c(
    input clk,
    input init,
	 input tv,
	 input [1:0] fr,
    input [5:0] igain,
    input [7:0] oneg,
    input [7:0] opos,
    input [7:0] ocompen,
    inout sda,
    output reg scl,
    output reg endet,
	 output reg tecp,
	 output reg tecn,
	 output reg in,
	 output reg [9:0] itemp,
	 output reg otest	
    );
//FSM i2c
    parameter s_wait = 0;//�������� tv ��� tvt
    parameter s_start = 1;//���� 
	 parameter s_receive = 2;//����� ������ �� ����������(8��� �������� 16 ��� �����), ����� �������
    parameter s_trans = 3;//�������� 24 �����,�������� ������(��� �� ������)
    parameter s_stop = 4;//��������� �����
	 parameter s_pause = 5;//����� ����� �������� � �������� ������������	
    parameter s_err = 6;//��������� ���� ��������� � ������� �� �����
//FSM ������� �����������	 
    parameter t_wait = 0;//�������� ���������� ������ ��������� ����������� ��� TEC
	 parameter t_mes1 = 1;//1-�� ���������(8192)
	 parameter t_mes2 = 2;//2-�� ���������(4096)
	 parameter t_mes3 = 3;//3-�� ���������(2048)
	 parameter t_mes4 = 4;//4-�� ���������(1024)
	 parameter t_mes5 = 5;//5-�� ���������(512)
	 parameter t_mes6 = 6;//6-�� ���������(256)
	 parameter t_mes = 7;//���������� ���������(64)
	 
	 parameter tmin = 10'h3f8;//���� ����(-6)����������� �������� �����������
	 parameter tmax = 10'h12c;//���� ����(+75)����������� �������� �����������
//���������� ����������
	 reg [2:0] statet;//FSM ������� �����������
    reg [2:0] state;//FSM i2c 
    reg [7:0] cbsync;//������� ���������    
	 reg [4:0] cbbit;//������� �����
	 reg [3:0] cbdata;//������� ������� � �������� ������������
    reg [27:0] odata;//������������ ���������� ������   
    reg [9:0] idata;//����������� ������
//    reg in;//������� ������� sda
    reg ent;//��������� ��������� �����������
	 reg [10:0] cbtv;//������� ��������� ����� ����������� �����������
	 reg zsda;//������������ sda � ������ ���������(����� ������ �� ������� ���������)
	 reg od;
	 reg [9:0] iitemp;//���������� �������� �����������
	 reg enmes;//���������� ������ ��������� ����������� ��� TEC
	 reg imes,mes;//��������� ����������� ��� TEC
	 reg [3:0] cbmes;//������� �� ������ ��������� ����������� ��� TEC
	 reg [13:0] cbtec;//��� ��� TEC
	 reg [13:0] entec;//����� ��������� TEC
assign sda = (zsda)? 1'bz: od;

always @(posedge clk)
begin if (init) begin scl <= 1; endet <= 0; tecp <= 0; tecn <= 0; state <= s_wait; cbsync <= 0; 
                      cbbit <= 0; od <= 1; zsda <= 0; cbdata <= 0; ent <= 0; cbtv <= 0; itemp <= 10'h3ff;
							 enmes <= 0; cbmes <= 0; cbtec <=0; entec <=0; statet <= t_wait; end
  
  else begin begin in <= sda; 
                   cbtv <= (ent)? 0: (tv)? cbtv+1: cbtv;
						 ent <= ((fr==0&&cbtv==240)||(fr==1&&cbtv==480)||(fr==2&&cbtv==960)||(fr==3&&cbtv==1920))? 1:
							     (state==s_receive)? 0: ent;//��������� ����������� ��� � 4��� 
						 cbtec <= (cbtec==0)? 16383: cbtec-1;
						 tecp <= (cbtec==0)? 0: (cbtec==entec)? 1: tecp; tecn<= 1'b0; 
						 cbmes <= (cbmes==4)? 0: (state==s_receive&&cbbit==28&&cbsync==100)? cbmes+1: cbmes;
						 enmes <= (cbmes==4)? 1: enmes;
						 imes <= (enmes&&cbmes==3&&cbbit==28&&cbsync==100)? 1: 0; mes <= imes;
						 otest <= (state==s_start&&ent&&cbsync==50)? 1: 0;	end	
case (state)	   
			s_wait : begin  state <= (tv)? s_start: state; 
		                   zsda <= 0; cbsync <= 0; cbbit <= 0; cbdata <= 0; end	    			   
			s_start : begin state <= (ent&&cbsync==50)? s_receive: (cbsync==50)? s_trans: state;
                         scl <= (cbsync==50)? 0: 1;
								 od <= 0;
								 cbsync <= (cbsync==50)? 0: cbsync+1; 
								 odata <= (ent&&cbsync==50)? {7'h48,2'b10,19'h0}:
								          (cbdata==0&&cbsync==50)? {7'h2c,2'b00,9'h0,~igain,4'b0}:
											 (cbdata==1&&cbsync==50)? {7'h2c,2'b00,9'h100,opos,2'b0}:
											 (cbdata==2&&cbsync==50)? {7'h2d,2'b00,9'h0,oneg,2'b0}: {7'h2d,2'b00,9'h100,ocompen,2'b0}; end
			s_receive: begin state <= (cbbit==9&&cbsync==150&&in!=0)? s_err: (cbbit==28&&cbsync==100)? s_stop: state;
								  scl <= (cbsync==100)? 1: (cbsync==200)? 0: scl;
								  od <= (cbsync==50)? odata[27]: od;
								  odata <= (cbsync==50)? {odata[26:0],1'b1}: odata;
								  zsda <= (cbbit>=9&&cbbit<=17||cbbit>=19&&cbbit<=27)? 1: 0;
								  idata <= (cbsync==150&&(cbbit>=10&&cbbit<=17||cbbit>=19&&cbbit<=20))? {idata[8:0],in}: idata;
								  itemp <= (cbbit==28&&cbsync==100)? idata: itemp;
								  iitemp <= (cbbit==28&&cbsync==100)? itemp: iitemp;
								  cbbit <= (cbbit==28&&cbsync==100)? 0: (cbsync==50)? cbbit+1: cbbit;
								  cbsync <= ((cbbit==28&&cbsync==100)||cbsync==200)? 0: cbsync+1; end		
			s_trans : begin  state <= ((cbbit==9||cbbit==18||cbbit==27)&&cbsync==150&&in!=0)? s_err: (cbbit==28&&cbsync==100)? s_stop: state;
								  scl <= (cbsync==100)? 1: (cbsync==200)? 0: scl;
								  od <= (cbsync==50)? odata[27]: od;
								  odata <= (cbsync==50)? {odata[26:0],1'b1}: odata;
								  zsda <= (cbbit==9||cbbit==18||cbbit==27)? 1: 0;
								  cbbit <= (cbbit==28&&cbsync==100)? 0: (cbsync==50)? cbbit+1: cbbit;
								  cbsync <= ((cbbit==28&&cbsync==100)||cbsync==200)? 0: cbsync+1; 
								  cbdata <= (cbbit==28&&cbsync==100)? cbdata+1: cbdata; end
	      s_stop :  begin  state <= (cbsync==50)? s_pause: state;
								  scl <= 1;
								  od <= (cbsync==50)? 1: 0;
								  zsda <= 0; 
								  cbsync <= (cbsync==50)? 0: cbsync+1; end		   
			s_pause : begin  state <= (cbsync==200&&cbdata==4)? s_wait: (cbsync==200)? s_start: state;
								  cbsync <= (cbsync==200)? 0: cbsync+1; end	
	      s_err : begin  state <= s_wait; scl <= 1; od <= 1; zsda <= 0; cbsync <= 0; cbbit <= 0; cbdata <= 0; end         
	   endcase
case (statet)
			t_wait : begin statet <= (enmes)? t_mes1: statet; entec <= 0; end
			t_mes1 : begin statet <= (mes&&itemp[9]==1)? t_mes2: (mes)? t_mes: statet;
								entec <= (mes&&itemp[9]==1)? 8192: 0; end
			t_mes2 : begin statet <= (mes)? t_mes3: statet;
								entec <= (mes&&itemp[9]==1)? entec+4096: (mes&&itemp>0)? entec-4096: entec; end
			t_mes3 : begin statet <= (mes)? t_mes4: statet;
								entec <= (mes&&itemp[9]==1)? entec+2048: (mes&&itemp>0)? entec-2048: entec; end
			t_mes4 : begin statet <= (mes)? t_mes5: statet;
								entec <= (mes&&itemp[9]==1)? entec+1024: (mes&&itemp>0)? entec-1024: entec; end
			t_mes5 : begin statet <= (mes)? t_mes6: statet;
								entec <= (mes&&itemp[9]==1)? entec+512: (mes&&itemp>0)? entec-512: entec; end
			t_mes6 : begin statet <= (mes)? t_mes: statet;
								entec <= (mes&&itemp[9]==1)? entec+256: (mes&&itemp>0)? entec-256: entec; end
			t_mes  : begin statet <= (mes)? t_mes : statet; 
			               endet <= (itemp>tmin||itemp<tmax)? 1: 0;
								entec <= (mes&&itemp[9]==1&&entec>=16319)? 16383: (mes&&itemp[9]==1)? entec+64:
         								(mes&&itemp>0&&entec<=64)? 0: (mes&&itemp>0)? entec-64: entec; end					
		endcase						
	   end
	   end 


endmodule
