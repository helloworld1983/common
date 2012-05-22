module blextsyn(clk,fr,inv,tv,th,midsyn,in,ah,av,iexp,extsyn,uph,downh,beginsyn,e1sec,esyn,isyn,tv60);
    input clk;//65.625MHz
	 input [1:0] fr;//������� ������
    input inv;//�������� ������ �������������
    input tv;//����� ����� 
	 input th;//����� ������	
    input midsyn;//������������� �� �������� ����������
    input in;//120����
    input [10:0] ah;//����� �������
    input [10:0] av;//����� ������
    input [10:0] iexp;//������� ����������
	 input extsyn;//������ ������� �������������
    output reg uph;//���������� ������������ ������
    output reg downh;//���������� ������������ ������
    output reg beginsyn;//����� �������� � ������� �������������
	 output reg e1sec;//1 �������, ���� ������ clk, �������
    output reg esyn;//60 ����, ���� ������ clk, �������
    output reg isyn;//60 ����, ���� ������ clk, ����������
	 output reg tv60;//tv-60Hz
//����������
    reg [7:0] cbsub;//������� ������
    reg [7:0] cberr;//������� ��������� ������
    reg [8:0] cbwidth;//������� ����������� 1�������
    reg frame;//60 ���� �����
    reg oin;//��� ��������� �������� �� ������
    reg sub;//������ ����� ������� � ���������� ���������������    
    reg err;//������� ������:��������� ����� �� ������� esyn     
    reg iin,fdin,fdup,fddown;
    reg [1:0] beginsyn2;
	 reg [2:0] cbframe;//������� ������ ������
	 reg en1sec;
	 reg [2:0] cbtv;//��������� 60�� �� tv �������
	 
//���������
//    parameter midh = 391;//�������� ������
    parameter maxsub = 100;//������������ �������� ����� ���������������

always @(posedge clk)
  begin iin <=fdin; fdin <=in;//�������� ������������� � ����������� ����������
        oin <=((inv&&~fdin&&iin)||(~inv&&fdin&&~iin))? 1: 0;//��������� �������� �� ������ 
        cbwidth <= ((inv && ~iin)||(~inv && iin))? cbwidth + 1: 0;//������� ����� �������������
		  frame <=  (cbwidth==500)? 0: (oin)? ~frame: frame;//�������� � 1��� � ��������� ������� 60��
		  en1sec <= (cbwidth==500)? 1: (oin)? 0: en1sec;//��������� �����
		  e1sec <= (~extsyn)? tv60: (en1sec)? oin: 0;//��������� �������� ������������ � ������� 1��� ��� ���������� ������������� 60��
		  esyn <=(~frame && oin)? 1: 0;//��������� ������� ������������� 60��
		  cbtv <= ((fr==0||fr==1&&cbtv==1||fr==2&&cbtv==3||fr==3&&cbtv==7)&&tv)? 0: cbtv+1;
		  tv60 <= (fr==0||fr==1&&cbtv==1||fr==2&&cbtv==3||fr==3&&cbtv==7)? tv: 0;//��������� ���������� ������������� 60��
		  cbframe <= (beginsyn)? 0: (tv)? cbframe+1: cbframe;//������� ������ ������
		  isyn <= ((midsyn==0&&fr==0&&tv)||(midsyn==0&&fr==1&&cbframe==1&&tv)||
				     (midsyn==0&&fr==2&&cbframe==3&&tv)||(midsyn==0&&fr==3&&cbframe==7&&tv)||
				     (midsyn==1&&fr==0&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==0&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==532)||
					  (midsyn==1&&fr==1&&cbframe==1&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==1&&cbframe==1&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==266)||
					  (midsyn==1&&fr==2&&cbframe==3&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==2&&cbframe==3&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==133)||
					  (midsyn==1&&fr==3&&cbframe==7&&iexp[0]==0&&av=={1'b0,iexp[10:1]}&&th)||
					  (midsyn==1&&fr==3&&cbframe==7&&iexp[0]==1&&av=={1'b0,iexp[10:1]}&&ah==67))? 1: 0;//��������� ���������� �������������							  
		  beginsyn <= (err&&esyn)? 1'b1: 1'b0;//����� �����
		  sub <= (beginsyn)? 0: (esyn^isyn)? ~sub : sub;//����������� ����� �������� ����� ���������������
		  cbsub <= (sub==1)? cbsub+1: 0;//���������� �������� ����� ��������������� � ��������
		  err <= (cbsub==maxsub)? 1:(beginsyn)? 0: err;//��������� ����� ������ ��� ���������� ���������
		  uph <= (cberr==0||beginsyn)? 0: (sub==1&&esyn==1)? 1: uph;//������ ���� ���������
		  downh <= (cberr==0||beginsyn)? 0: (sub==1&&isyn==1)? 1: downh;//������ ���� ���������
		  cberr <= (err)? 0: (esyn^isyn && sub)? cbsub: (th&&cberr!=0)? cberr-1: cberr;
  end
endmodule
