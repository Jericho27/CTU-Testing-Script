#!/usr/bin/env bash

# Initialize flags
verbose=0
time_flag=0
compile_flag=1 # Flag to enable/disable compilation (1 = compile, 0 = no compile)
help_flag=0
compile_only_flag=0 # Flag for compile only

# Help message function
show_help() {
    echo "Usage: $0 [-v] [-t] [-n] [-h] [-c] <file_name> <datapub_directory>

Options:
  -v    Enable verbose mode (shows output differences if a test fails).
  -t    Show the time taken for each test case to run.
  -n    Disable compilation (useful for running programs in other languages).
  -h    Show this help message.
  -c    Compile only (no testing, just compilation)."
    exit 0
}

# Parse options using getopts
while getopts "vtnhc" opt; do
    case $opt in
        v)
            verbose=1
            ;;
        t)
            time_flag=1
            ;;
        n)
            compile_flag=0
            ;;
        h)
            help_flag=1
            ;;
        c)
            compile_only_flag=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            show_help
            ;;
    esac
done

# If the help flag is set, show help
if [ $help_flag -eq 1 ]; then
    show_help
fi

# Shift the arguments so that positional arguments (file and directory) remain
shift $((OPTIND-1))

# Check if at least one positional argument is provided (file name)
if [ $# -lt 1 ]; then
    echo "Error: Missing required arguments."
    show_help
fi

# Store the base file name (without extension) from the remaining arguments
file_name=$1

# Set the full file name (with .cpp extension) for compilation
file_name_with_ext="${file_name}.cpp"

# Compile the program if the compile_flag is set
if [ $compile_flag -eq 1 ]; then
    g++ -std=c++14 -pipe -Wall -O3 "$file_name_with_ext" -o "$file_name" && echo "Compilation successful."

    # Check if compilation was successful
    if [ $? -ne 0 ]; then
        echo "Compilation failed!"
        exit 1
    fi
fi

# If the compile-only flag is set, exit after compilation
if [ $compile_only_flag -eq 1 ]; then
    exit 0
fi

# Check if at least two positional arguments are provided (file name and directory) for testing
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments for testing."
    show_help
fi

# Store the directory from the remaining arguments
datapub=$2

# Define color codes
GREEN='\033[1;32m' # Bold green
RED='\033[1;31m'   # Bold red
WHITE='\033[0;37m' # Regular white for text output
NC='\033[0m'       # No Color

# Loop through all input files in the specified directory
for input_file in "$datapub"/pub*.in; do
    # Get the base name of the file (e.g., pub01, pub02, etc.)
    base_name=$(basename "$input_file" .in)
    
    # Expected output file
    expected_output="$datapub/$base_name.out"
    
    # Measure the time taken for the program to run if the time flag is set
    if [ $time_flag -eq 1 ]; then
        start_time=$(date +%s%N)
    fi
    
    # Run the program with the input file and redirect output to a temporary file
    ./${file_name} < "$input_file" > temp_output.txt
    
    # Compare the actual output with the expected output and print result first
    if diff -q temp_output.txt "$expected_output" > /dev/null; then
        echo -e "${GREEN}$base_name: Passed${NC}"
    else
        echo -e "${RED}$base_name: Failed${NC}"
        
        # Show the actual output vs expected output only for failed tests if verbose is enabled
        if [ $verbose -eq 1 ]; then
            echo -e "${WHITE}Your Output:${NC}"
            cat temp_output.txt
            echo -e "${WHITE}Expected Output:${NC}"
            cat "$expected_output"
        fi
    fi
    
    # Calculate and print the time taken if the time flag is set
    if [ $time_flag -eq 1 ]; then
        end_time=$(date +%s%N)
        elapsed_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
        echo "Time taken for $base_name: ${elapsed_time} ms"
    fi
    
done

# Clean up temporary file
rm temp_output.txt