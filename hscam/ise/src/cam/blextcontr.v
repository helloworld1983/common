module blextcontr(RCIN,clk,init,endet,igain,iexp,itemp,rdstat,istat,rdcfg,icfg,RCOUT,oregime,ogain,oexp,oneg,opos,ocompen,korr,wrcfg,ocfg,testser);
    input RCIN;//���� ���������������� ������
    input clk;//65.625MHz
    input init;//�������������
	 input endet;//0 - �������� �������� �� �����������
    input [7:0] igain;//������� ������ ��������
    input [10:0] iexp;//����������
	 input [9:0] itemp;//����������� ���������
	 output reg rdstat;//������ ������ �� FIFO �������� �������
	 input [7:0] istat;//������ �� FIFO �������� �������
	 output reg rdcfg;//������ ������ �� FIFO �������� ������������
	 input [15:0] icfg;//������ �� FIFO �������� ������������
    output reg RCOUT;//����� ���������������� ������
    output reg [15:0] oregime;//�������� ������ �����(9-raid;8-endark;7-test;6-negsyn;5-extgain;4-extexp;3-midsyn;2-extsyn;1,0-60,120,240,480)
    output reg [7:0] ogain;//�������� ������ ��������
    output reg [10:0] oexp;//�������� ������ ����������
	 output reg [7:0] oneg;//�������� ������ ������������� �����
	 output reg [7:0] opos;//�������� ������ ������������� �����
	 output reg [7:0] ocompen;//�������� ������ ����������� ����������
    output reg korr;//������ ��������� ��������
	 output reg wrcfg;//������ ������ � FIFO �������� ������������
	 output reg [15:0] ocfg;//������ ������������ � FIFO �������� ������������
    output [3:0] testser;
//����������-[11:8]��������;[7:0]�������
//��������� FSM
    parameter s_wait = 0;//�������� ��������� �������(������� 1-0)
    parameter s_start = 1;//���������������� � ����������� ������ cb_sync=0.5b
    parameter s_data = 2;//����� ������
    parameter s_stop = 3;////����� �������� �������
    parameter s_proc = 4;//������ ���������� ������
	 parameter s_begin = 5;//����� cb0_5b, ������ ������� �������������(ident) ����� � ������ ��������� ������ � ��������������� �������
    parameter s_trans = 6;//�������� ����� ������, �������, ������
    parameter s_end = 7;//������ ������������ ������
    parameter s_err = 8;//��������� ������. ����� �� ��������.
//�������
	 parameter c_korr = 8'h00;//������ ���������.����� 2�����,�������� 2�����. 2�����.���������.
	 parameter c_rdtemp = 8'h40;//������ ����������� ���������.����� 2�����,�������� 4�����
    parameter c_wrmode = 8'h10;//��������� ������.����� 4�����,�������� 2�����
    parameter c_rdmode = 8'h50;//������ ������.����� 2�����,�������� 4�����
    parameter c_wrexp = 8'h12;//��������� ����������.����� 4�����,�������� 2�����
    parameter c_rdexp = 8'h52;//������ ����������.����� 2�����,�������� 4�����
    parameter c_wrgain = 8'h14;//��������� ��������.����� 3�����,�������� 2�����
	 parameter c_rdgain = 8'h54;//������ ��������.����� 2�����,�������� 3�����
	 parameter c_wrcompen = 8'h16;//��������� ����������� ����������.����� 3�����,�������� 2�����
	 parameter c_rdcompen = 8'h56;//������ ����������� ����������.����� 2�����,�������� 3�����
    parameter c_wrnegoff = 8'h18;//��������� ����������� ������.����� 3�����,�������� 2�����
	 parameter c_rdnegoff = 8'h58;//������ ����������� ������.����� 2�����,�������� 3�����
	 parameter c_wrposoff = 8'h19;//��������� ����������� ������.����� 3�����,�������� 2�����
	 parameter c_rdposoff = 8'h59;//������ ����������� ������.����� 2�����,�������� 3�����
	 parameter c_rdstatus = 8'h60;//������ ������� FIFO.����� 2�����,�������� 3�����.������ rd ��� FIFO(3-� ����)
	 parameter c_wrcfg = 8'h22;//��������� ������������ FIFO.����� 4�����,�������� 2�����.������ wr ��� FIFO(4-� ����)
	 parameter c_rdcfg = 8'h62;//������ ������������ FIFO.����� 2�����,�������� 4�����.������ rd ��� FIFO(4-� ����)
//���� ������������� ������
	 parameter ident = 8'he7;
//��������� �������
    parameter cb0_5b = 3418;
    parameter cb1b = 6836;
    parameter cb10b = 76000;
//�������� � ����������
    reg [3:0] state;//��������� FSM
    reg [12:0] cbsync;//������� �������������
    reg [16:0] cbtout;//������� ��������
	 reg tout;//������� ��������
    reg [7:0] com;//������� ������
    reg [15:0] data;//������� ������������� ������
    reg rc_in,irc_in,rc_out;
    reg [7:0] sdata;//����������� ������
    reg [8:0] odata;//������������ ������
    reg [3:0] cbbit;//������� �����
	 reg [2:0] cbbyte;//������� ������
    reg [7:0] iregime;
    reg [7:0] br;//�������
	 reg rkorr;

    assign testser[0] = state[0];
    assign testser[1] = state[1];
    assign testser[2] = state[2];
    assign testser[3] = state[3];
//������
  always @(posedge clk)
  begin if (init)//�������� �������������
	                begin state <= s_wait; cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <= 0;
						       cbtout <= 0; tout <= 0; odata <= 9'h1ff; oregime <= 10'h120; oexp <= 1;
								 ogain <= 8'h0; oneg <= 8'h40; opos <= 128; ocompen <= 8'h40; end
		  else if (tout) begin state <= s_wait; cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <= 0;
						       cbtout <= 0; tout <= 0; end
        else begin begin rc_in <= irc_in; irc_in <= RCIN; RCOUT <= rc_out;
                         cbtout <= (rc_in==0||cbtout==cb10b||odata[0]==0)? 0: cbtout+1;//������ ��������
					          tout <= (cbtout==cb10b)? 1: 0;
		                   rc_out <= odata[0];
								 rkorr <= korr;
								 korr <= (rkorr)? 0: korr;
//								 ogain <= (oregime[5])? igain: ogain;
// 							    oexp <= (oregime[4])? iexp: oexp;
								 rdstat <= (state==s_end&&com==8'h60&&cbbyte==2)? 1: 0;
								 rdcfg <= (state==s_end&&com==8'h62&&cbbyte==3)? 1: 0;
								 wrcfg <= (state==s_end&&com==8'h22&&cbbyte==1)? 1: 0; end
case (state)
s_wait ://0//�������� ������(������� �� 1 � 0)
	      begin state <= (rc_in==1&&irc_in==0)? s_start: state;
				   cbsync <= 0; cbbit <= 0; end

s_start ://1//���������������� � �������� ���������� ����(���� �� 0, �� ������)
	      begin state <= (cbsync==cb0_5b&&rc_in==0)? s_data: (cbsync==cb0_5b&&rc_in==1)? s_err: state;
               cbsync <= (cbsync==cb0_5b)? 0: cbsync + 1; end

s_data ://2//����� �����
         begin state <= (cbbit==7&&cbsync==cb1b)? s_stop: state;
					cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					cbbit <= (cbbit==7&&cbsync==cb1b)? 0: (cbsync==cb1b)? cbbit+1: cbbit;
					sdata <= (cbsync==cb1b)? {rc_in,sdata[7:1]}: sdata; end

s_stop ://3//����� �������� �������(���� �� 1 ��� 0-� ���� �� ident, �� ������)
			begin state <= (cbsync==cb1b&&(rc_in==0||(cbbyte==0&&sdata!=ident)))? s_err:
			               (cbsync==cb1b)? s_proc:  state;
					cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					com <= (cbbyte==1&&cbsync==cb1b)? sdata: com; end

s_proc ://4//������ ���������� ������(���������� ����,�������)
		   begin state <= (cbbyte==1&&(com!=8'h0&&com!=8'h10&&com!=8'h50&&com!=8'h12&&com!=8'h52&&
								 com!=8'h14&&com!=8'h54&&com!=8'h16&&com!=8'h56&&com!=8'h40&&com!=8'h18&&
								 com!=8'h58&&com!=8'h19&&com!=8'h59&&com!=8'h60&&com!=8'h22&&com!=8'h62))? s_err:
			               (cbbyte==0||cbbyte==1&&(com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
                         cbbyte==2&&(com==8'h10||com==8'h12||com==8'h22))? s_wait: s_begin;
			      cbbyte <= cbbyte+1;
					data[15:8] <= ((com==8'h10||com==8'h12||com==8'h22)&&cbbyte==2)? sdata[7:0]: data[15:8];
					data[7:0] <= sdata[7:0]; end

s_begin ://5//����� cb0_5b, ������ ������� �������������(ident) ����� � ������ ��������� ������ � ��������������� �������
			 begin state <= (cbsync==cb0_5b)? s_trans: state;
					 odata <= (cbsync==cb0_5b)? {ident,1'b0}: 9'h1ff;
					 cbsync <= (cbsync==cb0_5b)? 0: cbsync+1;
					 cbbit <= 0; cbbyte <= 0;
					 korr <= (com==8'h0&&cbsync==cb0_5b)? 1: korr;
					 oregime <= (com==8'h10)? data[15:0]: oregime;
					 oexp <= (com==8'h12&&data>1027)? 1027: (com==8'h12&&data==0)? 1: (com==8'h12)? data[10:0]: oexp;
					 ogain <= (com==8'h14)? data[7:0]: ogain;
					 ocompen <= (com==8'h16)? data[7:0]: ocompen;
					 oneg <= (com==8'h18)? data[7:0]: oneg;
					 opos <= (com==8'h19)? data[7:0]: opos;
					 ocfg <= (com==8'h22)? data: ocfg;	end

s_trans ://6//�������� ����� ������, �������, ������
			 begin state <= (cbsync==cb1b&&cbbit==9)? s_end: state;
					 cbsync <= (cbsync==cb1b)? 0: cbsync+1;
					 cbbit <= (cbsync==cb1b&&cbbit==9)? 0: (cbsync==cb1b)? cbbit+1: cbbit;
					 odata <= (cbsync==cb1b)? {1'b1,odata[8:1]}: odata; end

s_end ://7//������ ������������ ������
		  begin state <= (cbbyte==1&&(com==8'h0||com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
		                  cbbyte==2&&(com==8'h54||com==8'h56||com==8'h58||com==8'h59||com==8'h60)||
								cbbyte==3&&(com==8'h40||com==8'h50||com==8'h52||com==8'h62))? s_wait: s_trans;
				  cbbyte <= (cbbyte==1&&(com==8'h0||com==8'h10||com==8'h12||com==8'h14||com==8'h16||com==8'h18||com==8'h19||com==8'h22)||
		                   cbbyte==2&&(com==8'h54||com==8'h56||com==8'h58||com==8'h59||com==8'h60)||
								 cbbyte==3&&(com==8'h40||com==8'h50||com==8'h52||com==8'h62))? 0: cbbyte+1;
				  odata <= (cbbyte==0)? {com,1'b0}:
							  (cbbyte==1&&com==8'h40)? {6'h0,itemp[9:8],1'b0}:
							  (cbbyte==2&&com==8'h40)? {itemp[7:0],1'b0}:
				           (cbbyte==1&&com==8'h50)? {5'h0,endet,oregime[9:8],1'b0}:
							  (cbbyte==2&&com==8'h50)? {oregime[7:0],1'b0}:
          				  (cbbyte==1&&com==8'h52)? {5'h0,iexp[10:8],1'b0}:
							  (cbbyte==2&&com==8'h52)? {iexp[7:0],1'b0}:
							  (cbbyte==1&&com==8'h54)? {igain,1'b0}:
							  (cbbyte==1&&com==8'h56)? {ocompen,1'b0}:
							  (cbbyte==1&&com==8'h58)? {oneg,1'b0}:
							  (cbbyte==1&&com==8'h59)? {opos,1'b0}:
							  (cbbyte==1&&com==8'h60)? {istat,1'b0}:
							  (cbbyte==1&&com==8'h62)? {icfg[15:8],1'b0}:
							  (cbbyte==2&&com==8'h62)? {icfg[7:0],1'b0}: 9'h1ff; end

s_err ://8//��������� ������. ����� �� ��������.
		 begin state <= (tout)? s_wait: state;
				 cbsync <= 0; cbbit <= 0; cbbyte <= 0; com <=0; end
  endcase
    end
  end
endmodule
