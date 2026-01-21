# Teach Skill - Interactive Skill Creation Through Sequential Questions

**CRITICAL INSTRUCTION**: This skill MUST use the AskUserQuestion tool for EVERY SINGLE QUESTION. Each question must provide 2-4 specific option choices. NEVER ask open-ended text questions. ONE question at a time.

**Usage**: `/teach-skill [optional-skill-name]`

## Execution Protocol

### MANDATORY BEHAVIOR:

1. **USE AskUserQuestion TOOL WITH 2-4 OPTIONS**
2. **STOP AND WAIT FOR USER SELECTION**
3. **PROCESS ANSWER**
4. **USE AskUserQuestion TOOL FOR NEXT QUESTION**
5. **REPEAT UNTIL ALL 10 QUESTIONS ANSWERED**

**DO NOT:**
- ❌ Ask multiple questions at once
- ❌ Ask open-ended text questions without options
- ❌ Use plain text questions instead of AskUserQuestion tool
- ❌ Batch questions into groups
- ❌ Explain what questions are coming next

**DO:**
- ✅ Use AskUserQuestion tool for every question
- ✅ Provide 2-4 concrete options per question
- ✅ Wait for user selection
- ✅ Acknowledge answer briefly
- ✅ Track state internally

---

## Question 1: Skill Name

**USE AskUserQuestion TOOL - Generate 3-4 relevant skill name options based on user's initial request or context.**

Example structure:
- Option A: Generic approach name
- Option B: Domain-specific name
- Option C: Action-focused name
- Option D: Tool-focused name

User can always select "Other" to provide custom name.

After answer: Store `skill_name`

---

## Question 2: Primary Purpose

**USE AskUserQuestion TOOL - Present 3-4 main purposes this skill could serve.**

Example options:
- "Design and implement new features with HIG compliance"
- "Review and critique existing code for design violations"
- "Generate UI components following design system patterns"
- "Audit codebase for accessibility and UX issues"

After answer: Store `primary_purpose`

---

## Question 3: Execution Mode

**USE AskUserQuestion TOOL - How should the skill operate?**

Options must include:
- "Proactive - Automatically implement fixes and improvements"
- "Interactive - Show plan first, ask permission before implementing"
- "Advisory - Only provide recommendations, never modify code"
- "Hybrid - Auto-fix minor issues, ask permission for major changes"

After answer: Store `execution_mode`

---

## Question 4: Input Type

**USE AskUserQuestion TOOL - What inputs should trigger this skill?**

Options must include:
- "Feature description (text describing what to build)"
- "File path (review existing code)"
- "Both feature descriptions and file paths"
- "Auto-scan codebase (no input needed)"

After answer: Store `input_type`

---

## Question 5: Scope of Changes

**USE AskUserQuestion TOOL - How extensive should modifications be?**

Options must include:
- "Single file only"
- "Multiple related files (2-5 files)"
- "Entire feature area (5-15 files)"
- "Project-wide refactoring (15+ files)"

After answer: Store `change_scope`

---

## Question 6: Design Authority Source

**USE AskUserQuestion TOOL - What should guide design decisions?**

Options must include:
- "Local HIG documentation (project-specific)"
- "Apple Human Interface Guidelines (official docs)"
- "Existing codebase patterns (learn from project)"
- "All of the above (combined approach)"

After answer: Store `design_authority`

---

## Question 7: Error Handling Strategy

**USE AskUserQuestion TOOL - How should failures be handled?**

Options must include:
- "Auto-rollback all changes on any failure"
- "Partial commit - save what succeeded, report what failed"
- "Retry automatically with simpler approach"
- "Stop and ask user for guidance"

After answer: Store `error_strategy`

---

## Question 8: Git Workflow

**USE AskUserQuestion TOOL - How should version control be handled?**

Options must include:
- "Always create new feature branch before changes"
- "Auto-stash, work on current branch, pop stash"
- "Require clean working directory (abort if uncommitted changes)"
- "No git operations (manual version control)"

After answer: Store `git_workflow`

---

## Question 9: Build Validation

**USE AskUserQuestion TOOL - Should the skill validate builds?**

Options must include:
- "Always validate build succeeds after implementation"
- "Only validate for major changes (5+ files)"
- "Never auto-validate (user will test manually)"
- "Validate syntax only (no full build)"

After answer: Store `build_validation`

---

## Question 10: Output Detail Level

**USE AskUserQuestion TOOL - How much detail should be shown?**

Options must include:
- "Verbose - Show every file read, every decision, every change"
- "Standard - Show major phases and key decisions"
- "Minimal - Only show final summary and results"
- "Debug - Include HIG citations and rationale for every decision"

After answer: Store `output_detail`

---

## Summary and Confirmation

**AFTER ALL 10 QUESTIONS:**

Present summary in clear text format:

```
Skill Configuration Summary:

1. Name: [skill_name]
2. Purpose: [primary_purpose]
3. Execution: [execution_mode]
4. Input: [input_type]
5. Scope: [change_scope]
6. Design Authority: [design_authority]
7. Error Handling: [error_strategy]
8. Git: [git_workflow]
9. Build Validation: [build_validation]
10. Output: [output_detail]
```

**THEN USE AskUserQuestion TOOL:**

Options:
- "Yes - Generate the skill file now"
- "Edit - Modify one or more answers"
- "Restart - Start over from beginning"
- "Cancel - Abort skill creation"

---

## Generation Phase

**ONLY AFTER USER SELECTS "YES":**

Generate skill markdown file with this structure:

```markdown
# [Skill Name] - [Brief Description]

You are the [role based on purpose] for KahloStudio (or relevant project).

**Usage**: `/[skill-name] [arguments]`

## Core Identity

[Description of persona, values, priorities based on answers]

## What This Does

[Clear explanation based on primary_purpose]

## Execution Mode

[Description based on execution_mode]

## How It Works

### Step 1: Analyze Input
[Based on input_type]

### Step 2: Check Design Authority
[Based on design_authority - how to load/check HIG docs]

### Step 3: Plan Implementation
[Based on change_scope]

### Step 4: Execute Changes
[Based on execution_mode and change_scope]

### Step 5: Handle Errors
[Based on error_strategy]

### Step 6: Manage Version Control
[Based on git_workflow]

### Step 7: Validate Results
[Based on build_validation]

## Edge Cases

[Generate based on all answers - what can go wrong and how to handle]

## Examples

### Example 1: [Common use case based on purpose]
```
/[skill-name] "add export button"
```
[Expected behavior based on execution_mode]

### Example 2: [Review scenario]
```
/[skill-name] --review KahloStudio/MaterialEditor.swift
```
[Expected output based on output_detail]

### Example 3: [Complex scenario]
```
/[skill-name] "implement dark mode toggle"
```
[Expected workflow based on change_scope]

## Prerequisites

[Based on design_authority and build_validation]

## Success Criteria

- ✅ [Criterion based on primary_purpose]
- ✅ [Criterion based on design_authority]
- ✅ [Criterion based on build_validation]
- ✅ [Criterion based on execution_mode]
```

Save to: `.claude/commands/[skill-name].md`

Report:
```
✅ Skill created: .claude/commands/[skill-name].md

Test it now: /[skill-name] [example-args]
```

---

## State Tracking (Internal)

Track these values across conversation turns:

```
question_number: 1-10
skill_name: ""
primary_purpose: ""
execution_mode: ""
input_type: ""
change_scope: ""
design_authority: ""
error_strategy: ""
git_workflow: ""
build_validation: ""
output_detail: ""
```

**CRITICAL**: Every question MUST use AskUserQuestion tool with 2-4 concrete options. No exceptions.
