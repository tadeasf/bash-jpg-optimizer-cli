#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Display help message
display_help() {
    echo -e "${CYAN}Usage: ./jpg-optimizer.sh [OPTIONS]${RESET}"
    echo
    echo -e "${GREEN}Options:${RESET}"
    echo -e "  ${YELLOW}-r${RESET}                 Search for images recursively in subdirectories."
    echo -e "  ${YELLOW}--help, -h${RESET}          Display this help text."
    echo
    echo -e "${CYAN}Description:${RESET}"
    echo "  This script processes JPEG images in the specified directory, optimizes them by resizing"
    echo "  them to the given longest side dimension, and compresses them according to the quality setting."
    echo
    echo -e "${GREEN}Prompts:${RESET}"
    echo -e "  ${YELLOW}Input Directory:${RESET} Specify the directory containing the images to process."
    echo -e "  ${YELLOW}Output Directory:${RESET} Specify the directory where processed images will be saved."
    echo -e "  ${YELLOW}Longest Side:${RESET} Enter the longest side dimension for resizing the images (in pixels)."
    echo -e "  ${YELLOW}Quality Setting:${RESET} Choose from 'compressed', 'balanced', or 'quality'."
    echo
    echo -e "${CYAN}Example:${RESET}"
    echo "  ./jpg-optimizer.sh -r"
    echo "  ./jpg-optimizer.sh"
    exit 0
}

# Check for --help or -h option
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    display_help
fi

# Function to display a spinning loader
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${RESET} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to display a progress bar
progress_bar() {
    local duration=$1
    local steps=$2
    local width=50
    local progress=0
    for ((i=0; i<steps; i++)); do
        progress=$((i * width / steps))
        printf "\r${YELLOW}[%-${width}s]${RESET} %3d%%" "$(printf '#%.0s' $(seq 1 $progress))" $((progress * 100 / width))
        sleep $(echo "scale=3; $duration / $steps" | bc)
    done
    printf "\n"
}

# Function to display ASCII art
display_ascii_art() {
    echo -e "${MAGENTA}"
    cat << "EOF"
 _____                            _____        _   _           _             
|_   _|                          |  _  |      | | (_)         (_)            
  | | _ __ ___   __ _  __ _  ___ | | | |_ __  | |_ _ _ __ ___  _ _______ _ __
  | || '_ ` _ \ / _` |/ _` |/ _ \| | | | '_ \ | __| | '_ ` _ \| |_  / _ \ '__|
 _| || | | | | | (_| | (_| |  __/\ \_/ / |_) || |_| | | | | | | |/ /  __/ |   
 \___/_| |_| |_|\__,_|\__, |\___| \___/| .__/  \__|_|_| |_| |_|_/___\___|_|   
                       __/ |           | |                                    
                      |___/            |_|                                    
EOF
    echo -e "${RESET}"
    
    echo -e "${CYAN}"
    cat << "EOF"
   __             .___                     _____
 _/  |______    __| _/____ _____    ______/ ____\
 \   __\__  \  / __ |/ __ \\__  \  /  ___|   __\
  |  |  / __ \/ /_/ \  ___/ / __ \_\___ \ |  |    https://github.com/tadeasf
  |__| (____  |____ |\___  >____  /____  >|__|
            \/     \/    \/     \/
EOF
    echo -e "${RESET}"
}

# Function to prompt for directory with path completion
prompt_for_directory() {
    local prompt="$1"
    local dir
    read -e -p "$(echo -e "${YELLOW}${prompt}${RESET}")" dir
    echo "$dir"
}

# Function to prompt for longest side dimension
prompt_for_longest_side() {
    local longest_side
    read -p "$(echo -e "${YELLOW}Enter the longest side dimension in pixels: ${RESET}")" longest_side
    echo "$longest_side"
}

# Function to prompt for quality setting
prompt_for_quality() {
    local quality
    while true; do
        read -p "$(echo -e "${YELLOW}Choose quality setting (compressed/balanced/quality): ${RESET}")" quality
        case $quality in
            compressed|balanced|quality) break;;
            *) echo -e "${RED}Invalid input. Please enter 'compressed', 'balanced', or 'quality'.${RESET}";;
        esac
    done
    echo "$quality"
}

# Main script
clear
display_ascii_art

echo -e "${CYAN}Welcome to Image Optimizer!${RESET}"
echo

# Check for the -r argument
recursive_search=false
if [[ "$1" == "-r" ]]; then
    recursive_search=true
    shift
fi

# Get the input directory from the user
input_dir=$(prompt_for_directory "Enter the input directory: ")

# Validate the input directory
if [ ! -d "$input_dir" ]; then
    echo -e "${RED}Error: The specified input directory does not exist.${RESET}"
    exit 1
fi

# Get the longest side dimension from the user
longest_side=$(prompt_for_longest_side)

# Get the quality setting from the user
quality_setting=$(prompt_for_quality)

# Get the output directory from the user
output_dir=$(prompt_for_directory "Enter the output directory: ")

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

echo
echo -e "${BLUE}Processing images from:${RESET} $input_dir"
echo -e "${BLUE}Saving processed images to:${RESET} $output_dir"
echo -e "${BLUE}Longest side:${RESET} $longest_side pixels"
echo -e "${BLUE}Quality setting:${RESET} $quality_setting"
echo

# Set ImageMagick parameters based on quality setting
case $quality_setting in
    compressed)
        quality_params="-quality 85%"
        ;;
    balanced)
        quality_params="-sampling-factor 4:2:0 -quality 95%"
        ;;
    quality)
        quality_params="-sampling-factor 4:2:2 -quality 98%"
        ;;
esac

# Function to process a single image
process_image() {
    local file="$1"
    local filename=$(basename "$file")
    local output_file="$output_dir/$filename"
    local duplicates_dir="$output_dir/duplicates"
    local index=1

    # Check if the file already exists in the output directory
    if [ -f "$output_file" ]; then
        # Create duplicates directory if it doesn't exist
        mkdir -p "$duplicates_dir"

        # Generate a new filename with an index
        while [ -f "$duplicates_dir/${filename%.*}_$index.${filename##*.}" ]; do
            ((index++))
        done
        output_file="$duplicates_dir/${filename%.*}_$index.${filename##*.}"
    fi

    # Process the image
    magick "$file" -filter Lanczos -resize "${longest_side}x${longest_side}>" -strip -interlace Plane $quality_params "$output_file"
}

export -f process_image
export longest_side quality_params output_dir

echo -e "${CYAN}Optimizing images...${RESET}"
# Use parallel to process images with a progress bar
if $recursive_search; then
    find "$input_dir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | \
    parallel --will-cite --bar process_image
else
    find "$input_dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" \) | \
    parallel --will-cite --bar process_image
fi

echo
echo -e "${GREEN}All images have been processed and saved to $output_dir${RESET}"
echo -e "${YELLOW}Duplicate filenames (if any) have been saved in $output_dir/duplicates${RESET}"
echo

# Final ASCII art
echo -e "${MAGENTA}"
cat << "EOF"
   __             .___                     _____
 _/  |______    __| _/____ _____    ______/ ____\
 \   __\__  \  / __ |/ __ \\__  \  /  ___|   __\
  |  |  / __ \/ /_/ \  ___/ / __ \_\___ \ |  |    https://github.com/tadeasf
  |__| (____  |____ |\___  >____  /____  >|__|
            \/     \/    \/     \/
EOF
echo -e "${RESET}"

echo -e "${CYAN}Thank you for using Image Optimizer!${RESET}"
