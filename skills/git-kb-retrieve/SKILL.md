---
name: git-kb-retrieve
description: Browse and retrieve knowledge from a GitHub-based knowledge base by navigating the folder tree structure. Use this skill when you need to find information from the user's personal knowledge base. The skill retrieves the complete folder tree using gh-cli, presents the structure in levels, and allows drilling down to specific branches to find and read relevant files.
---

# Knowledge Base Tree Browsing

Browse and retrieve knowledge from a GitHub-based knowledge repository by navigating its hierarchical folder tree structure. Use the decision-tree organization to drill down and locate relevant information.

## Core Approach:

**Start with top levels, drill down progressively.** The KB has a deep nested structure. Get the top 3 levels first, then navigate deeper by passing a path to the list commands.

**Navigate, then read.** Once you identify the relevant folder branch, list the files, read frontmatter first, then read only relevant files.

## Required Environment

```bash
export GIT_KB_REPO="owner/repo-name"
```

## Helper Script Commands

```bash
# Get top 3 directory levels (start here)
./scripts/gh_kb_helper.sh list-dirs

# Drill down: get 3 levels under a specific path
./scripts/gh_kb_helper.sh list-dirs "domain/development/stack"

# Get all markdown files in repo
./scripts/gh_kb_helper.sh list-files

# Get markdown files in a specific folder (and subfolders)
./scripts/gh_kb_helper.sh list-files "domain/development/backend"

# Read a specific file
./scripts/gh_kb_helper.sh read "domain/development/backend/auth/jwt-patterns.md"

# Read only frontmatter (title, description, tags) - START HERE for file selection
./scripts/gh_kb_helper.sh read-frontmatter "domain/development/backend/auth/jwt-patterns.md"

# Check if path exists
./scripts/gh_kb_helper.sh exists "domain/development/backend/auth"
```

## Progressive Navigation Workflow

### Step 1: Get Top-Level Tree

Start by getting the top 3 levels:

```bash
./scripts/gh_kb_helper.sh list-dirs

# Example output:
domain
domain/development
domain/development/layer
domain/development/stack
domain/operations
domain/research
```

### Step 2: Drill Down Based on Question

Identify the relevant branch from the tree, then drill down:

```
User asks about: "authentication"
From tree: domain/development/layer/backend/concern/auth/
→ Drill down: domain/development/layer/backend/concern/

User asks about: "React performance"
From tree: domain/development/stack/react/
→ Drill down: domain/development/stack/

User asks about: "deployment"
From tree: domain/operations/deployment/
→ Drill down: domain/operations/
```

### Step 3: Get Sub-Levels

```bash
# Get next 3 levels under a specific path
./scripts/gh_kb_helper.sh list-dirs "domain/development/layer"

# Example output:
backend
backend/concern
backend/concern/auth
backend/concern/database
backend/concern/api-design
frontend
frontend/concern
frontend/component
```

### Step 4: List Files in Target Folder

```bash
# Get all files in a specific branch
./scripts/gh_kb_helper.sh list-files "domain/development/layer/backend/concern/auth"

# Example output:
domain/development/layer/backend/concern/auth/jwt-patterns.md
domain/development/layer/backend/concern/auth/oauth-setup.md
domain/development/layer/backend/concern/auth/session-management.md
```

### Step 5: Read Frontmatter First, Then Select Files

**Don't read everything - be selective.** Use frontmatter to understand what each file contains before deciding which ones to read fully.

```bash
# First: Get frontmatter from all files in the branch
for file in $(./scripts/gh_kb_helper.sh list-files "domain/development/layer/backend/concern/auth"); do
  echo "=== $file ==="
  ./scripts/gh_kb_helper.sh read-frontmatter "$file"
  echo ""
done
```

**Based on frontmatter, decide which files to read fully:**
- If user's question matches title/description → read full file
- If tags contain relevant keywords → read full file
- If unsure → read it anyway
- If clearly irrelevant → skip

```bash
# Second: Read full content of only the relevant files
./scripts/gh_kb_helper.sh read "domain/development/layer/backend/concern/auth/jwt-patterns.md"
./scripts/gh_kb_helper.sh read "domain/development/layer/backend/concern/auth/oauth-setup.md"
# Skip session-management.md if not relevant to the question
```

## Drill-Down Examples

```bash
# User: "How do I handle authentication?"

# Step 1: Get top levels
./scripts/gh_kb_helper.sh list-dirs
# → domain, domain/development, domain/development/layer...

# Step 2: Drill to domain/development/layer
./scripts/gh_kb_helper.sh list-dirs "domain/development/layer"
# → backend, backend/concern, frontend...

# Step 3: Drill to backend/concern
./scripts/gh_kb_helper.sh list-dirs "domain/development/layer/backend/concern"
# → auth, database, api-design...

# Step 4: List all auth files
./scripts/gh_kb_helper.sh list-files "domain/development/layer/backend/concern/auth"
# → jwt-patterns.md, oauth-setup.md, session-management.md

# Step 5: Read frontmatter first to understand each file
for file in $(./scripts/gh_kb_helper.sh list-files "domain/development/layer/backend/concern/auth"); do
  ./scripts/gh_kb_helper.sh read-frontmatter "$file"
done

# Step 6: Read full content of selected files
./scripts/gh_kb_helper.sh read "domain/development/layer/backend/concern/auth/jwt-patterns.md"
./scripts/gh_kb_helper.sh read "domain/development/layer/backend/concern/auth/oauth-setup.md"
```

## File Listing Patterns

### List All Files (No Filter) - Use with Caution

**Warning: `list-files` without a path returns ALL markdown files in the KB.** This can be thousands of files. Use only when you need a global search.

```bash
# Returns every .md file - can be very slow
./scripts/gh_kb_helper.sh list-files
```

### List Files in Folder (Recommended)

```bash
./scripts/gh_kb_helper.sh list-files "domain/development/stack/react"
# Returns all React-related files

./scripts/gh_kb_helper.sh list-files "domain/development/layer/backend/concern/auth"
# Returns all auth-related files
```

### Filter by Date (Recent First)

```bash
# List files, sorted by name (dates in YYYY-MM-DD format)
./scripts/gh_kb_helper.sh list-files "auth/" | sort | tail -3

# Read most recent file
latest=$(./scripts/gh_kb_helper.sh list-files "auth/" | sort | tail -1)
./scripts/gh_kb_helper.sh read "$latest"
```

## Remember

- **Start with `list-dirs`** (no args) - get top 3 levels
- **Drill with `list-dirs <path>`** - get next 3 levels under path
- **List with `list-files <path>`** - get all files in a branch
- **Read frontmatter first** - use `read-frontmatter` to understand each file before reading
- **Read selectively** - only read full files that match user's question
- **Navigate the hierarchy** - don't jump to conclusions
