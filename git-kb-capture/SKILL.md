---
name: git-kb-capture
description: Capture chat session summaries to a GitHub-based knowledge base repository. Use this skill when the user wants to save chat content, insights, decisions, or summaries to their personal knowledge base.
---

## Core Principles

**ALWAYS show the draft to the user before committing.** Every commit require explicit approval from user. The user must see exactly what will be saved and where.

**Explore before suggesting.** Always inspect the existing repository structure and content to understand the user's organization patterns before proposing where to save new notes.

**Follow existing conventions.** Match the directory structure, naming patterns, and frontmatter style already present in the knowledge base.

**Connect related knowledge.** Find and link to existing notes on similar topics to build a connected knowledge graph.

## Required Environment

The skill requires the `GIT_KB_REPO` environment variable:

```bash
export GIT_KB_REPO="owner/repo-name"
```

**Setup instructions** (if env var is missing):
1. Create a GitHub repository for your knowledge base
2. Add to your shell configuration (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):
   ```bash
   export GIT_KB_REPO="yourusername/your-kb-repo"
   ```
3. Ensure GitHub CLI is authenticated:
   ```bash
   gh auth login
   ```
4. Reload your shell or run `source ~/.bashrc`

## Helper Script

This skill bundles a helper script at `scripts/gh_kb_helper.sh` that wraps common gh-cli operations. Use it instead of typing raw gh commands:

```bash
# Check repo is accessible
./scripts/gh_kb_helper.sh check

# List all markdown files
./scripts/gh_kb_helper.sh list-files

# Show directory structure (first 3 levels)
./scripts/gh_kb_helper.sh list-dirs

# Show directory structure under a specific path (drill down)
./scripts/gh_kb_helper.sh list-dirs "domain/development/stack"
./scripts/gh_kb_helper.sh list-dirs "domain/development/layer/backend/concern"

# Search for related files
./scripts/gh_kb_helper.sh search "auth jwt"

# Read a file's content
./scripts/gh_kb_helper.sh read "domain/development/backend/auth/jwt.md"

# Check if path exists
./scripts/gh_kb_helper.sh exists "domain/development/backend/auth"

# Create a file from source file
./scripts/gh_kb_helper.sh create-from-file "path/to/file.md" "/path/to/source.md" "commit message"

```

The helper script handles all the gh-cli API calls, base64 encoding, and error handling.

## Workflow

### Step 1: Check Environment

Verify `GIT_KB_REPO` is set and the repository exists:

```bash
./scripts/gh_kb_helper.sh check
```

If the environment is not configured, show the setup instructions above and ask the user to configure it before proceeding.

### Step 2: Determine Focus

Check if the user specified a focus area:

- **With focus**: "record the install process to kb", "save the auth discussion"
  - Extract the focus: "install process", "auth discussion"
  - Summarize ONLY content related to that focus
  
- **Without focus**: "record to kb", "save this chat"
  - Create a general summary of key points, decisions, and insights from the entire session

### Step 3: Explore Repository Structure

Use the helper script to understand the existing knowledge base:

```bash
# Get all markdown files (Use with Caution)
./scripts/gh_kb_helper.sh list-files

# Show directory structure (first 3 levels)
./scripts/gh_kb_helper.sh list-dirs

# Drill down into a specific path to see deeper levels
./scripts/gh_kb_helper.sh list-dirs "domain/development/stack"
./scripts/gh_kb_helper.sh list-dirs "domain/development/layer/backend"
```

**Analyze the structure**:
- Identify the top-level organization (domain/, date/, topic/, etc.)
- Note naming conventions (kebab-case, dates, topic names)
- Look for existing patterns in directory hierarchy
- Use `list-dirs "path"` to explore specific branches deeper

**Search for related content**:

```bash
# Search for files matching keywords from the focus/topic
./scripts/gh_kb_helper.sh search "auth authentication jwt"
```

If files are found, read their frontmatter to understand their scope:

```bash
./scripts/gh_kb_helper.sh read-frontmatter "domain/development/backend/auth/jwt-patterns.md"
```

### Step 4: Suggest Location

Based on the exploration, propose a file path following existing patterns:

**Decision tree structure** (adapt to user's actual structure):
```
domain/development/layer/backend/concern/auth/2025-03-07-session.md
domain/development/stack/react/2025-03-07-performance-optimization.md
domain/research/architecture/2025-03-07-microservices-decision.md
```

**Present the suggestion**:
```
I'll save this to your knowledge base. Here's what I found:

📊 Existing structure: domain/development/layer/backend/concern/

📄 Related notes found:
   • domain/development/backend/auth/jwt-patterns.md
   • domain/development/backend/auth/oauth-setup.md

📁 Suggested location:
   domain/development/backend/auth/2025-03-07-auth-session.md

Tags: [jwt, authentication, security, best-practices]

Does this look right? You can:
• [approve] - Save here
• [change path] - Tell me the new path
• [merge] - Append to existing jwt-patterns.md
• [cancel] - Don't save
```

### Step 5: Generate Content

Create the note with YAML frontmatter:

```markdown
---
date: 2025-03-07
focus: {extracted_focus_or_null}
type: development  # development, qa, research, general
tags: [tag1, tag2, tag3]
related_notes:
  - domain/development/backend/auth/jwt-patterns.md
  - domain/development/backend/auth/oauth-setup.md
---

# {Focus or Session Summary Title}

## Context
{What was being discussed}

## Key Points
- Point 1
- Point 2
- Point 3

## Decisions Made
- Decision 1
- Decision 2

## Code Snippets
```javascript
// Important code example from discussion
```

## Insights & Learnings
- Learning 1
- Learning 2

## Related Notes
- [JWT Patterns](./jwt-patterns.md)
- [OAuth Setup](./oauth-setup.md)
- [Security Best Practices](../security/best-practices.md)

```

**Content rules**:
- If focus was specified, include only content related to that focus
- If no focus, include a general summary of key points and insights
- Include code snippets only if they're significant to the discussion
- Link to related notes discovered in Step 3

### Step 6: Show Draft for Approval

**CRITICAL**: Always show the complete draft before committing:

```
Here's what I'll save:

📁 File: domain/development/backend/auth/2025-03-07-auth-session.md

📝 Content:
---
date: 2025-03-07
focus: auth patterns
type: development
tags: [jwt, authentication, security]
---

# Auth Patterns Discussion

## Context
Discussion about implementing JWT authentication...

[... full content ...]

---

Approve to commit and push to $GIT_KB_REPO?
• [yes] - Commit and push
• [edit] - Tell me what to change
• [cancel] - Don't save
```

### Step 7: Commit and Push (Only proceed after explicit user approval)

Create the file using the helper script:

```bash
# Write content to temp file
echo "{markdown_content}" > /tmp/kb-note.md

# Create file from temp file (RECOMMENDED)
./scripts/gh_kb_helper.sh create-from-file "path/to/file.md" "/tmp/kb-note.md" "Add: {focus} - {date}"

# Cleanup
rm /tmp/kb-note.md
```

**Confirm success**:
```
✅ Saved to: https://github.com/$GIT_KB_REPO/blob/main/{file_path}

Commit: Add: auth patterns - 2025-03-07
```

## Handling Edge Cases

### If repo has no existing structure

```
Your knowledge base is empty. I'll create the first note.

Suggested structure:
domain/development/backend/auth/2025-03-07-auth-session.md

This follows a domain/layer/concern hierarchy. You can reorganize later.
```

### If the suggested path already exists

```
A file already exists at this location:
domain/development/backend/auth/2025-03-07-auth-session.md

Options:
1. [create new] - Use a different filename
2. [append] - Add to existing file
3. [overwrite] - Replace existing content (not recommended)
```

### If multiple related locations found

```
This topic could fit in multiple places:
• domain/development/backend/auth/ (existing auth notes)
• domain/development/frontend/auth/ (cross-cutting concern)
• domain/research/security/ (security-focused)

Which location would you prefer?
```

### If user wants to change the path

Accept the new path and adjust accordingly. Always confirm the new path before proceeding.

## Examples

**Example 1: With specific focus**
```
User: "record the docker setup process to kb"

Agent: Saves to domain/development/stack/docker/2025-03-07-setup-process.md
       Content focuses only on Docker setup steps
```

**Example 2: General summary**
```
User: "record this chat to kb"

Agent: Saves to domain/development/layer/backend/concern/api/2025-03-07-session.md
       Content summarizes the entire discussion: API design decisions,
       authentication approach, error handling patterns, etc.
```

**Example 3: With related notes**
```
Existing: domain/development/backend/auth/jwt-setup.md
New:     domain/development/backend/auth/2025-03-07-jwt-patterns.md

Links: New note includes "Related Notes" section linking to jwt-setup.md
```

## Important Reminders

- **Never push without approval** - Always show the draft first
- **Explore before suggesting** - Understand existing structure
- **Match existing patterns** - Follow the user's conventions
- **Link related content** - Build connections between notes
- **Be flexible** - Let the user adjust the path if needed
