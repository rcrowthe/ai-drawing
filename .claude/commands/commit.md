# Commit - Smart Git Commit Workflow

Review changes, stage files, and create well-crafted commits with guidance throughout the process.

**Usage**: `/commit [message]`

## What This Does

Guides you through creating a git commit by:
1. Showing what files have changed
2. Letting you choose what to include
3. Helping write a clear commit message
4. Creating the commit with proper formatting
5. Adding `Co-Authored-By: Claude` attribution

## How It Works

### Step 1: Check What Changed

Run git commands to see the current state:

```bash
git status --porcelain
git diff --stat
```

Show organized summary:
```
📋 CHANGES SUMMARY

Modified (5 files):
  M  KahloStudio/BrowserPanel.swift     (+45, -12)
  M  KahloStudio/GitPanel.swift         (+23, -8)

New (2 files):
  ?? KahloStudio/TokensPanel.swift      (234 lines)
  ?? Scripts/analyze-tokens.py          (89 lines)

Deleted (1 file):
  D  OLD-README.md

Total: 8 files changed (+391, -20)
```

### Step 2: Select Files to Commit

Ask which files to include:

```
📦 SELECT FILES

What would you like to commit?

[1] All files (8 total)
[2] Select individually
[3] Show diffs first

Your choice:
```

If user chooses "Select individually", show checklist:
```
[x] KahloStudio/BrowserPanel.swift
[x] KahloStudio/GitPanel.swift
[ ] KahloStudio/TokensPanel.swift (skip this one)
[x] Scripts/analyze-tokens.py
...

[A]ll [N]one [C]ontinue [Q]uit
```

### Step 3: Write Commit Message

**If user provided message**, use it directly.

**If no message provided**, analyze changes and suggest:

```
💭 SUGGESTED COMMIT MESSAGE

Based on your changes:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Update git panel and browser panel with improved filtering

- Add TokensPanel for token search and management
- Update BrowserPanel with enhanced search
- Add analyze-tokens script for token analysis
- Remove obsolete OLD-README

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
[1] Use this message
[2] Edit this message
[3] Write custom message
```

### Step 4: Confirm and Commit

Show final preview:

```
📤 COMMIT PREVIEW

Message:
Update git panel and browser panel with improved filtering

- Add TokensPanel for token search and management
- Update BrowserPanel with enhanced search
- Add analyze-tokens script for token analysis
- Remove obsolete OLD-README

Files (7):
  M  KahloStudio/BrowserPanel.swift
  M  KahloStudio/GitPanel.swift
  A  KahloStudio/TokensPanel.swift
  A  Scripts/analyze-tokens.py
  D  OLD-README.md

Proceed? [Y]es [E]dit message [C]hange files [Q]uit
```

### Step 5: Execute Commit

Stage files and create commit:

```bash
# Stage selected files
git add KahloStudio/BrowserPanel.swift
git add KahloStudio/GitPanel.swift
...

# Create commit with proper formatting
git commit -m "$(cat <<'EOF'
Update git panel and browser panel with improved filtering

- Add TokensPanel for token search and management
- Update BrowserPanel with enhanced search
- Add analyze-tokens script for token analysis
- Remove obsolete OLD-README

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"

# Verify
git status
```

### Step 6: Show Results

```
✅ COMMIT SUCCESSFUL

Commit: abc123def
Date: 2026-01-19 14:30:22
Files: 7 changed (+391, -20)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 NEXT STEPS

• View commit: git show abc123def
• Push to remote: git push origin <branch>
• Amend if needed: git commit --amend

Working directory status: Clean ✨
```

## Message Guidelines

**Good commit messages:**
- Start with a clear summary (imperative mood: "Add" not "Added")
- Use bullet points for multiple changes
- Explain WHY, not just WHAT
- Keep first line under 72 characters

**Message format:**
```
Short summary of change

- Detailed point 1
- Detailed point 2
- Detailed point 3

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Safety Checks

**Before committing, verify:**
- No merge conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- No sensitive data (`.env`, credentials, API keys)
- No debug code (excessive `print` statements, TODOs added by mistake)
- Files are actually ready to commit

**If issues found:**
```
⚠️  WARNING

Found potential issues:
• file.swift contains TODO markers
• credentials.json may contain sensitive data

Proceed anyway? [Y/N]
```

## Examples

```bash
# Interactive mode (suggests message)
/commit

# With custom message
/commit "Fix bug in device viewer"

# With detailed message
/commit "Add workout routes feature

- Implement WorkoutRoutesPanel for GPX visualization
- Add database schema for route storage
- Integrate with map overlay system"
```

## Quick Mode

For simple, obvious changes, the command:
1. Shows changes
2. Suggests message
3. Asks for single confirmation
4. Commits immediately

For complex changes:
1. Interactive file selection
2. Detailed diff review
3. Multiple confirmations
4. Safety checks

## Related Commands

- `/git-flow create-pr` - Create pull request after committing
- `/page` - Save conversation before committing major work
- `git log` via Bash - Review commit history

## Success Criteria

A successful commit:
- ✅ Includes intended changes only
- ✅ Has clear, descriptive message
- ✅ Passes safety checks
- ✅ Properly staged and committed
- ✅ Includes Claude co-author attribution
- ✅ Leaves working directory in expected state

---

**Execute the smart commit workflow now.**
