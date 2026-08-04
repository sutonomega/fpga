VIVADO = vivado
GOWIN = ~/IDE/bin/gw_sh
PROGRAMMER = sudo ~/Programmer/bin/programmer_cli

PROJECT_DIR = $(shell pwd)
FS_FILE = $(PROJECT_DIR)/gowin/fpga_project/impl/pnr/fpga_project.fs

LOG_DIR = logs

TB ?= tb_uart_if


.PHONY: all sim create build program clean


all: build


# Vivadoシミュレーション
sim:
	mkdir -p $(LOG_DIR)
	cd $(LOG_DIR) && TB=$(TB) $(VIVADO) -mode batch -source ../vivado/sim.tcl


# Gowin プロジェクト作成
create:
	mkdir -p $(LOG_DIR)
	cd $(LOG_DIR)  \
	unset DISPLAY && \
	QT_QPA_PLATFORM=offscreen \
	$(GOWIN) ../gowin/create.tcl


# Gowin 合成・配置配線
build:
	mkdir -p $(LOG_DIR)
	cd $(LOG_DIR)  \
	unset DISPLAY && \
	QT_QPA_PLATFORM=offscreen \
	$(GOWIN) ../gowin/build.tcl


# FPGA書き込み
program:
	$(PROGRAMMER) \
		--device GW1NR-9C \
			--operation_index 2 \
			--fsFile $(FS_FILE)


# 生成物削除
clean:
	rm -rf logs
	rm -rf gowin/fpga_project
