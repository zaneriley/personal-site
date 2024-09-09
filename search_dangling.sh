#!/bin/bash

# Search term passed as an argument
SEARCH_TERM="$1"

# Function to search a single object
search_object() {
    OBJECT="$1"
    if git show "$OBJECT" 2>/dev/null | grep -q "$SEARCH_TERM"; then
        echo "Found in $OBJECT:"
        git show "$OBJECT" | grep -C3 "$SEARCH_TERM"
        echo "------------------------"
    fi
}

# Search dangling blobs
git fsck --lost-found --dangling --no-reflogs | grep "dangling blob" | cut -d' ' -f3 | while read blob; do
    search_object "$blob"
done

# Search dangling commits
git fsck --lost-found --dangling --no-reflogs | grep "dangling commit" | cut -d' ' -f3 | while read commit; do
    search_object "$commit"
done