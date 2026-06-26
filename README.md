# FPGA UART Sample

SystemVerilogでUART送信回路を作成し、Verilatorでシミュレーション確認するためのプロジェクトです。

現在は、UART送信モジュール単体のテストと、上位モジュールから `"Hello, FPGA\n"` を送信するテストを用意しています。

## 構成

```text
.
├── src
│   ├── uart_tx.sv        # UART送信モジュール
│   └── uart_fpga.sv      # "Hello, FPGA\n" を送信する上位モジュール
├── tb
│   ├── tb_uart_tx.sv     # uart_tx単体テスト
│   ├── tb_uart_fpga.sv   # uart_fpga上位テスト
│   └── common
│       ├── gen_clk.sv
│       ├── gen_rst.sv
│       ├── uart_master.sv
│       └── uart_rx_model.sv
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

`VALID` と `READY` が同時にHighのとき、`DATA_IN` を送信開始します。

### uart_fpga

`uart_tx` を使って `"Hello, FPGA\n"` を1回送信する上位モジュールです。

実機ではこのモジュールをトップとして使用する想定です。

## テストベンチ

### tb_uart_tx

`uart_tx` 単体のテストです。

`8'h41`、つまり ASCII の `A` を送信し、UART受信モデルで正しく受信できることを確認します。

### tb_uart_fpga

`uart_fpga` の上位テストです。

UART出力から `"Hello, FPGA\n"` が正しく受信できることを確認します。

期待値は以下のように文字列で登録します。

```systemverilog
push_exp_string("Hello, FPGA\n");
```

## 使い方

### lint

UART送信モジュール単体のlintを実行します。

```bash
make lint-tx
```

上位モジュールのlintを実行します。

```bash
make lint-fpga
```

### シミュレーション

UART送信モジュール単体のシミュレーションを実行します。

```bash
make sim-tx
```

成功すると、以下のようなログが表示されます。

```text
PASS: UART RX received 41
PASS: received all expected bytes
```

上位モジュールのシミュレーションを実行します。

```bash
make sim-fpga
```

成功すると、以下のようなログが表示されます。

```text
PASS: UART RX received 48
PASS: UART RX received 65
PASS: UART RX received 6c
PASS: UART RX received 6c
PASS: UART RX received 6f
PASS: UART RX received 2c
PASS: UART RX received 20
PASS: UART RX received 46
PASS: UART RX received 50
PASS: UART RX received 47
PASS: UART RX received 41
PASS: UART RX received 0a
PASS: received all expected bytes
```

これは `"Hello, FPGA\n"` を正しく受信できたことを示しています。

### クリーン

生成物を削除します。

```bash
make clean
```

## UART設定

現在の `uart_fpga` では、以下の設定を想定しています。

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

## 確認済み

- `uart_tx` 単体で `8'h41` を送信できること
- `uart_fpga` から `"Hello, FPGA\n"` を送信できること
- Verilatorによるlint
- Verilatorによるシミュレーション

## 今後やること

- 実機FPGAでUART出力を確認する
- Vivado用の制約ファイルを整理する
- `P_WAIT_DIV` を上位から変更できるようにする
- 連続送信や任意文字列送信に対応する
