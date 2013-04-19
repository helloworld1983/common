#ifndef WMAIN_H
#define WMAIN_H

#include <QWidget>
#include <QtNetwork>
#include <QtGui>


//C_CFGPKT_WR_BIT/ Bit Map:
#define C_CFGPKT_WR                0
#define C_CFGPKT_RD                1
//HEADER(0)/ Bit map:
#define C_CFGPKT_FIFO_BIT          6 //��� ��������� 1 - FIFO/0 - �������(���� ������������� ������)
#define C_CFGPKT_WR_BIT            7 //��� ������ - ������/������
#define C_CFGPKT_DADR_L_BIT        8 //����� ������ � ������� FPGA
#define C_CFGPKT_DADR_MASK         0xFF
//HEADER(1)/ Bit map:
#define C_CFGPKT_RADR_L_BIT        0 //����� ���������� ��������
#define C_CFGPKT_RADR_MASK         0xFFFF
//HEADER(2)/ Bit map:
#define C_CFGPKT_DLEN_L_BIT        0 //���-�� ������ ��� ������/������
#define C_CFGPKT_DLEN_MASK         0xFFFF

struct TEth{
    QUdpSocket *udpSocket;
    QHostAddress ip;
    qint16 port;
};

class MainWindow : public QWidget
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = 0);
    ~MainWindow();

private:

    TEth eth;

    QLineEdit *eline_eth_ip;
    QLineEdit *eline_eth_port;
    QPushButton *btn_eth;

    QPushButton *btn_img_open;
    QCheckBox *chbox_img;

    QPushButton *btn_usr_set;

    QTextEdit *etext_log;

    QLabel *lbimage;

    bool imgToboard(QImage *img);

private slots:

    void cfg_txd();
    void eth_rxd();
    void eth_on_off();
    void img_open();

};

#endif // WMAIN_H
