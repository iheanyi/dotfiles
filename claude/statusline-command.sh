#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Poimandres Storm color palette
BRIGHT_MINT="\033[38;2;93;228;199m"
LOWER_MINT="\033[38;2;95;179;161m"
HOT_RED="\033[38;2;208;103;157m"
DARKER_GRAY="\033[38;2;134;140;173m"
RESET="\033[0m"

# Directory section
dir_name=$(basename "$cwd")
dir_section="${LOWER_MINT}${dir_name}${RESET}"

# Cost (total USD spent this session)
cost_section=""
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
if [ "$cost" != "0" ] && [ "$cost" != "null" ]; then
    cost_fmt=$(printf "%.2f" "$cost")
    cost_section="   ${BRIGHT_MINT}\$${cost_fmt}${RESET}"
fi

# Token counts
token_section=""
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
if [ "$input_tokens" != "0" ] || [ "$output_tokens" != "0" ]; then
    if [ "$input_tokens" -ge 1000 ]; then
        in_fmt=$(echo "scale=1; $input_tokens / 1000" | bc)k
    else
        in_fmt=$input_tokens
    fi
    if [ "$output_tokens" -ge 1000 ]; then
        out_fmt=$(echo "scale=1; $output_tokens / 1000" | bc)k
    else
        out_fmt=$output_tokens
    fi
    token_section="   ${DARKER_GRAY}↓${in_fmt}  ↑${out_fmt}${RESET}"
fi

# Context window percentage
ctx_section=""
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
current_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

if [ "$ctx_size" != "0" ] && [ "$ctx_size" != "null" ]; then
    current_total=$((current_input + cache_create + cache_read))
    if [ "$current_total" -gt 0 ]; then
        pct=$((current_total * 100 / ctx_size))
        if [ "$pct" -ge 80 ]; then
            ctx_color="$HOT_RED"
        elif [ "$pct" -ge 50 ]; then
            ctx_color="$BRIGHT_MINT"
        else
            ctx_color="$DARKER_GRAY"
        fi
        ctx_section="   ${ctx_color}${pct}%${RESET}"
    fi
fi

# Model
model_section="   ${DARKER_GRAY}${model}${RESET}"

# Output
printf "${dir_section}${cost_section}${token_section}${ctx_section}${model_section}"
