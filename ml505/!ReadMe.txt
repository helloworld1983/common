--#######################
--ML505 - �����
--#######################

1. ��� �������� FPGA:
-------------------------------------------------
DIP switch(SW3): | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
-------------------------------------------------
JTAG             | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 |
PROM             | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |


2. SATA
DUAL_GTP: GTP_X0Y2

J40 - SATA-HOST1 - �� PCI-express ������ -2 (DUAL_GTP:CH0)
J41 - SATA-HOST2 - �� PCI-express ������ -1 (DUAL_GTP:CH1)


3. ���������:

������������:

PCI-Express     L L L L          L L L L
                E E E E          E E E E
                D D D D          D D D D
                0 1 2 3          4 5 6 7


4. ���������� �������� BRAM � ������� ������� data2mem
(����� �������� � ������������� ������� data2mem ��. d:\Help\Doc_Hardware\Xilinx\Xilinx_Doc\data2mem_standalone.pdf + data2mem_ug658.pdf)

scripts/eth_prm_xdl.bat    -- ����� �������� ����� *.xdl � ��� ����� ����� ���� ������ XST ��������� ETH_BRAM_PRM (LOC)
scripts/eth_prm_update.bat -- ��������� �������� ETH_BRAM_PRM
scripts/eth_prm_dump.bat   -- ����� ��������� (����� �����) ��������� �� ���������� �������� ETH_BRAM_PRM


