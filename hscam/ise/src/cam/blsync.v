//���� �������������
module blsync(fr,IN,clk,inv,extsyn,midsyn,iexp,ah,av,ahlvds,avlvds,th,tv,e1sec,esyn,isyn);
	 input [1:0] fr;//������� ������: 00-60��; 01-120��; 10-240��; 11-480��
    input IN;//120 ����
    input clk;//65.625MHz
    input inv;//�������� ������� �������������
    input extsyn;//���������� ������� �������������
    input midsyn;//�������� � �������� ����������
    input [10:0] iexp;//������� ����������	    
    output reg [10:0] ah;//����� �������
    output reg [10:0] av;//����� ������
	 output reg [10:0] ahlvds;//����� ������� ��� ������ � lvds
    output reg [10:0] avlvds;//����� ������ ��� ������ � lvds
    output reg th;//����� ������
    output reg tv;//����� �����
    output e1sec,esyn,isyn;    
//���������� ����������      
    wire uph;//���������� ������������ ������ +1
    wire downh;//���������� ������������ ������ -1
    wire beginsyn;//�������� �������������
    wire gate;//������ ��� �����
//����������
blextsyn blextsyn(.clk(clk),.fr(fr),.inv(inv),.tv(tv),.th(th),.midsyn(midsyn),.in(IN),.ah(ah),.av(av),.iexp(iexp),.extsyn(extsyn),
                  .uph(uph),.downh(downh),.beginsyn(beginsyn),.e1sec(e1sec),.esyn(esyn),.isyn(isyn),.tv60(tv60));

always @(posedge clk)
  begin begin  tv <= (av==0&&ah==1)? 1: 0;
               th <= (ah==1)? 1: 0; 
					avlvds <= (ahlvds==0&&avlvds==0||tv60)? 1027: (ahlvds==0)? avlvds-1: avlvds;
					ahlvds <= (ahlvds==0||tv60)? 1063: ahlvds-1; end
    begin if (extsyn)
          begin if (beginsyn)
		      begin if (midsyn)
				  begin if (iexp[0]) begin av <= {1'b0,iexp[10:1]};
                          				   ah <= (fr==0)? 531: (fr==1)? 265: (fr==2)? 132: 66; end//iexp[0]==1
				                else begin av <= ({1'b0,iexp[10:1]}-1);
            									ah <= (fr==0)? 1063: (fr==1)? 531: (fr==2)? 265: 132; end//iexp[0]==0
				  end
			   	  else begin av <= 1027; 
					             ah <= (fr==0)? 1063: (fr==1)? 531: (fr==2)? 265: 132; end//endsyn
			   end
			  //��� beginsyn
			  else begin av <= (tv&th)? 1027: (th)? av-1: av;
			             ah <= (uph&&th&&fr==0)? 1064:(uph&&th&&fr==1)? 532:(uph&&th&&fr==2)? 266:(uph&&th&&fr==3)? 133:
							       (downh&&th&&fr==0)? 1062:(downh&&th&&fr==1)? 530:(downh&&th&&fr==2)? 264:(downh&&th&&fr==3)? 131:
									 (th&&fr==0)? 1063:(th&&fr==1)? 531:(th&&fr==2)? 265:(th&&fr==3)? 132: ah-1; end//��� beginsyn
		   end
			else begin av <= (tv&th)? 1027: (th)? av-1: av;
		 		        ah <= (th&&fr==0)? 1063:(th&&fr==1)? 531:(th&&fr==2)? 265:(th&&fr==3)? 132: ah-1; end//��� extsyn
    end
  end
endmodule					  