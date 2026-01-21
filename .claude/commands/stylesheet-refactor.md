# Stylesheet Refactor - VKCSS Optimization Tool

Interactive tool for refactoring Apple's VKCSS (Vector Kit CSS) stylesheets with compilation validation and knowledge learning.

**Usage**: `/stylesheet-refactor [file-path|selector-pattern]`

## What This Does

Helps simplify and optimize VKCSS stylesheets in `~/git/CartoStylesheet/` by:
- Finding duplicate properties across selectors
- Simplifying client state inheritance (Light/Dark variants)
- Consolidating similar selectors
- Validating changes through compilation
- Learning VKCSS patterns and edge cases over time

Maintains a knowledge base at `.claude/vkcss-knowledge.md` that grows with each refactoring session.

## How It Works

### Step 1: Load Knowledge Base

Check for existing VKCSS knowledge:
```bash
# Load if exists, create if not
if [ -f ~/.claude/vkcss-knowledge.md ]; then
  cat ~/.claude/vkcss-knowledge.md
fi
```

### Step 2: Determine Scope

Ask what to refactor:
```
What would you like to refactor?

1. Specific file (e.g., Roads.vkcss)
2. Specific selector (e.g., label[feature-type=Park])
3. Entire directory
4. Search for pattern across all files

Your choice:
```

### Step 3: Analyze VKCSS

Parse the target file(s):
- Extract selectors and properties
- Identify client states (Base, Light, Dark, LightExplore, etc.)
- Map inheritance chains
- Detect duplication
- Check against known patterns

Present findings:
```
📊 ANALYSIS: Roads.vkcss

Duplication:
  • 'fill-color: #FF0000' in 12 selectors
  • Light/Dark/LightExplore share 85% properties

Simplification:
  • 3 selectors differ only in zoom (can merge)
  • Selector with 5 conditions (high complexity)

Issues:
  ⚠️ Dark missing 'fill-color' but DarkExplore defines it
```

### Step 4: Interactive Refactoring

For each opportunity:
```
Opportunity #1: Consolidate duplicate fill-color

Current:
  label[feature-type=Park] { fill-color: #FF0000; }
  label[feature-type=Forest] { fill-color: #FF0000; }
  label[feature-type=Garden] { fill-color: #FF0000; }

Proposed:
  label[feature-type=Park],
  label[feature-type=Forest],
  label[feature-type=Garden] {
    fill-color: #FF0000;
  }

Apply? [Yes / No / Modify / Tell me more]
```

### Step 5: Validate Through Compilation

After changes:
```bash
# Run compilation
~/KahloStudio/Scripts/compile-stylesheet.sh
```

If compilation fails:
```
❌ Compilation Error

Error: Unknown property 'fill-color-opacity'
Line: 247

This is a new edge case. What did we learn?
[Document learning / Skip]
```

### Step 6: Capture New Knowledge

After successful refactoring:
```
✅ Refactoring validated!

Document any new VKCSS patterns discovered?

Example learnings:
• "Dark state requires fill-color if DarkExplore overrides it"
• "Selectors with >4 conditions cause warnings"

Your learning: [Type or skip]
```

If provided, add to `.claude/vkcss-knowledge.md`:
```markdown
### Rule: Client State Inheritance
- If child overrides property, parent must define it
- Discovered: 2026-01-19 during Roads.vkcss refactoring
```

### Step 7: Summary

```
📋 REFACTORING SUMMARY

File: Roads.vkcss
Changes: 5 consolidations, 2 simplifications
Lines: +12, -34 (net: -22)
Compilation: ✅ Success
Learnings: 2 patterns documented

Git Status:
  M Source/Roads.vkcss

Next Steps:
1. Review: git diff Source/Roads.vkcss
2. Test on device
3. Commit: /commit "Refactor Roads.vkcss"
4. Continue: /stylesheet-refactor [next-file]

[Continue / Review knowledge base / Done]
```

## VKCSS Concepts

**Client States:**
- Base → Light → LightExplore, LightDriving, LightTransit
- Base → Dark → DarkExplore, DarkDriving, DarkTransit
- Children inherit parent properties unless overridden

**Common Patterns:**
- Zoom ranges: `[zoom>=14][zoom<=18]`
- Feature types: `[feature-type=Park]`
- Multiple selectors: `label[type=A], label[type=B]`

**Edge Cases:**
- Parent must define if child overrides
- Dark mode requires explicit color definitions
- Selectors with >4 conditions trigger warnings

## Examples

```bash
# Refactor specific file
/stylesheet-refactor LandCover.vkcss

# Optimize client states
/stylesheet-refactor Roads.vkcss --goal optimize-compilation

# Fix all inheritance breaks
/stylesheet-refactor --scope all
```

## Safety Features

- Always validates through compilation
- Shows diff before applying
- Can revert on failure
- Backs up knowledge base
- Tracks git status

## Success Criteria

Successful refactoring:
- ✅ Reduces duplication or complexity
- ✅ Passes compilation
- ✅ Preserves visual behavior
- ✅ Documents new learnings
- ✅ Provides clear git diff

---

**Execute VKCSS refactoring with knowledge tracking now.**
