//------------------------------------------------------------
// ������ ������������� ����� ������� ���������� ������� ���
//  ������� �����, �������������� ��� ������� ���������������� 
//  �������� (���� ���������� 3.3���). ����������� ��������
//  ��� �������� �������� ���������������� � ������������� �
//  ���������� �������� �������� �������
// ������ �������: [31]-overday, [30:26]-����, [25:20]-������,
//  [19:14]-�������, [13:4]-��, [3:0]-����� ���.
//------------------------------------------------------------
// ����� ������� �.�.
// 
// V1.0     Date 20.4.5 - 24.4.5
// V1.1     Date 14.5.5 - 15.5.5
// V2.0     Date 23.9.6 - 25.9.6
// V2.1     Date 24.10.6 - 24.10.6
// V2.2     Date 2.11.6
// V2.3     Date 30.06.10 ������� ���� ������� ��� ������������������� ���������
//------------------------- -----------------------------------
module sync_u(clk,i_pps,i_ext_1s,i_ext_1m,
           sync_iedge,sync_oedge,sync_time_en,mode_set_time,type_of_sync,
           sync_win,
           host_clk,wr_en_time,host_wr_data,
		     stime,n_sync,sync_cou_err,
           sync_out1, sync_out2, out_1s,out_1m,
			  sync_ld, sync_pic
           );
    
   input clk;
   input i_pps,i_ext_1s,i_ext_1m;		 //PPS � ������� �������������
   
   input sync_iedge;       //����������� ������ ������ ������� ������������� (0-rise)
   input sync_oedge;       //����������� ������ ������� �� ������� ������������� (0-rise)
   input sync_time_en;     //���������� ������ ����� (1-���������)
   input mode_set_time;    //��������� ����� (0-����� � �������, 1-�� ������� �������)
   input [1:0] type_of_sync; //����� ��������� ������� �������������,
// '10'-�������, '01'-PPS, '11','00'-���������� �������������

   output reg sync_win;         //���������� �������� ������ ������� (1 ��)

   input host_clk;               //�������� �� �����
   input wr_en_time;             //��������� �������
   input [31:0] host_wr_data;    //������ �� ����� ��� ������

   output [31:0] stime;          //���������� ������� �������
   output [7:0] n_sync;          //����� ��������������
   output [7:0] sync_cou_err;    //������� ������ ������� ������������� (�� � �������)

   output sync_out1,out_1s,out_1m;    //������������� ��� ������� ���������
	output sync_out2;
	output sync_ld;  //������������� �� 
	output sync_pic; //������������� PIC 
   
//   output reg sync_piezo;        //������������� ��� ������������ ����� ���
//   output reg sync_cam_ir;       //������������� ��� ������ ���
   

// ���������� ����������
   reg pps,p_pps,ext_1s,pext_1s,ext_1m,pext_1m;
   reg rise_pps,fall_pps,rise_ext1s,fall_ext1s,rise_ext1m,fall_ext1m;
   wire rst_pps,rst_ext,breset;

   parameter i_freq=14400000; //������� �������
   reg [6:0] bcounter =0;
   parameter bend=48;         //����������� ������� 1-�� �������� (�� 300���)
   reg [11:0] sync_cou;       //������� ��������� ������� ����������
   parameter len_sync_cou=2500;   //����������� ������� �� �������������
   parameter int_gap=len_sync_cou/4;  //�������� ����� ������������
   parameter max_n_sync=i_freq/(bend*len_sync_cou);
   parameter div_100us=i_freq/(bend*2*10000);

   reg sync =0;		         //�������� �������������
	reg sync_ld=0;             // ������������� ��   
	reg sync_pic=0;            // ������������� PIC  
   parameter st_0s=5;         //��������� 0-�� ������ ��������
   parameter st_s=2;          //��������� �� 0-� ������ ���������
	parameter st_sp=5;         //��������� ������ ��������� ��� pic
	parameter st_ld=2290;      //��� �� ������� ����� �� 700��� �� �������� 120��
   reg [7:0] n_sync;          //����� �������� ��������������
   reg [7:0] sync_cou_err;    //������� ������ ������� ������������� (�� � �������)
	//-----------------------------
	//��������� 
	reg sync_corr =0;
	reg [7:0] n_sync_corr =0;
	reg [11:0] sync_cou_corr =0;
	reg [6:0] bcounter_corr =0;
	wire [6:0] bend_corr;
	reg flag_decr =0;
	reg flag_incr =0;
	reg [6:0] delta_p=0;
	reg [6:0] delta_m=0;
	wire sync_pulse;
   reg sync_=0;
	
	//-----------------------------

   reg p_sync_cou0;

   reg [3:0] cou100us;    //������� ������� �� div_100us ��� ��������� 10���
   reg [3:0] p_cou100us;  //����������� ������� cou100us
   reg c100us;            //�������� � �������� 10���
   reg c1s,c1m;	        //�������� �� ������� � ������
	//wire c1s,c1m;	        //�������� �� ������� � ������
   reg out_1s,out_1m;     //������ ��� ������� �������������
   reg [15:0] cou_c1s,cou_c1m; //������� ������������ ��������� 
                               // �� ������� ������� �������������
   parameter max_cou_c1s=32766; //������������ ��������� �� ������ 1 ���
   parameter max_cou_c1m=32766; //������������ ��������� �� ������ 1 ���

   reg [30:4] t_time;   //���� ��� ������ �������
   reg [31:0] stime;     //���������� ������� �������
   reg new_time;	       //������ �� ��������� ������ �������
   reg rd_new_time;      //����� ������� �� ��������� ������ �������

   wire minutka;     //������ ��������� ����� �� �������
	reg breset_ =0;
	reg breset_z =0;
	reg [10:0] cou_sync_pulse =0;
//--------------------------------------------------------------------------------
// ������� ������������ ��������������� ��� �������� 5��� �� �������, 10��� �������
always @(posedge clk)
begin
if (sync_corr) cou_sync_pulse <= cou_sync_pulse + 1;
else cou_sync_pulse <=0;
end
assign sync_out1 = ((n_sync_corr==119)&& sync_corr &&(cou_sync_pulse < 144))? 1:   //10���
                   ((n_sync_corr!=119)&& sync_corr &&(cou_sync_pulse < 72))?  1:0; //5���

//--------------------------------------------------------------------------------
//assign sync_out1 = sync_corr;
assign sync_out2 = sync;


// ������ ����� �� ���������� ��������
always @(posedge host_clk)
   begin
      if(wr_en_time) t_time[30:4] <= host_wr_data[30:4];
   end

// ������ �������� � ������ ������ ������� �������
always @(posedge clk)
   begin
//  PPS
      pps <= i_pps;
      p_pps <= pps;
	   if(~p_pps && pps) rise_pps <= 1;
	   else rise_pps <= 0;
	   if(p_pps && ~pps) fall_pps <= 1;
	   else fall_pps <= 0;
// ������� ������������� (�������)
      ext_1s <= i_ext_1s;
	   pext_1s <= ext_1s;
	   if(~pext_1s && ext_1s) rise_ext1s <= 1;
	   else rise_ext1s <= 0;
	   if(pext_1s && ~ext_1s) fall_ext1s <= 1;
	   else fall_ext1s <= 0;
// ������� ������������� (�������)
      ext_1m <= i_ext_1m;
	   pext_1m <= ext_1m;
	   if(~pext_1m && ext_1m) rise_ext1m <= 1;
	   else rise_ext1m <= 0;
	   if(pext_1m && ~ext_1m) fall_ext1m <= 1;
	   else fall_ext1m <= 0;
   end

// ������� ���������� ����� ������� � ����� ���������� ������
assign rst_pps = sync_iedge? fall_pps: rise_pps;
assign rst_ext = sync_iedge? fall_ext1s: rise_ext1s;
// ���������� 'breset' � ����������� �� ���� ������������� � 
//  ��� ��������� ������ ������� (!!!)
assign breset = (type_of_sync==2'b01)? rst_pps: (type_of_sync==2'b10)? rst_ext: new_time;
// ���������� ������ ������� �� ������� ������
assign minutka = (~mode_set_time)? 1: sync_iedge? fall_ext1m: rise_ext1m;

// �������� breset �� 2 ����� ����� �� ������ � c100us
always @(posedge clk)
begin
breset_ <= breset;
breset_z <= breset_;
end

// ��������� �������� �������
//  �������������� ��� ������� ������
always @(posedge clk)
   if(breset || bcounter==bend-1) bcounter <= 0; 
   else bcounter <= bcounter+1;
// ��������� ��������. ����� �� ������� �������������. ������������
//  ������ � ��������� ���������
always @(posedge clk)
   if(breset ||(bcounter==bend-1 && sync_cou==len_sync_cou-1)) sync_cou <= 0; 
   else if(bcounter==bend-1) sync_cou <= sync_cou+1;
// ����� ������ �������� ���������� ��� �������� �������� � 0
always @(posedge clk)
   if(breset ||(bcounter==bend-1 && sync_cou==len_sync_cou-1 && 
          n_sync==max_n_sync-1)) n_sync <= 0; 
   else if(bcounter==bend-1 && sync_cou==len_sync_cou-1) n_sync <= n_sync+1;
	
// ��������, ������ �� ������� ������������� � ������ 3.3 ��� � ���� � � �����
always @(posedge clk)
  if(wr_en_time) sync_cou_err <= 0;
  else
      if(breset && (sync_cou!=len_sync_cou-1 || sync_cou!=0)) 
                 sync_cou_err <= sync_cou_err+1;

// ���������������� ������ (119-� ������� ������)
always @(posedge clk)
   if((n_sync==119 && sync_cou < st_0s)||(n_sync!=119 && sync_cou < st_s)) sync <= 1;
   else sync <= 0;


	
//-------------------------------------------------------------------------------------------	
// ���������� 120 ��
// �������� ������������ ����� �������� ���������������, ������� ����� �������������� �� 
// ����������� ������� ������ ������� �������������
// ��������� �������� ������� �� 300 ��� = 48 ������ 14.4 ��� �������� ����������
// ��-�� �������������� ������� ���������� �� ������ ������� ����������������� ������
// ��������� ���� ���������� �������� ������� ����� ���� ������ 48 ������ clk, ���� ��� �������� ����
// ������� ����� (�������, ��� ����� �� "������" ���������� �������� ������� ������� ������������� �� ������)
// ���� ��� ���������� - ����������� ������� ������ �������������
// ��� ������������ ������ ������������� - ������� ������, 
// ������� ������ ���������� ������� �� �� ������ ������� 
// ���� ����� ������� ������������� ������ ������ ��� �� ��� ������� (�� ����� � ������),
// �� ��� ������� ����������� ����� �������������
// ����������� �� ���� ���� ������������ ������� bcounter_corr � �������������� ��������� delta
// � ���������� ������������������ 119 ������� ������������� ������ ���������� �� delta �� ������ pps
// ���� ����� ������� ������������� ������ ����� ��� �� ��� ������� (�� ����� � ������),
// �� ��� ������� ����������� ����� �������������
// ��������� �� ���� ���� ������������ ������� bcounter_corr � �������������� ��������� delta
// ��������� ���� ������ �������


assign bend_corr = ((sync_cou_corr == 0) && flag_decr)? bend-1:
                   ((sync_cou_corr == 0) && flag_incr)? bend+1: bend;
// ��������� �������� �������
//  �������������� ��� ������� ������
always @(posedge clk)
   if(breset || bcounter_corr == bend_corr -1) bcounter_corr <= 0; 
   else bcounter_corr <= bcounter_corr+1;
// ��������� ��������. ����� �� ������� �������������. ������������
//  ������ � ��������� ���������
always @(posedge clk)
   if(breset ||(bcounter_corr == bend_corr-1 && sync_cou_corr == len_sync_cou-1)) sync_cou_corr <= 0; 
   else if(bcounter_corr == bend_corr-1) sync_cou_corr <= sync_cou_corr +1;
// ����� ������ �������� ���������� ��� �������� �������� � 0
always @(posedge clk)
   if(breset ||(bcounter_corr == bend_corr-1 && sync_cou_corr == len_sync_cou-1 && 
      n_sync_corr==max_n_sync-1))                                          n_sync_corr <= 0; 
   else if(bcounter_corr == bend_corr-1 && sync_cou_corr ==len_sync_cou-1) n_sync_corr <= n_sync_corr+1;
	

assign sync_pulse = sync && !sync_;
always @(posedge clk)
sync_<= sync;

	
always @(posedge clk)
begin
// ���������� ��������������� �
// ��� ������� ����������� ��������� 120 �� ��������� ������ �� 1
if(breset && (n_sync==119) && (sync_cou == len_sync_cou-1 )) delta_m <= bend - bcounter;
else if (sync_pulse && (delta_m > 0))                        delta_m <= delta_m - 1;

if(breset && (n_sync==0) && (sync_cou == 0))     delta_p <= bcounter;
else if (sync_pulse && (delta_p > 0))            delta_p <= delta_p - 1;

if (delta_m > 2)      flag_decr <= 1'b1;
else begin if (delta_p > 2) flag_incr <= 1'b1;
           else             flag_incr <= 1'b0;
           flag_decr <= 1'b0;
     end
end

// ���������������� ������ (119-� ������� ������)
always @(posedge clk)
   if((n_sync_corr==119 && sync_cou_corr<st_0s)||(n_sync_corr!=119 && sync_cou_corr<st_s)) sync_corr<= 1;
   else sync_corr <= 0;

//-------------------------------------------------------------------------------------------


	
//-------------------------------------------------------------
// ���������������� ������ ��� ��
always @(posedge clk)
begin
if (sync_cou_corr >= st_ld) sync_ld <= 1;
else sync_ld <= 0;
// ���������������� ������ ��� PIC
if (sync_cou_corr < st_sp) sync_pic <= 1;
else sync_pic <= 0;
end

//-------------------------------------------------------------
// ������ ������� ���������� 4 ���� �� ����� ������������� 
// ������ ���������� 1 �������� (3.3us) ��� ������ �������!
//always @(posedge clk)   
//   if(sync_cou<200) inter <= 1; 
//   if(sync_cou==0 || sync_cou==int_gap || sync_cou==2*int_gap || 
//          sync_cou==3*int_gap) inter <= 1;
//   if(sync_cou==0 || sync_cou==312 || sync_cou==625 || sync_cou==937 ||
//      sync_cou==1250 || sync_cou==1562 || sync_cou==1875 || sync_cou==2187) inter <= 1;
//   else inter <= 0;

//always @(posedge clk)
//   begin
//      if(n_sync[1:0]==2'b00 && sync_cou==22) sync_piezo <= 1;
//      else sync_piezo <= 0;
//
//      if(n_sync[1:0]==2'b01 && sync_cou==22) sync_cam_ir <= 1;
//      else sync_cam_ir <= 0;
//   end

// ���������� �� �������� ������ ������. ������� ������������� 1 ��. 
// (1 �������� ����� �������������=3.3us)
always @(posedge clk)
   if(sync_cou==0 && n_sync==0) sync_win <= 1;
   else sync_win <= 0; 

//   ��������� ����
// �������� ���������� ��������� �������� ������� ��������
//  ������������� (�� ���������� � �������� i_freq/2*bend=150���) �
//  ������� ��� ������� �� 10���
always @(posedge clk)
   p_sync_cou0 <= breset? 0: sync_cou[0];   
always @(posedge clk)
   if(breset ||(p_sync_cou0 && !sync_cou[0] && cou100us==div_100us-1)) 
            cou100us <= 0;
   else if(p_sync_cou0 && !sync_cou[0]) cou100us <= cou100us+1;
// �� ���������� �������� �� 10 ��� � ���� ���������� ������
//  ������ ������������� �������� � �������� 100 ��� ��� �����
always @(posedge clk)
   p_cou100us <= cou100us;
always @(posedge clk)
   if(cou100us==0 && p_cou100us==div_100us-1) c100us <= sync_time_en;
   else c100us <= 0;



// ������� ����� ���
always @(posedge clk)
   if(breset_z || new_time ||(c100us && stime[3:0]==9)) stime[3:0] <= 0;
   else if(c100us) stime[3:0] <= stime[3:0]+1;
	
// �� ������� �� ��� ����� ���������� ��������� ������������� �����???????	
//assign c1s = (breset_z && (stime[13:4]>500))? ~new_time :
//             (c100us && stime[3:0]==9 && stime[13:4]==999)? ~new_time : 0;
	
//assign c1m = (c1s && stime[19:14]==59)? ~new_time : 0;	

// ������� �� � ������ ������� �� ��������� ������
//������� �������� � ������� �� �����������, ���� ��������������� ����� �����
always @(posedge clk)
      if(new_time && minutka) stime[13:4] <= t_time[13:4];
      else if(breset_z) begin
           stime[13:4] <= 0;
           c1s <= (stime[13:4]>500)? ~new_time: 0;
			  ////////////c1s <= ~new_time;
           end
           else if(c100us && stime[3:0]==9 && stime[13:4]==999) begin
                stime[13:4] <= 0;
	             c1s <= ~new_time;
                end
                else if(c100us && stime[3:0]==9) begin
                     stime[13:4] <= stime[13:4]+1;
	                  c1s <= 0;
		               end
                     else c1s <= 0;
// ������� ������� � ��������� ������� ��� ����� ����� � �����
always @(posedge clk)
   begin
//������� �������
//������� �������� � ������ �� �����������, ���� ��������������� ����� �����
      if(new_time && minutka) stime[19:14] <= t_time[19:14];
      else if(c1s && stime[19:14]==59) begin 
	          stime[19:14] <= 0;
		       c1m <= ~new_time;	
	     end
	   else if(c1s) begin 
	            stime[19:14] <= stime[19:14]+1;
		         c1m <= 0;
		     end
      else c1m <= 0;
   end

// ����������� ���������� ����� �����
always @(posedge rd_new_time or posedge host_clk)
   if(rd_new_time) new_time <= 0;
   else if(wr_en_time) new_time <= 1;  //���������� ������

// ��������� ������ ������� ��� ���� ����� � �����
always @(posedge clk)
   if(new_time && minutka) begin
         stime[31:20] <= {1'b0,t_time[30:20]};
	      rd_new_time <= 1;	  //���������� ����� �����
      end
   else begin 
	    rd_new_time <= 0;
// ������� ������
       if(c1m && stime[25:20]==59) stime[25:20] <= 0;
		 else if(c1m) stime[25:20] <= stime[25:20]+1;
// ������� ����
       if(c1m && stime[25:20]==59 && stime[30:26]==23) begin
		         stime[30:26] <= 0;
				   stime[31] <= 1;  //������� �� ����� �����
				end
       else if(c1m && stime[25:20]==59) stime[30:26] <= stime[30:26]+1;
       end

// ������� ������� 1 ��� ��� ������� �������������
always @(posedge clk)
   if(c1s) begin
         out_1s <= ~sync_oedge;
	      cou_c1s <= max_cou_c1s;
      end
   else if(cou_c1s!=0) cou_c1s <= cou_c1s-1;
        else out_1s <= sync_oedge;
// ������� ������� 1 ��� ��� ������� �������������
always @(posedge clk)
   if(c1m) begin
         out_1m <= ~sync_oedge;
	      cou_c1m <= max_cou_c1m;
      end
   else if(cou_c1m!=0) cou_c1m <= cou_c1m-1;
        else out_1m <= sync_oedge;



endmodule
