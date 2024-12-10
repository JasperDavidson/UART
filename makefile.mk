# Makefile

# Setting up the path
PYTHONPATH := /home/jasperd/Documents/programming/hdl/testing/.venv/lib/python3.12/site-packages:$(PYTHONPATH)
export PYTHONPATH

export PATH := $(PATH):$(shell dirname $(find .venv -name cocotb-config))

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = modules/uart_top.v modules/uart_tx.v modules/uart_rx.v

# use VHDL_SOURCES for VHDL files

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = uart_top

# MODULE is the basename of the Python test file
MODULE = full_uart_testbench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
