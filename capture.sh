#!/bin/bash
if ["$#" -ne 1]; then
    echo "Incorrect args. usage: $0 <interface>"
    exit 1
fi

sudo tshark -f "not port 22" -i $1 -T fields \
-e ip.src \
-e ip.dst \
-e frame.protocols \
-E header=y