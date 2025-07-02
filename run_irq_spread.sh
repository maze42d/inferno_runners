#!/bin/bash

AFFINITY_MASK="0C"  # binary 1100 = CPU2 + CPU3

DEVICES=("xhci" "ehci" "ohci" "dwc3" "mmc" "eth" "i2c")

for dev in "${DEVICES[@]}"; do
    grep "$dev" /proc/interrupts | while read -r line; do
        irq=$(echo "$line" | awk -F: '{print $1}' | tr -d ' ')
        irq_path="/proc/irq/$irq/smp_affinity"
        if [ -w "$irq_path" ]; then
            echo "Setting IRQ $irq ($dev) affinity to $AFFINITY_MASK"
            echo $AFFINITY_MASK > "$irq_path"
        fi
    done
done
