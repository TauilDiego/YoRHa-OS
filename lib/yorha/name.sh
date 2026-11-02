# shellcheck shell=bash
# The product's name and folders, in one place (spec 014, FR-019). The name is provisional: renaming
# the project means editing this file (install.sh reads it from the version it downloads).
YORHA_NAME=yorha-shell                  # folders and archive names
YORHA_CMD=yorha                      # the command in ~/.local/bin
YORHA_PRETTY=YoRHa-Shell                # what messages call it
YORHA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/$YORHA_NAME"
YORHA_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/$YORHA_NAME"
YORHA_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/$YORHA_NAME"
YORHA_BIN="$HOME/.local/bin"
YORHA_KEEP=3                         # versions kept in $YORHA_HOME/versions
