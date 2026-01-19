# Git Flow - Automated Git Workflow Operations

Automate common git workflows: create branches, make PRs, merge features, and sync with upstream.

**Usage**: `/git-flow <operation> [arguments]`

## What This Does

Automates git operations that normally require multiple commands:
- **create-feature**: Create and push new feature branch from main
- **create-pr**: Create pull request with auto-generated description
- **merge-feature**: Merge feature branch back to main with cleanup
- **sync**: Rebase current branch on latest upstream
- **status**: Comprehensive status showing branch, commits, changes

## Operations

### create-feature

Create a new feature branch from main/master.

**Usage**: `/git-flow create-feature <branch-name> [base-branch]`

**What it does:**
1. Fetches latest from origin
2. Updates base branch (main/master)
3. Creates new branch from base
4. Pushes to origin with tracking

**Example:**
```bash
/git-flow create-feature user-auth
/git-flow create-feature user-auth develop
```

**Output:**
```
✅ Feature branch created: user-auth

Branch: user-auth
Base: main (latest from origin)
Tracking: origin/user-auth

💡 Next: Make your changes and commit them
```

### create-pr

Create a pull request from current branch.

**Usage**: `/git-flow create-pr [title] [description]`

**What it does:**
1. Ensures branch is pushed to remote
2. Analyzes commits since branching
3. Generates PR title and description (if not provided)
4. Creates PR using `gh pr create`
5. Returns PR URL

**Example:**
```bash
/git-flow create-pr "Add user authentication" "Implements OAuth2 and JWT"
/git-flow create-pr  # Interactive - analyzes commits and suggests
```

**Auto-generated PR format:**
```
## Summary
- Bullet point 1
- Bullet point 2

## Test Plan
- [ ] Test case 1
- [ ] Test case 2

🤖 Generated with Claude Code
```

### merge-feature

Merge feature branch to main with cleanup.

**Usage**: `/git-flow merge-feature [branch-name]`

**What it does:**
1. Verifies working directory is clean
2. Checks out and updates main
3. Merges feature branch (--no-ff)
4. Pushes to origin
5. Deletes local and remote feature branch

**Example:**
```bash
/git-flow merge-feature user-auth
/git-flow merge-feature  # Uses current branch
```

**Safety checks:**
- Confirms uncommitted changes
- Warns before deleting branches
- Verifies merge success before cleanup

### sync

Sync current branch with upstream.

**Usage**: `/git-flow sync [base-branch]`

**What it does:**
1. Fetches latest from origin
2. Rebases current branch on base (main/master)
3. Handles conflicts if they occur
4. Force-pushes if needed (with warning)

**Example:**
```bash
/git-flow sync main
/git-flow sync  # Auto-detects base branch
```

**Conflict handling:**
```
⚠️ MERGE CONFLICTS

Conflicting files:
  - KahloStudio/BrowserPanel.swift
  - KahloStudio/GitPanel.swift

Resolve conflicts, then:
  git add <resolved-files>
  git rebase --continue

Or abort: git rebase --abort
```

### status

Show comprehensive git status.

**Usage**: `/git-flow status`

**What it shows:**
```
📊 GIT STATUS

Current branch: feature/user-auth
Tracking: origin/feature/user-auth
Status: 2 commits ahead, 0 behind

📝 Uncommitted Changes (3 files):
  M  KahloStudio/AuthPanel.swift
  M  KahloStudio/LoginView.swift
  ?? KahloStudio/TokenManager.swift

📜 Recent Commits:
  abc123 Add JWT token validation
  def456 Implement OAuth2 flow

💡 Suggested Actions:
  1. Commit changes: /commit
  2. Create PR: /git-flow create-pr
```

## Complete Workflow Example

```bash
# Start new feature
/git-flow create-feature user-auth

# ... make changes and commit ...
/commit "Add OAuth2 authentication"

# Sync with latest main
/git-flow sync main

# Create pull request
/git-flow create-pr "Implement user authentication"

# After PR approval, merge
/git-flow merge-feature user-auth
```

## Safety Features

**Pre-flight checks:**
- Clean working directory before branch operations
- Upstream tracking exists before pushing
- Uncommitted changes warning before merging
- Confirmation before destructive operations

**Error handling:**
- Merge conflicts: Clear resolution steps
- Missing upstream: Offer to set tracking
- Uncommitted changes: Suggest stash or commit
- Missing gh CLI: Installation instructions

**User confirmations:**
Ask before:
- Force pushing to remote
- Deleting branches
- Merging without clean status
- Overwriting local changes

## Requirements

- Git 2.23+
- GitHub CLI (`gh`) for PR operations (optional)
- Clean working directory for branch operations
- Proper git config (user.name, user.email)

## Common Issues

**"No upstream branch"**
```bash
# Set upstream manually:
git push -u origin <branch-name>
```

**"Merge conflicts"**
```bash
# Resolve conflicts, then:
git add <files>
git rebase --continue
# Or abort: git rebase --abort
```

**"Cannot force push to main"**
```
Branch protection prevents force push to main.
This is a safety feature - never force push to main!
```

## Success Criteria

Each operation should:
- ✅ Complete without errors
- ✅ Leave repository in valid state
- ✅ Provide clear next steps
- ✅ Handle conflicts gracefully
- ✅ Confirm destructive actions

---

**Execute the requested git flow operation now.**
