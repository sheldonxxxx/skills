# Git Knowledge Base Skill

A unified skill for managing a personal knowledge base stored in Git. Designed for collaborative use between humans and AI agents.

## Overview

This skill provides tools to:
- **Query** your knowledge base (tree navigation, search, read)
- **Capture** new knowledge (create, edit, commit)
- **Maintain** auto-generated indexes via CI

## Philosophy

- **Local-first**: Clone locally, work fast, push to sync
- **Self-documenting**: README.md at every level
- **Git-powered**: Full version control, works offline
- **Descriptive naming**: Long, clear names over abbreviations
- **Collaborative**: Humans mainly read, AI writes (with approval)

## Installation

1. Copy this skill to your skills directory
2. Set up environment variables (see below)
3. Add CI workflow to your KB repository

## Setup

### Environment Variables

Add to your shell configuration (`~/.bashrc`, `~/.zshrc`, or `~/.bash_profile`):

```bash
export GIT_KB_PATH="$HOME/knowledge-base"
export GIT_KB_REPO="git@github.com:yourusername/your-kb.git"
```

Then reload: `source ~/.bashrc`

### CI Setup

Copy the CI workflow to your KB repository:

```bash
mkdir -p your-kb/.github/workflows
mkdir -p your-kb/.github/scripts
cp .github/workflows/readme-indexer.yml your-kb/.github/workflows/
cp .github/scripts/update_readmes.py your-kb/.github/scripts/
```

Push to your repo and enable GitHub Actions.

## Usage

### AI Query Flow

When user asks "What do I know about X?":

```bash
./scripts/git_kb.sh tree concepts/ --depth 2
./scripts/git_kb.sh search "X"
./scripts/git_kb.sh read concepts/X/some-file.md
```

### AI Capture Flow

When user says "Record to KB":

1. AI writes file directly using file tools to `$GIT_KB_PATH/...`
2. AI shows preview to user
3. User approves
4. AI commits: `./scripts/git_kb.sh commit "message"`

## File Structure

```
git-kb/
├── SKILL.md                    # Skill documentation
├── README.md                   # This file
├── scripts/
│   └── git_kb.sh              # Helper script
└── .github/
    ├── workflows/
    │   └── readme-indexer.yml  # CI workflow (for KB repos)
    └── scripts/
        └── update_readmes.py   # README generator (for KB repos)
```

## Commands

| Command | Description |
|---------|-------------|
| `tree [path]` | Show folder structure with descriptions |
| `read <path>` | Read file content |
| `search <query>` | Search file names and content |
| `tags` | List all tags used |
| `status` | Show current KB state |
| `commit [message]` | Commit and push changes |
| `sync` | Pull then push |

## Best Practices

### File Naming

- Use descriptive names: `jwt-implementation-patterns.md`
- Use kebab-case (hyphens)
- Include dates if relevant: `2025-03-15-decision.md`

### Frontmatter

```yaml
---
title: "Descriptive Title"
created: 2025-03-15
updated: 2025-03-15
type: concept
tags: [tag1, tag2]
status: active
---
```

### Folder Structure

Keep it flexible, but consistent:

```
kb/
├── README.md              # Root index (auto-generated)
├── concepts/              # Knowledge domains
│   ├── authentication/
│   │   ├── README.md      # Auto-generated
│   │   └── jwt-patterns.md
│   └── databases/
├── decisions/             # Architecture Decision Records
└── snippets/              # Code snippets
```

## License

MIT
