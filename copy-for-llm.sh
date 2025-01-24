#!/bin/bash

# Exit on error (only for critical failures) and enable error tracing
# but we'll selectively handle non-fatal errors in the loop so we can continue processing.
set -e


VERSION="1.0.0"

# Default values
output_file="code_output.md"
verbose=false
relative=false
language=""

# Help message
show_help() {
    cat << EOF
Usage: ${0##*/} [-h] [-v] [-r] [-l LANG] [-o FILE] PATHS...
Copy file contents with markdown formatting to output file.

    -h, --help              Show this help message
    -v, --verbose          Show detailed progress
    -r, --relative         Use relative paths
    -l, --language LANG    Specify language for code blocks
    -o, --output FILE      Output file (default: code_output.md)

PATHS can be files or directories. Directories will be processed recursively.
EOF
}

# Process options
while :; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            verbose=true
            ;;
        -r|--relative)
            relative=true
            ;;
        -l|--language)
            if [ -n "$2" ]; then
                language="$2"
                shift
            else
                echo "Error: --language requires a non-empty option argument." >&2
                exit 1
            fi
            ;;
        -o|--output)
            if [ -n "$2" ]; then
                output_file="$2"
                shift
            else
                echo "Error: --output requires a non-empty option argument." >&2
                exit 1
            fi
            ;;
        --)
            shift
            break
            ;;
        -?*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
    esac
    shift
done

# Check if paths were provided
if [ $# -eq 0 ]; then
    echo "Error: No input paths specified" >&2
    show_help
    exit 1
fi

# Initialize output file
> "$output_file"

# Function to process a single file
process_file() {
    local file="$1"

    if [ ! -r "$file" ]; then
        echo "Error: Cannot read file: $file" >&2
        return 1
    fi

    # Determine path to display
    if [ "$relative" = true ]; then
        display_path="$file"
    else
        display_path="$(realpath "$file")"
    fi

    # Determine language for code block
    if [ -n "$language" ]; then
        lang_spec="$language"
    else
        # Try to detect from file extension
        ext="${file##*.}"
        lang_spec="$ext"
    fi

    if [ "$verbose" = true ]; then
        echo "Processing file: $file"
    fi

    # Write to output file with markdown formatting
    {
        echo "# $display_path"
        echo
        echo "\`\`\`$lang_spec"
        cat "$file"
        echo "\`\`\`"
        echo
    } >> "$output_file"
}

# Function to process a directory
process_directory() {
    local dir="$1"

    if [ ! -r "$dir" ]; then
        echo "Error: Cannot read directory: $dir" >&2
        return 1
    fi

    if [ "$verbose" = true ]; then
        echo "Processing directory: $dir"
    fi

    # Find all regular files in the directory, excluding hidden files and directories
    while IFS= read -r -d '' file; do
        process_file "$file"
    done < <(find "$dir" -type f ! -path '*/\.*' -print0)
}

# Process each path
for path in "$@"; do
    if [ ! -e "$path" ]; then
        echo "Error: Path not found: $path" >&2
        continue
    fi

    if [ -d "$path" ]; then
        process_directory "$path"
    elif [ -f "$path" ]; then
        process_file "$path"
    else
        echo "Error: Not a regular file or directory: $path" >&2
    fi
done

if [ "$verbose" = true ]; then
    echo "Output saved to: $output_file"
fi 