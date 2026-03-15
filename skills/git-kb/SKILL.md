---
name: git-kb
description: Unified knowledge base skill for reading and writing to a Git-managed personal knowledge base. Supports tree navigation, full-text search, and collaborative editing between humans and AI. Use this skill when the user wants to query their personal knowledge base, save notes or session summaries, or manage knowledge base content. Trigger on phrases like "what do I know about", "record to KB", "save this to knowledge base", "search my notes", "find in KB".
---

# Git Knowledge Base

Read, search, and contribute to your personal knowledge base stored in Git.

## Core Philosophy

This knowledge base is designed for **collaboration between humans and AI agents**:

- **Local-first**: Clone locally, work fast, push to sync
- **Self-documenting**: README.md at every folder level provides navigation
- **Git-powered**: Full version control, works offline, familiar workflow
- **Descriptive naming**: Long, clear file names over abbreviations
- **Human + AI**: Humans mainly read, AI mainly writes (with approval)

## Environment Setup

Required environment variables:

```bash
export GIT_KB_PATH="$HOME/knowledge-base"       # Local clone location
export GIT_KB_REPO="git@github.com:user/kb.git" # Remote repository URL
```

## Helper Script Commands

All commands are available through the helper script at `scripts/git_kb.sh`:

### Read Operations

```bash
# Show folder tree structure
./scripts/git_kb.sh tree [path] [--depth N]

# Read file content
./scripts/git_kb.sh read <path>

# Search files and content
./scripts/git_kb.sh search <query> [--path path]

# List all tags used across the KB
./scripts/git_kb.sh tags

# Check KB status (changes, sync state)
./scripts/git_kb.sh status
```

### Write Operations

```bash
# Commit all staged changes and push
./scripts/git_kb.sh commit "message"

# Sync with remote (pull then push)
./scripts/git_kb.sh sync
```

## Workflows

### Querying the Knowledge Base

When the user asks "What do I know about X?" or "Search my notes for Y":

1. **Explore structure**: Run `tree` to see the folder hierarchy
2. **Search**: Use `search` to find relevant files
3. **Read**: Use `read` to get file contents
4. **Synthesize**: Answer based on the content found

Example:
```bash
# User: "What do I know about JWT?"
./scripts/git_kb.sh tree concepts/ --depth 2
./scripts/git_kb.sh search "JWT"
./scripts/git_kb.sh read concepts/authentication/jwt-implementation-patterns.md
```

### Capturing Knowledge

When the user wants to save notes, session summaries, or new knowledge:

**Important**: Create files directly using file tools, NOT through shell commands. This avoids escaping issues with complex content.

1. **Write file directly**: Use the `write` tool to create/edit files in `$GIT_KB_PATH/`
2. **Show preview**: Display what was created/modified to the user
3. **Get approval**: Wait for user to confirm
4. **Commit**: Run `commit` to push changes

Example:
```
User: "Record this session to KB"

AI: [Uses write tool to create $GIT_KB_PATH/concepts/auth/new-topic.md]

"I created: concepts/auth/jwt-security-checklist.md
 
 Preview:
 ---
 title: JWT Security Checklist
 ...
 
 Commit with message 'feat(auth): Add JWT security checklist'?"

User: "yes"

AI: [Runs ./scripts/git_kb.sh commit "feat(auth): Add JWT security checklist"]
```

### Batch Operations

For multiple related changes:

1. Create/edit all files directly
2. Show summary of all changes
3. Commit once with descriptive message

Example:
```
AI: "I created 3 files:
   - A  concepts/auth/jwt-security.md
   - A  decisions/004-jwt-implementation.md  
   - M  concepts/auth/README.md
   
   Commit with 'feat(auth): Document JWT patterns and decisions'?"
```

## File Organization

### Naming Conventions

- **Descriptive names**: Use full phrases, not abbreviations
  - ✅ `jwt-implementation-patterns-for-microservices.md`
  - ❌ `jwt.md`

- **Consistent separators**: Use kebab-case (hyphens)
  - ✅ `database-connection-pooling.md`
  - ❌ `database_connection_pooling.md`

- **Date prefixes** (optional): For time-sensitive notes
  - `2025-03-15-saas-architecture-decision.md`

### Frontmatter Schema

Every file should include YAML frontmatter:

```yaml
---
title: "Descriptive Title"
created: 2025-03-15
updated: 2025-03-15
type: concept  # concept, decision, reference, snippet, project
tags: [tag1, tag2, tag3]
status: active  # active, draft, archived
---
```

### Folder Structure

The KB structure is **flexible** - organize however makes sense for your needs:

```
kb/
├── README.md                          # Root index
├── work-projects/                     # Project documentation
│   ├── README.md
│   ├── saas-platform/
│   │   ├── README.md
│   │   ├── architecture/
│   │   └── decisions/
├── concepts/                          # Knowledge domains
│   ├── README.md
│   ├── authentication/
│   │   ├── README.md
│   │   ├── jwt-implementation.md
│   │   └── oauth2-flows.md
└── snippets/                          # Code snippets, templates
    └── README.md
```

**README.md at every level** provides:
- Directory listing with descriptions
- File index with metadata
- Navigation aid for humans and AI

These READMEs are **auto-generated by CI** - don't edit them manually.

## Helper Script Reference

### tree [path] [--depth N]

Display folder structure with README summaries.

```bash
./scripts/git_kb.sh tree
./scripts/git_kb.sh tree concepts/auth
./scripts/git_kb.sh tree --depth 4
```

### read <path>

Display file content.

```bash
./scripts/git_kb.sh read concepts/auth/jwt-patterns.md
```

### search <query> [--path path]

Search file names and content.

```bash
./scripts/git_kb.sh search "authentication"
./scripts/git_kb.sh search "JWT" --path concepts
```

### tags

List all tags used across the KB with counts.

```bash
./scripts/git_kb.sh tags
```

### status

Show current state: modified files, untracked files, sync status.

```bash
./scripts/git_kb.sh status
```

### commit "message"

Stage all changes, commit with message, and push to remote.

```bash
./scripts/git_kb.sh commit "feat(auth): Add JWT patterns"
```

If no message provided, generates one based on changes.

### sync

Pull latest changes from remote, then push local changes.

```bash
./scripts/git_kb.sh sync
```

## Best Practices

1. **Always preview before commit**: Show user what will change
2. **Get explicit approval**: Never commit without user saying yes
3. **Use descriptive messages**: Explain what changed and why
4. **Batch related changes**: Commit multiple files together when related
5. **Check status first**: See what's already staged before adding more
6. **Use frontmatter**: Include proper YAML frontmatter in new files

### File Content Guidelines

- **Start with context**: What is this about?
- **Use clear structure**: Headers, lists, code blocks
- **Include examples**: Show don't just tell
- **Link related content**: Build a connected knowledge graph
- **Update timestamps**: Keep `updated` field current

## Troubleshooting

### Repository not cloned

```bash
export GIT_KB_REPO="git@github.com:youruser/yourkb.git"
export GIT_KB_PATH="$HOME/knowledge-base"
./scripts/git_kb.sh tree  # Will auto-clone
```

### Merge conflicts

If human and AI edit simultaneously:

```bash
cd $GIT_KB_PATH
git status
# Resolve conflicts manually or:
git checkout --theirs .
git add -A
./scripts/git_kb.sh commit "resolve: merge conflict"
```

## Example Session

```
User: What decisions have I made about authentication?

AI: [Runs ./scripts/git_kb.sh search "authentication"]
    [Runs ./scripts/git_kb.sh search "decision" --path decisions]
    
    "I found these auth-related decisions:
    
    1. decisions/003-migrate-to-jwt-auth.md
       - Date: 2025-03-10
       - Status: accepted
       - Decision: Migrate from session-based to JWT auth
    
    2. decisions/007-oauth2-provider-selection.md
       - Date: 2025-03-12
       - Status: pending
       - Decision: Evaluating Auth0 vs Keycloak
    
    Would you like me to read the full content of any of these?"

User: Read the first one

AI: [Runs ./scripts/git_kb.sh read decisions/003-migrate-to-jwt-auth.md]
    
    "Here's the decision record:
    
    [Full content displayed...]"

User: Record this discussion about refresh tokens

AI: [Uses write tool to create $GIT_KB_PATH/concepts/auth/refresh-token-rotation-patterns.md]

    "I created a new note:
    
    📄 concepts/auth/refresh-token-rotation-patterns.md
    
    Preview:
    ---
    title: Refresh Token Rotation Patterns
    created: 2025-03-15
    tags: [jwt, security, patterns]
    ---
    
    # Refresh Token Rotation Patterns
    
    ## Context
    Discussion about secure refresh token handling...
    
    ## Patterns
    - Rotation on every use
    - Detection of reuse (token family)
    - Automatic revocation chains
    
    Commit with message 'feat(auth): Add refresh token rotation patterns'?"

User: Yes

AI: [Runs ./scripts/git_kb.sh commit "feat(auth): Add refresh token rotation patterns"]

    "✓ Committed and pushed. CI will auto-update the README index."
```
