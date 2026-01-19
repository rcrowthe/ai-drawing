# Cleanup - Remove Unused Code and Cruft

Find and remove backup files, unused code, dead scripts, and technical debt from your repository.

**Usage**: `/cleanup [--dry-run] [--scope=<all|swift|scripts|backups>]`

## What This Does

Identifies and removes:
- Backup files (.bak, .old, .backup, numbered backups)
- Unused Swift files (not in project, not referenced)
- Broken or unused scripts
- Commented-out code blocks
- Debug print statements
- Empty files

Then presents findings categorized by severity, letting you choose what to delete.

## Arguments

- `--dry-run`: Show what would be deleted without deleting
- `--scope`: Limit to specific areas:
  - `all` (default): Check everything
  - `swift`: Only Swift source files
  - `scripts`: Only Python/shell scripts
  - `backups`: Only backup and temp files

## How It Works

### Phase 1: Discover Cleanup Candidates

**Find backup files:**
```bash
find . -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*~"
find . -name "*.swift.bak" -o -name "*.py.backup"
```

**Find unused Swift files:**
- Check if file is in `project.pbxproj`
- Check if imported anywhere
- Look for deprecation markers in comments

**Find broken scripts:**
- Check for syntax errors
- Check for missing imports
- Check if executable but never called

**Find dead code:**
- Large commented-out blocks (>50 lines)
- Excessive debug prints (>10 per file)
- Unused functions (no references)

### Phase 2: Categorize Findings

```
🧹 CLEANUP ANALYSIS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY
Files analyzed: 156
Issues found: 47
Potential savings: 12,450 lines, 2.3 MB

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 SAFE TO DELETE (15 files)

Backup Files (8 files, 450 KB)
  • BrowserPanel.swift.bak
  • Panels.swift.bak2
  • generate-tokens.py.old
  [These are backup copies - safe to remove]

Broken Scripts (4 files)
  • generate-tokens.py - Import error: module 'yaml' not found
  • old-implementation.py - Syntax error line 45
  [These scripts don't work]

Empty Files (3 files)
  • Helpers.swift - 0 lines
  • utils.py - Only comments
  [No functional code]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 LIKELY UNUSED (18 files)

Unused Swift Files (8 files, 3,450 lines)
  • OldStyleParser.swift
    - Not in project.pbxproj
    - Contains "DEPRECATED" comment
    - Replaced by DefaultStyleLoader.swift
    Recommendation: DELETE

Unused Scripts (7 files)
  • tokenize-stylesheet.py
    - Not called anywhere
    - Duplicate of canonical_scripts/tokenize.py
    Recommendation: DELETE

Dead Code (890 lines across 3 files)
  • DatabaseService.swift:450-680
    - 230 lines commented out for 2 months
    - Comment: "Old query implementation"
    Recommendation: REMOVE (git has history)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 NEEDS REVIEW (14 items)

Potentially Slow Code (5 instances)
  • MaterialParser.swift:125
    - Synchronous file reads in loop (2,292 iterations)
    Recommendation: Use async/await or batch loading

Large Debug Output (3 files)
  • BrowserPanel.swift - 45 print statements
  Recommendation: Convert to proper logging
```

### Phase 3: Interactive Cleanup

```
🧹 CLEANUP ACTIONS

[1] Delete all backup files (8 files) ✓ SAFE
[2] Delete broken scripts (4 files) ✓ SAFE
[3] Delete unused Swift files (8 files) ⚠ REVIEW FIRST
[4] Remove commented code (890 lines) ⚠ CHECK VERSION CONTROL
[5] Delete unused scripts (7 files) ⚠ VERIFY NOT NEEDED
[6] Custom selection (choose specific files)
[7] Exit without changes

Enter choice(s) [1-7, or comma-separated]:
```

### Phase 4: Execute Cleanup

For selected items:

1. **Create backup** (optional):
```bash
timestamp=$(date +%Y%m%d_%H%M%S)
mkdir -p .cleanup-backup-$timestamp
cp [files-to-delete] .cleanup-backup-$timestamp/
```

2. **Delete files**:
```bash
rm BrowserPanel.swift.bak
git rm Scripts/old-script.py  # If tracked
```

3. **Show results**:
```
✅ CLEANUP COMPLETE

Deleted: 15 files
Removed: 4,340 lines
Saved: 2.8 MB

Backup: .cleanup-backup-20260119_143045/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔄 NEXT STEPS

1. Test build: Cmd+B in Xcode
2. Run tests: Verify functionality
3. Commit: git commit -m "Clean up unused code"
4. Remove backup: rm -rf .cleanup-backup-*

To restore if needed:
cp -r .cleanup-backup-20260119_143045/* .
```

## Safety Features

**Pre-deletion checks:**
- Check if file is tracked by git
- Check last modified date (skip if <48 hours old)
- Grep for references in codebase
- Check if imported or used

**Auto-exclude:**
- Files modified in last 48 hours
- `.git/` directory contents
- Project files (.xcodeproj, .xcworkspace)
- Dependencies (node_modules/, Pods/)
- Files with "WIP" or "IN PROGRESS" comments

**Backup strategy:**
- Always create .cleanup-backup-{timestamp}/
- Provide restore command in output
- Keep backup until user confirms deletion is permanent

## Examples

```bash
# Full analysis
/cleanup

# See what would be deleted
/cleanup --dry-run

# Only remove backup files
/cleanup --scope=backups

# Only check scripts
/cleanup --scope=scripts
```

## Detection Algorithms

**Unused function detection:**
- Extract all function definitions
- Search entire codebase for calls
- If zero references outside definition → likely unused

**Code complexity:**
- Lines > 200 → Function too long
- Nesting depth > 5 → Too deep
- Cyclomatic complexity > 15 → Too many branches

**Duplicate detection:**
- Calculate similarity between files
- If >90% similar → One might be duplicate

## When To Run

Run cleanup:
- **Weekly** during regular maintenance
- **Before major refactoring** to clear the deck
- **After feature completion** to remove experiments
- **Before code review** to clean up for reviewers
- **When confused** to remove distractions

## What To Keep vs. Remove

**DON'T delete:**
- Working code (even if not "perfect")
- Recent experiments (<1 week old)
- Documentation and explanatory comments
- Tests (even if seemingly redundant)
- Build scripts (might be needed later)

**DO delete:**
- Backup files (.bak, .old, numbered)
- Failed experiments (commented out >1 month)
- Duplicate implementations
- Excessive debug code
- Very old TODO markers (>6 months)

## Success Criteria

A successful cleanup:
- ✅ Removes cruft without breaking anything
- ✅ Creates backup before deleting
- ✅ Provides clear categorization
- ✅ Asks for confirmation on risky items
- ✅ Leaves repository in buildable state
- ✅ Documents what was deleted

---

**Execute repository cleanup now.**
