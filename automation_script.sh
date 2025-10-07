#!/bin/bash

print_alert() {
    local msg="$1"
    local width=80
    local sep_line
    sep_line=$(printf '=%.0s' $(seq 1 $width))

    # Print top separator
    echo -e "\n\033[1;34m$sep_line\033[0m"

    # Print centered title
    local title="IMPORTANT:"
    printf "\033[1;34m%*s%*s\033[0m\n" $(( (${#title} + width) / 2 )) "$title" $(( width - (${#title} + width) / 2 )) ""

    # Print the message with word wrap
    echo -e "\033[1;33m$msg\033[0m" | fold -s -w $width

    # Print bottom separator
    echo -e "\033[1;34m$sep_line\033[0m\n"

    sleep 3
}

print_alert "Cleaning previous build..."
make clean

print_alert "Building tracker elf binary..."
make

print_alert "Building tracker bin binary..."
make bin

print_alert "Flashing the bin binary to the board..."
make flash_bin

print_alert "Now you can check the board status led..."
