rem // ��� ����� ������� core_gen � ������ � ��� ��������� ��������:
for /R  %%f in ( core_gen\doc core_gen\implement core_gen\simulation ) do rmdir /s /q "%%f"

rem // ��� ����� ������� core_gen � ������ � ��� ��������� �����:
for /R  %%f in ( core_gen\*.prj core_gen\*.xise core_gen\*.ise core_gen\*.gise core_gen\*.asy core_gen\*.vho core_gen\*.tcl core_gen\*.txt core_gen\*.pdf core_gen\*.veo core_gen\*.lso core_gen\*.xrpt ) do del "%%f"

rem // ��� ����� ������� pci_express � ������ � ��� ��������� ��������:
for /R  %%f in ( core_gen\core_pciexp_ep_blk_plus\doc core_gen\core_pciexp_ep_blk_plus\example_design  core_gen\core_pciexp_ep_blk_plus\simulation  core_gen\core_pciexp_ep_blk_plus\implement) do rmdir /s /q "%%f"

rem // ��� ����� ������� pci_express � ������ � ��� ��������� �����:
for /R  %%f in ( core_gen\core_pciexp_ep_blk_plus\*.txt ) do del "%%f"

rem // ��� ����� ������� emac � ������ � ��� ��������� �����:
for /R  %%f in ( core_gen\emac_core\*.txt ) do del "%%f"


rem // ��� ����� ������� matlab � ������ � ��� ��������� �����:
for /R  %%f in ( matlab\*.asv ) do del "%%f"


rem // ��� ����� ������� mscript � ������ � ��� ��������� ��������:
for /R  %%f in ( mscript\work mscript\plxsim ) do rmdir /s /q "%%f"

rem // ��� ����� ������� mscript � ������ � ��� ��������� �����:
for /R  %%f in ( mscript\tcl_stacktrace.txt mscript\*.bmm mscript\*.vstf mscript\*.wlf ) do del "%%f"

rem // ������ �� ���� ������������ ��������� �����
del /s /q AlphaData_Session.log
del /s /q _impactbatch.log
