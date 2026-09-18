#!/bin/bash

INSTALL_DIR="$HOME/.ec2-cli"
BIN="$HOME/.local/bin/ec2"

echo "Removing EC2 CLI..."

rm -rf "$INSTALL_DIR"
rm -f "$BIN"

echo "EC2 CLI removed."