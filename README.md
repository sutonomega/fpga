# FPGA UART Sample

SystemVerilogでUART送受信回路を作成し、Verilatorでlint・シミュレーション確認するためのプロジェクトです。

現在は、以下のテストを用意しています。

- `uart_tx` 単体で1byteを送信するテスト
- `uart_fpga` から `"Hello, FPGA\n"` を送信するテスト
- `uart_rx` がUART波形を受信して8bitデータに復元できることを確認するテスト
- `uart_if` で受信したUARTデータをそのまま送信し返すエコーバックテスト

## 構成

```text
.
├── src
│   ├── uart_tx.sv        # UART送信モジュール
│   ├── uart_rx.sv        # UART受信モジュール
│   ├── uart_if.sv        # UARTエコーバックモジュール
│   └── uart_fpga.sv      # "Hello, FPGA\n" を送信する上位モジュール
├── tb
│   ├── tb_uart_tx.sv     # uart_tx単体テスト
│   ├── tb_uart_rx.sv     # uart_rx受信テスト
│   ├── tb_uart_if.sv     # uart_ifエコーバックテスト
│   ├── tb_uart_fpga.sv   # uart_fpga上位テスト
│   └── common
│       ├── gen_clk.sv
│       ├── gen_rst.sv
│       ├── uart_tx_model.sv
│       ├── uart_line_rx_model.sv
│       └── uart_data_rx_model.sv
├── constraints
│   └── serial_arty.xdc
└── Makefile
```

## モジュール概要

### uart_tx

UARTの送信モジュールです。

主な信号は以下の通りです。

| 信号名   | 方向   | 説明           |
| -------- | ------ | -------------- |
| CLK      | input  | クロック       |
| RST      | input  | リセット       |
| VALID    | input  | 送信データ有効 |
| DATA_IN  | input  | 送信データ     |
| READY    | output | 送信受付可能   |
| DATA_OUT | output | UART送信出力   |

`VALID` と `READY` が同時にHighのとき、`DATA_IN` の送信を開始します。

### uart_rx

UARTの受信モジュールです。

主な信号は以下の通りです。

| 信号名   | 方向   | 説明               |
| -------- | ------ | ------------------ |
| CLK      | input  | クロック           |
| RST      | input  | リセット           |
| READY    | input  | 後段が受信可能     |
| DATA_IN  | input  | UART受信入力       |
| VALID    | output | 受信データ有効     |
| DATA_OUT | output | 受信した8bitデータ |

`VALID` と `READY` が同時にHighのとき、`DATA_OUT` の受け渡しが成立します。

### uart_if

`uart_rx` と `uart_tx` を接続したUARTエコーバックモジュールです。

`RXD` から受信した1byteデータを、そのまま `TXD` から送信します。

```text
RXD → uart_rx → uart_tx → TXD
```

`uart_if` は `P_WAIT_DIV` をパラメータとして持っています。

```systemverilog
module uart_if #(
    parameter int P_WAIT_DIV = 868
)(
    input  logic CLK,
    input  logic RST,
    input  logic RXD,
    output logic TXD
);
```

シミュレーションでは `P_WAIT_DIV=5` のように小さい値を指定し、実機ではデフォルトの `868` を使用します。

### uart_fpga

`uart_tx` を使って `"Hello, FPGA\n"` を1回送信する上位モジュールです。

実機でUART送信だけを確認する場合は、このモジュールをトップとして使用できます。

## テストベンチ

### tb_uart_tx

`uart_tx` 単体のテストです。

`8'h41`、つまりASCIIの `A` を送信し、UART波形を `uart_line_rx_model` で読み取って正しく受信できることを確認します。

### tb_uart_fpga

`uart_fpga` の上位テストです。

UART出力から `"Hello, FPGA\n"` が正しく受信できることを確認します。

期待値は以下のように文字列で登録します。

```systemverilog
t_push_exp_string("Hello, FPGA\n");
```

### tb_uart_rx

`uart_rx` の受信テストです。

テストベンチ内で以下のように接続しています。

```text
uart_tx_model
  ↓ VALID / DATA
uart_tx
  ↓ UART波形
uart_rx
  ↓ VALID / DATA
uart_data_rx_model
```

`uart_tx` で生成したUART波形を `uart_rx` に入力し、復元された8bitデータが期待値と一致することを確認します。

### tb_uart_if

`uart_if` のエコーバックテストです。

テストベンチ内で以下のように接続しています。

```text
uart_tx_model
  ↓ VALID / DATA
uart_tx
  ↓ UART_IF_RXD
uart_if
  ↓ UART_IF_TXD
uart_line_rx_model
```

`"Hello, FPGA\n"` を `uart_if` に入力し、同じ文字列が `TXD` から返ってくることを確認します。

## 共通テストモデル

### uart_tx_model

送信したい8bitデータ列を生成するモデルです。

内部にキューを持ち、以下のようにデータや文字列を登録できます。

```systemverilog
u_uart_tx_model.push_tx_data(8'h41);
u_uart_tx_model.push_tx_string("Hello, FPGA\n");
```

`READY` を見て送信する構成にしておくことで、送信先が受付可能になるまで `VALID` を保持できます。

### uart_line_rx_model

UARTの1bit波形を読み取り、期待値と比較するモデルです。

`uart_tx` や `uart_if` の `TXD` のような1bit UART線の確認に使います。

```systemverilog
u_uart_line_rx_model.push_exp_data(8'h41);
```

文字列をまとめて登録したい場合は、テストベンチ側で以下のようなtaskを用意しています。

```systemverilog
task automatic t_push_exp_string(input string str);
    for (int i = 0; i < str.len(); i++) begin
        u_uart_line_rx_model.push_exp_data(str.getc(i));
    end
endtask
```

### uart_data_rx_model

`VALID` / `DATA` の形式で出てくる受信済みデータを確認するモデルです。

`uart_rx` の出力確認に使います。

```systemverilog
u_uart_data_rx_model.push_exp_data(8'h41);
```

## 使い方

### lint

UART送信モジュール単体のlintを実行します。

```bash
make lint-tx
```

UART送信上位モジュールのlintを実行します。

```bash
make lint-fpga
```

UART受信モジュールのlintを実行します。

```bash
make lint-rx
```

UARTエコーバックモジュールのlintを実行します。

```bash
make lint-if
```

### シミュレーション

UART送信モジュール単体のシミュレーションを実行します。

```bash
make sim-tx
```

UART送信上位モジュールのシミュレーションを実行します。

```bash
make sim-fpga
```

UART受信モジュールのシミュレーションを実行します。

```bash
make sim-rx
```

UARTエコーバックモジュールのシミュレーションを実行します。

```bash
make sim-if
```

### 全テスト実行

lintとシミュレーションをまとめて実行します。

```bash
make check
```

現在、以下のテストが通ることを確認しています。

```text
tb_uart_tx    PASS
tb_uart_fpga  PASS
tb_uart_rx    PASS
tb_uart_if    PASS
```

### 波形確認

シミュレーションでは `dump.vcd` を出力します。

GTKWaveで確認できます。

```bash
gtkwave dump.vcd
```

`tb_uart_if` で見るとよい信号例は以下です。

```text
tb_uart_if.CLK
tb_uart_if.RST
tb_uart_if.TX_VALID
tb_uart_if.TX_DATA
tb_uart_if.UART_IF_RXD
tb_uart_if.UART_IF_TXD
tb_uart_if.u_uart_if.rx_valid
tb_uart_if.u_uart_if.tx_ready
tb_uart_if.u_uart_if.rx_data
```

### クリーン

生成物を削除します。

```bash
make clean
```

## UART設定

現在は以下の設定を想定しています。

| 項目           | 値        |
| -------------- | --------- |
| ボーレート     | 115200bps |
| データビット   | 8bit      |
| パリティ       | なし      |
| ストップビット | 1bit      |

`P_WAIT_DIV` はクロック周波数とボーレートから決めます。

```text
P_WAIT_DIV = クロック周波数 / ボーレート
```

100MHzクロックで115200bpsの場合は、以下のようになります。

```text
100,000,000 / 115,200 ≒ 868
```

シミュレーションでは高速化のため、`P_WAIT_DIV=5` など小さい値を使っています。

## 実機向け制約例

Arty A7 のUSB-UARTを使用する場合の例です。

```xdc
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 10.00 [get_ports { CLK }];

set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports { RST }];

set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { RXD }];
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { TXD }];
```

`D10` はFPGAからPCへ送るUART信号です。
`A9` はPCからFPGAへ入ってくるUART信号です。

## 確認済み

- `uart_tx` 単体で `8'h41` を送信できること
- `uart_fpga` から `"Hello, FPGA\n"` を送信できること
- `uart_rx` でUART波形を受信し、8bitデータに復元できること
- `uart_if` で `"Hello, FPGA\n"` をエコーバックできること
- Verilatorによるlint
- Verilatorによるシミュレーション
- GTKWave用のVCD出力

## 今後やること

- 実機FPGAでUART送信を確認する
- 実機FPGAでUARTエコーバックを確認する
- Vivado用の制約ファイルを整理する
- `uart_if` に受信バッファまたはFIFOを追加し、連続受信に強くする
- テストシナリオを増やす
- テストベンチ共通化とシナリオinclude方式を検討する
