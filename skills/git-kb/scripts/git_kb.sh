#!/bin/bash
#
# git_kb.sh - Git Knowledge Base Helper Script
#
# Usage: ./git_kb.sh {tree|read|search|tags|status|commit|sync}
#

set -e

KB_PATH="${GIT_KB_PATH:-$HOME/knowledge-base}"
KB_REPO="${GIT_KB_REPO}"

# Colors for output (disable if not terminal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    BLUE=''
    RED=''
    NC=''
fi

# Ensure repository is cloned locally
ensure_repo() {
    if [ ! -d "$KB_PATH/.git" ]; then
        if [ -z "$KB_REPO" ]; then
            echo -e "${RED}Error: GIT_KB_REPO not set and repository not cloned${NC}"
            echo "Set GIT_KB_REPO to your knowledge base repository URL"
            exit 1
        fi
        
        echo -e "${BLUE}Cloning knowledge base repository...${NC}"
        mkdir -p "$(dirname "$KB_PATH")"
        git clone "$KB_REPO" "$KB_PATH"
        echo -e "${GREEN}[OK] Repository cloned to $KB_PATH${NC}"
    fi
}

# Display tree structure with README info
cmd_tree() {
    ensure_repo
    
    local path="."
    local depth="3"
    local limit="10"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --depth)
                depth="$2"
                shift 2
                ;;
            --limit)
                limit="$2"
                shift 2
                ;;
            -*)
                shift
                ;;
            *)
                path="$1"
                shift
                ;;
        esac
    done
    
    cd "$KB_PATH"
    
    echo -e "${BLUE}Knowledge Base Tree:${NC}"
    echo ""
    
    # Use find to build tree-like structure with README descriptions
    local full_path="$KB_PATH/$path"
    full_path="${full_path%/}"  # Normalize path
    
    # Show current directory info
    if [ -f "$full_path/README.md" ]; then
        local title=$(head -1 "$full_path/README.md" | sed 's/^# //')
        echo -e "${GREEN}[DIR] $(basename "$full_path")/${NC} - $title"
    else
        echo -e "${GREEN}[DIR] $(basename "$full_path")/${NC}"
    fi
    
    # Build tree
    local indent="    "
    build_tree "$full_path" "$indent" "$depth" "$limit" 1
}

# Recursive tree builder
build_tree() {
    local current_path="$1"
    local current_indent="$2"
    local max_depth="$3"
    local limit="$4"
    local current_depth="$5"
    
    if [ "$current_depth" -ge "$max_depth" ]; then
        return
    fi
    
    # List directories first (excluding .git)
    local dirs=()
    while IFS= read -r -d '' dir; do
        dirs+=("$dir")
    done < <(find "$current_path" -maxdepth 1 -mindepth 1 -type d ! -name ".git" -print0 2>/dev/null | sort -z)
    
    local dir_count=${#dirs[@]}
    
    # Apply limit to directories
    local dirs_to_show=()
    local remaining_dirs=0
    if [ "$dir_count" -gt "$limit" ]; then
        for ((i=0; i<limit; i++)); do
            dirs_to_show+=("${dirs[$i]}")
        done
        remaining_dirs=$((dir_count - limit))
    else
        dirs_to_show=("${dirs[@]}")
    fi
    
    local i=0
    for dir in "${dirs_to_show[@]}"; do
        i=$((i + 1))
        local basename=$(basename "$dir")
        local is_last_dir=$([[ $i -eq ${#dirs_to_show[@]} && $remaining_dirs -eq 0 ]] && echo "1" || echo "0")
        local connector=$([ $is_last_dir -eq 1 ] && echo "└──" || echo "├──")
        
        # Get README description if exists
        local desc=""
        if [ -f "$dir/README.md" ]; then
            desc=$(head -1 "$dir/README.md" 2>/dev/null | sed 's/^# //')
        fi
        
        if [ -n "$desc" ]; then
            echo -e "${current_indent}${connector} ${GREEN}[DIR] $basename/${NC} - $desc"
        else
            echo -e "${current_indent}${connector} ${GREEN}[DIR] $basename/${NC}"
        fi
        
        # Recurse with increased indent
        local next_indent="${current_indent}$([ $is_last_dir -eq 1 ] && echo "    " || echo "│   ")"
        build_tree "$dir" "$next_indent" "$max_depth" "$limit" $((current_depth + 1))
    done
    
    # Show remaining dirs count
    if [ "$remaining_dirs" -gt 0 ]; then
        echo -e "${current_indent}└── ${YELLOW}... ${remaining_dirs} more directories${NC}"
    fi
    
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$current_path" -maxdepth 1 -mindepth 1 -type f -name "*.md" ! -name "README.md" -print0 2>/dev/null | sort -z)
    
    local file_count=${#files[@]}
    
    # Apply limit to files
    local files_to_show=()
    local remaining_files=0
    if [ "$file_count" -gt "$limit" ]; then
        for ((i=0; i<limit; i++)); do
            files_to_show+=("${files[$i]}")
        done
        remaining_files=$((file_count - limit))
    else
        files_to_show=("${files[@]}")
    fi
    
    local j=0
    for file in "${files_to_show[@]}"; do
        j=$((j + 1))
        local basename=$(basename "$file")
        local is_last=$([[ $j -eq ${#files_to_show[@]} && $remaining_files -eq 0 ]] && echo "1" || echo "0")
        local connector=$([ $is_last -eq 1 ] && echo "└──" || echo "├──")
        
        # Get title from frontmatter if exists
        local title=""
        if head -5 "$file" | grep -q "^title:"; then
            title=$(head -10 "$file" | grep "^title:" | sed 's/^title: *//' | sed "s/['\"]//g")
        fi
        
        if [ -n "$title" ]; then
            echo -e "${current_indent}${connector} ${BLUE}[FILE] $basename${NC} - $title"
        else
            echo -e "${current_indent}${connector} ${BLUE}[FILE] $basename${NC}"
        fi
    done
    
    if [ "$remaining_files" -gt 0 ]; then
        local connector=$([ $remaining_dirs -gt 0 ] && echo "│   " || echo "    ")
        echo -e "${current_indent}${connector}└── ${YELLOW}... ${remaining_files} more files${NC}"
    fi
}

# Read file content
cmd_read() {
    ensure_repo
    
    local file="$1"
    if [ -z "$file" ]; then
        echo -e "${RED}Error: No file specified${NC}"
        echo "Usage: read <path>"
        exit 1
    fi
    
    if [ ! -f "$KB_PATH/$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        exit 1
    fi
    
    cat "$KB_PATH/$file"
}

# Search files and content
cmd_search() {
    ensure_repo
    
    local query="$1"
    local search_path="${2:-.}"
    
    if [ -z "$query" ]; then
        echo -e "${RED}Error: No search query specified${NC}"
        echo "Usage: search <query> [--path path]"
        exit 1
    fi
    
    cd "$KB_PATH"
    
    echo -e "${BLUE}Searching for: $query${NC}"
    echo ""
    
    # Search file names (excluding .git)
    echo -e "${YELLOW}[DIR] Files matching '$query':${NC}"
    local files=$(find "$search_path" -name "*.md" ! -path "*/.git/*" | grep -i "$query" | sed "s|^\\./||" | sort)
    if [ -n "$files" ]; then
        echo "$files" | while read -r file; do
            echo "  • $file"
        done
    else
        echo "  (none)"
    fi
    
    echo ""
    
    # Search content (excluding .git)
    echo -e "${YELLOW}[CONTENT] Content matching '$query':${NC}"
    local matches=$(grep -r -l -i "$query" "$search_path" --include="*.md" --exclude-dir=".git" 2>/dev/null | sed "s|^\\./||" | sort)
    if [ -n "$matches" ]; then
        echo "$matches" | while read -r file; do
            # Show line count
            local count=$(grep -i -c "$query" "$file" 2>/dev/null || echo "0")
            echo "  • $file ($count matches)"
        done
    else
        echo "  (none)"
    fi
}

# List all tags
cmd_tags() {
    ensure_repo
    
    cd "$KB_PATH"
    
    echo -e "${BLUE}Tags used in Knowledge Base:${NC}"
    echo ""
    
    # Extract tags from frontmatter (excluding .git)
    grep -r "^tags:" . --include="*.md" --exclude-dir=".git" 2>/dev/null | \
        sed 's/.*tags: *//' | \
        tr ',' '\n' | \
        sed 's/^ *//' | \
        sed 's/ *$//' | \
        sed 's/[][]//g' | \
        grep -v '^$' | \
        sort | \
        uniq -c | \
        sort -rn | \
        while read -r line; do
            local count=$(echo "$line" | awk '{print $1}')
            local tag=$(echo "$line" | awk '{print $2}')
            echo "  $tag ($count)"
        done
}

# Show status
cmd_status() {
    ensure_repo
    
    cd "$KB_PATH"
    
    echo -e "${BLUE}Knowledge Base Status:${NC}"
    echo ""
    
    # Check for changes (modified, staged, or untracked)
    if [ -z "$(git status --porcelain)" ]; then
        echo -e "${GREEN}[OK] Working directory clean${NC}"
    else
        echo -e "${YELLOW}Modified files:${NC}"
        git status --short
    fi
    
    echo ""
    
    # Check remote sync status
    git fetch origin --quiet 2>/dev/null || true
    local behind=$(git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
    local ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")
    
    if [ "$behind" -gt 0 ]; then
        echo -e "${YELLOW}[WARN] Behind origin/main by $behind commit(s)${NC}"
        echo "  Run 'kb sync' to pull changes"
    elif [ "$ahead" -gt 0 ]; then
        echo -e "${YELLOW}[AHEAD] Ahead of origin/main by $ahead commit(s)${NC}"
        echo "  Run 'kb commit' or 'kb sync' to push"
    else
        echo -e "${GREEN}[OK] In sync with origin/main${NC}"
    fi
}

# Generate commit message from changes
generate_commit_message() {
    cd "$KB_PATH"
    
    local added=$(git diff --staged --name-status 2>/dev/null | grep "^A" | wc -l)
    local modified=$(git diff --staged --name-status 2>/dev/null | grep "^M" | wc -l)
    local deleted=$(git diff --staged --name-status 2>/dev/null | grep "^D" | wc -l)
    
    # Trim whitespace
    added=$(echo "$added" | xargs)
    modified=$(echo "$modified" | xargs)
    deleted=$(echo "$deleted" | xargs)
    
    local msg=""
    if [ "$added" -gt 0 ]; then msg="${msg}${added} added, "; fi
    if [ "$modified" -gt 0 ]; then msg="${msg}${modified} modified, "; fi
    if [ "$deleted" -gt 0 ]; then msg="${msg}${deleted} deleted, "; fi
    
    # Remove trailing comma and space
    msg="${msg%, }"
    
    echo "update: $msg"
}

# Commit and push changes
cmd_commit() {
    ensure_repo
    
    cd "$KB_PATH"
    
    # Stage all changes
    git add -A
    
    # Check if there are staged changes
    if git diff --staged --quiet; then
        echo -e "${YELLOW}No changes to commit${NC}"
        return 0
    fi
    
    # Get or generate message
    local message="$1"
    if [ -z "$message" ]; then
        message=$(generate_commit_message)
    fi
    
    echo -e "${BLUE}Committing with message:${NC} $message"
    echo ""
    
    # Show what will be committed
    echo -e "${YELLOW}Changes:${NC}"
    git diff --staged --stat
    echo ""
    
    # Commit
    git commit -m "$message"
    
    # Push
    echo -e "${BLUE}Pushing to origin/main...${NC}"
    git push
    
    echo -e "${GREEN}[OK] Committed and pushed${NC}"
}

# Sync with remote
cmd_sync() {
    ensure_repo
    
    cd "$KB_PATH"
    
    echo -e "${BLUE}Syncing with remote...${NC}"
    echo ""
    
    # Pull latest
    echo -e "${BLUE}Pulling latest changes...${NC}"
    git pull --rebase || {
        echo -e "${RED}Pull failed. Resolve conflicts manually.${NC}"
        exit 1
    }
    
    # Push any local changes
    if [ -n "$(git rev-list origin/main..HEAD 2>/dev/null)" ]; then
        echo -e "${BLUE}Pushing local changes...${NC}"
        git push
    fi
    
    echo -e "${GREEN}[OK] Sync complete${NC}"
}

# Show help
cmd_help() {
    echo "Git Knowledge Base Helper"
    echo ""
    echo "Usage: $0 {tree|read|search|tags|status|commit|sync}"
    echo ""
    echo "Commands:"
    echo "  tree [path] [--depth N] [--limit N]  Show folder structure"
    echo "  read <path>                Read file content"
    echo "  search <query> [--path]    Search files and content"
    echo "  tags                       List all tags"
    echo "  status                     Show current status"
    echo "  commit [message]           Commit and push changes"
    echo "  sync                       Pull and push"
    echo ""
    echo "Options:"
    echo "  --depth N    Max depth to display (default: 3)"
    echo "  --limit N    Max items per level (default: 10)"
    echo ""
    echo "Environment:"
    echo "  GIT_KB_PATH    Local KB directory (default: ~/knowledge-base)"
    echo "  GIT_KB_REPO    Remote repository URL"
}

# Main command dispatcher
case "$1" in
    tree)
        shift
        cmd_tree "$@"
        ;;
    read)
        shift
        cmd_read "$@"
        ;;
    search)
        shift
        cmd_search "$@"
        ;;
    tags)
        cmd_tags
        ;;
    status)
        cmd_status
        ;;
    commit)
        shift
        cmd_commit "$@"
        ;;
    sync)
        cmd_sync
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        cmd_help
        exit 1
        ;;
esac
