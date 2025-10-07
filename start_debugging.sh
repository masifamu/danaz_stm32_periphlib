#!/bin/bash

# Start a new tmux session named "stm32_debug"
tmux new-session -d -s stm32_debug

# --- Pane 0: GDB ---
tmux split-window -h -t stm32_debug:0.0
tmux split-window -v -t stm32_debug:0.0

tmux send-keys -t stm32_debug:0.0 'openocd -f interface/stlink.cfg -f target/stm32f0x.cfg' C-m
tmux send-keys -t stm32_debug:0.2 'arm-none-eabi-gdb -tui build/main.elf -ex "target remote localhost:3333"' C-m

# --- Pane 1: Telnet to OpenOCD ---
tmux send-keys -t stm32_debug:0.1 'telnet localhost 4444' C-m

# --- Pane 2: OpenOCD with ST-LINK v2 and STM32F0 ---
tmux select-pane -t stm32_debug:0.2
#tmux split-window -h -t stm32_debug

# Attach to the tmux session
tmux attach -t stm32_debug

