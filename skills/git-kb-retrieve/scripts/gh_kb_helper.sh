#!/bin/bash

set -e

REPO="${GIT_KB_REPO}"

if [ -z "$REPO" ]; then
    echo "Error: GIT_KB_REPO environment variable not set"
    exit 1
fi

check_repo() {
    gh repo view "$REPO" --json name > /dev/null 2>&1
}

get_markdown_files() {
    gh api -X GET "repos/$REPO/git/trees/main" -f recursive=1 2>/dev/null | \
        jq -r '.tree // [] | .[] | select(.type=="blob" and (.path | endswith(".md"))) | .path' | \
        sort
}

get_directory_structure() {
    gh api -X GET "repos/$REPO/git/trees/main" -f recursive=1 2>/dev/null | \
        jq -r '.tree // [] | .[] | select(.type=="tree") | .path' | \
        grep -E '^([^/]+/?){1,3}$' | \
        sort
}

get_directory_structure_deep() {
    local base_path="${1:-}"
    
    if [ -z "$base_path" ]; then
        get_directory_structure
        return
    fi
    
    base_path="${base_path%/}/"
    
    gh api -X GET "repos/$REPO/git/trees/main" -f recursive=1 2>/dev/null | \
        jq -r '.tree // [] | .[] | select(.type=="tree") | .path' | \
        grep "^${base_path}" | \
        grep -E '^([^/]+/?){1,3}$' | \
        sed "s|^${base_path}||" | \
        sort
}

get_markdown_files_deep() {
    local folder="${1:-}"
    
    if [ -z "$folder" ]; then
        get_markdown_files
        return
    fi
    
    folder="${folder%/}/"
    
    get_markdown_files | grep "^${folder}"
}

search_related_files() {
    local keywords="$1"
    local files
    files=$(get_markdown_files)
    
    echo "$files" | grep -i -E "$(echo "$keywords" | tr ' ' '|')" | head -10
}

read_file() {
    local path="$1"
    gh api "repos/$REPO/contents/$path" 2>/dev/null | \
        jq -r '.content' | \
        base64 -d
}

read_frontmatter() {
    local path="$1"
    read_file "$path" | head -30
}

create_file() {
    local path="$1"
    local content="$2"
    local message="$3"
    
    local content_b64
    content_b64=$(echo -n "$content" | base64)
    
    local existing_sha
    existing_sha=$(gh api "repos/$REPO/contents/$path" 2>/dev/null | jq -r '.sha // empty')
    
    if [ -n "$existing_sha" ]; then
        gh api "repos/$REPO/contents/$path" \
            -X PUT \
            -f message="$message" \
            -f content="$content_b64" \
            -f sha="$existing_sha" \
            -f branch=main \
            > /dev/null 2>&1
    else
        gh api "repos/$REPO/contents/$path" \
            -X PUT \
            -f message="$message" \
            -f content="$content_b64" \
            -f branch=main \
            > /dev/null 2>&1
    fi
}

create_file_from_file() {
    local path="$1"
    local source_file="$2"
    local message="$3"
    
    if [ ! -f "$source_file" ]; then
        echo "Error: Source file not found: $source_file"
        exit 1
    fi
    
    local content_b64
    content_b64=$(base64 < "$source_file")
    
    local existing_sha
    existing_sha=$(gh api "repos/$REPO/contents/$path" 2>/dev/null | jq -r '.sha // empty')
    
    if [ -n "$existing_sha" ]; then
        gh api "repos/$REPO/contents/$path" \
            -X PUT \
            -f message="$message" \
            -f content="$content_b64" \
            -f sha="$existing_sha" \
            -f branch=main \
            > /dev/null 2>&1
    else
        gh api "repos/$REPO/contents/$path" \
            -X PUT \
            -f message="$message" \
            -f content="$content_b64" \
            -f branch=main \
            > /dev/null 2>&1
    fi
}

path_exists() {
    local path="$1"
    gh api "repos/$REPO/contents/$path" 2>/dev/null | jq -e '.path' > /dev/null 2>&1
}

get_file_url() {
    local path="$1"
    echo "https://github.com/$REPO/blob/main/$path"
}

case "$1" in
    check)
        if check_repo; then
            echo "Repository $REPO is accessible"
            exit 0
        else
            echo "Error: Cannot access repository $REPO"
            exit 1
        fi
        ;;
    list-files)
        if [ -z "$2" ]; then
            get_markdown_files
        else
            get_markdown_files_deep "$2"
        fi
        ;;
    list-dirs)
        if [ -z "$2" ]; then
            get_directory_structure
        else
            get_directory_structure_deep "$2"
        fi
        ;;
    search)
        search_related_files "$2"
        ;;
    read)
        read_file "$2"
        ;;
    read-frontmatter)
        read_frontmatter "$2"
        ;;
    create)
        create_file "$2" "$3" "$4"
        echo "File created/updated: $2"
        ;;
    create-from-file)
        create_file_from_file "$2" "$3" "$4"
        echo "File created/updated: $2"
        ;;
    exists)
        if path_exists "$2"; then
            echo "true"
        else
            echo "false"
        fi
        ;;
    url)
        get_file_url "$2"
        ;;
    *)
        echo "Usage: $0 {check|list-files|list-dirs|search|read|read-frontmatter|create|create-from-file|exists|url}"
        echo ""
        echo "Commands:"
        echo "  check                       - Verify repo is accessible"
        echo "  list-files                  - List all markdown files"
        echo "  list-files <path>          - List files in specific folder"
        echo "  list-dirs                   - Show top 3 directory levels"
        echo "  list-dirs <path>           - Show 3 levels under path"
        echo "  search <keywords>          - Find files matching keywords"
        echo "  read <path>                - Read file content"
        echo "  read-frontmatter <path>    - Read only frontmatter"
        echo "  create <path> <content> <msg>   - Create file (simple)"
        echo "  create-from-file <path> <file> <msg> - Create file from file"
        echo "  exists <path>              - Check if path exists"
        echo "  url <path>                 - Get file URL"
        exit 1
        ;;
esac
