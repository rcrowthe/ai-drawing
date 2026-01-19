# Page - Save Conversation to Disk Before Compaction

Save your entire conversation history to disk files before running `/compact` to free up context memory. Like OS memory paging - store everything safely before clearing working memory.

**Usage**: `/page [filename_prefix] [output_directory]`

## What This Does

This command saves your complete Claude Code conversation to markdown files on disk, so you can safely run `/compact` afterward to free up context memory without losing any information.

**Two files are created:**
1. **Full history** (`{prefix}-{timestamp}-full.md`) - Complete conversation with all details
2. **Compact summary** (`{prefix}-{timestamp}-compact.md`) - Executive summary for quick reference

## Why You Need This

During long development sessions, Claude's context fills up. Running `/compact` frees memory but loses conversation history. Use `/page` first to save everything, then `/compact` to get fresh context.

**Workflow:**
1. Run `/page` → Saves full conversation to disk
2. Run `/compact` → Frees up Claude's context memory
3. Result: Fresh context + complete history preserved

## Arguments

- `filename_prefix` (optional): Custom name for output files (default: "session-dump")
- `output_directory` (optional): Where to save files (default: current directory)

## How It Works

### Step 1: Extract Conversation History

**Use the extraction script** from agent-guides repository:

```bash
# Run session extraction
python3 scripts/session_extraction.py
```

This script:
- Finds Claude Code's storage directory (`~/.claude/projects/`)
- Locates the current session file
- Extracts all messages with timestamps
- Preserves tool usage and outputs

### Step 2: Generate Full History File

Create a comprehensive markdown file with:

**Content Structure:**
```markdown
# Session History - {timestamp}

## Quick Summary (For Fast Reference)

### What Was Accomplished
{2-3 sentence summary}

### Key Changes
- File1.swift: Added feature X
- File2.swift: Fixed bug Y
- Created: NewFile.swift

### Important Discoveries
- Finding 1
- Finding 2

---

## Full Conversation

### Message 1 - User ({time})
{message content}

**Context:**
- Files read: [list]
- Commands run: [list]

### Message 2 - Assistant ({time})
{message content}

**Actions Taken:**
- Used Read tool on: file.swift
- Used Bash: `git status`
- Modified: file.swift (lines 10-20)

{Continue for all messages...}

## Files Accessed
1. file1.swift - Read 3x, Modified 1x
2. file2.swift - Created
3. config.json - Modified

## Web Resources
1. [Title](URL) - Retrieved {date}

## Commands Executed
1. `git status` - Success
2. `npm run build` - Failed (error details)
```

### Step 3: Generate Compact Summary

Create an executive summary for quick loading:

```markdown
# Session Summary - {timestamp}

## Executive Summary
{2-3 sentences on what was accomplished}

## Key Decisions
- Decision 1: Why and outcome
- Decision 2: Context and result

## Code Changes
- Feature A: What was added
- Bug Fix B: What was fixed

## Important Context for Next Session
- Uses framework X with pattern Y
- Key files: main.swift, config.json
- Build command: `swift build`

## Quick Links
- [Full History]({full-history-file})
- [Key File 1](file:///path)
- [Documentation](url)
```

### Step 4: Save Files

Save both files with timestamps:
- Format: `YYYY-MM-DD_HHMMSS`
- Location: Current directory (or specified directory)
- Confirm: Show file paths and sizes

### Step 5: Final Instructions

Display:
```
✅ Conversation saved successfully!

Files created:
- session-dump-2026-01-19_143530-full.md (2.4 MB)
- session-dump-2026-01-19_143530-compact.md (15 KB)

📋 NEXT STEP: Run /compact to free up context memory

The /compact command will clear Claude's working memory.
Your conversation history is safely saved in the files above.
```

## Examples

```bash
# Basic usage
/page
# Creates: session-dump-{timestamp}-full.md and -compact.md

# Custom prefix
/page feature-work
# Creates: feature-work-{timestamp}-full.md and -compact.md

# Custom directory
/page bug-fixes ./docs/sessions/
# Creates files in ./docs/sessions/

# After saving, free up memory:
/compact
```

## What Gets Saved

**Included:**
- All user messages and assistant responses
- All tool usage (Read, Edit, Write, Bash, etc.)
- Tool outputs and results
- File modifications and creations
- Command executions and outputs
- Web searches and results
- Timestamps for everything

**Citations format:**
- Local files: `file:///absolute/path#L10-L20`
- Web pages: `[Title](URL)` with excerpts
- Commands: `` `command` `` with exit codes

## File Formats

**Full History File:**
- Complete conversation transcript
- All tool uses and outputs
- Source attributions and citations
- Typically large (1-5 MB for long sessions)

**Compact Summary File:**
- Executive summary only
- Key decisions and changes
- Quick reference links
- Small size (~10-50 KB)
- Optimized for loading into future context

## When To Use This

**Use `/page` when:**
- Context memory is getting full
- Before major context-clearing operations
- End of long development sessions
- Creating documentation of work done
- Preserving important conversations

**Then follow with:**
- `/compact` to free up memory
- Continue working with fresh context

## Success Criteria

A successful page operation:
- ✅ Creates both full and compact files
- ✅ Includes all messages and tool usage
- ✅ Properly cites all sources
- ✅ Generates accurate timestamps
- ✅ Creates valid file:// and http:// links
- ✅ Confirms file paths and sizes
- ✅ Reminds user to run `/compact` next

## Related Commands

- `/compact` - Free up context memory (run AFTER `/page`)
- `/commit` - Commit code changes before paging
- `/search-prompts` - Search through saved session histories

---

**Execute the conversation save process now, then remind user to run /compact.**
