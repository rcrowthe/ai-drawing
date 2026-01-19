# Teach Skill - Guide Skill Creation Through Questions

Help create high-quality Claude Code skills by asking strategic questions that uncover requirements, edge cases, and implementation details.

**Usage**: `/teach-skill`

## What This Does

Guides you through creating a new skill via a systematic Q&A process:
1. Asks about the skill's purpose and name
2. Explores core functionality and workflow
3. Identifies edge cases and errors
4. Clarifies user experience
5. Documents dependencies
6. Generates complete skill file

Result: A well-defined, ready-to-use skill file.

## How It Works

### Phase 1: Basic Definition (Questions 1-2)

**Question 1: Name and Purpose**
```
What would you like to name your skill?

Provide:
- Skill name (kebab-case, e.g., "code-reviewer")
- One-sentence description
- Main problem it solves
```

Analyze the name for clarity, consistency, conflicts.

**Question 2: Core Functionality**
```
What are the key steps this skill should perform?

List 3-7 main actions, for example:
1. Analyze code
2. Generate report
3. Suggest fixes
```

### Phase 2: Inputs and Outputs (Questions 3-4)

**Question 3: Input Requirements**
```
What inputs does your skill need?

Consider:
- Required arguments (must be provided)
- Optional arguments (have defaults)
- File paths, URLs, or data
- Configuration options
```

**Question 4: Output Format**
```
What should the skill produce?

Examples:
- Formatted report (markdown, JSON)
- Modified files
- Summary message
- Generated code
```

### Phase 3: Edge Cases (Questions 5-6)

**Question 5: Edge Cases**
```
What unusual situations should the skill handle?

Think about:
- Empty or missing inputs
- Very large datasets
- Invalid data
- Network failures
- Permission issues
```

**Question 6: Failure Scenarios**
```
How should it behave when things go wrong?

For each failure:
- Fail gracefully or abort?
- What error messages?
- Can it recover automatically?
- Ask user for help?
```

### Phase 4: User Experience (Questions 7-8)

**Question 7: User Interaction**
```
Should the skill interact during execution?

Consider:
- Progress updates (long operations)
- Confirmations (destructive actions)
- Multiple choice questions
- Pause/resume ability
```

**Question 8: Examples**
```
Provide 2-3 example use cases:

For each:
- Command invocation
- Context/situation
- Expected output
```

### Phase 5: Dependencies (Questions 9-10)

**Question 9: Prerequisites**
```
What does the skill depend on?

Check for:
- Required tools (git, npm, etc.)
- File structure needs
- Environment variables
- External services
- Specific file formats
```

**Question 10: Performance**
```
Any performance constraints?

Think about:
- Maximum file sizes
- Timeout limits
- Memory usage
- API rate limits
- Parallel operations
```

### Phase 6: Validation and Generation

**Summarize and Confirm:**
```
Let me summarize your skill:

Name: skill-name
Purpose: one-sentence description

Core Steps:
- Step 1
- Step 2

Inputs: [list]
Outputs: [list]
Edge Cases: [list]
Dependencies: [list]

Is this accurate? Modify anything? [Yes/No/Edit]
```

**Generate Skill File:**
```markdown
# Skill Name - Brief Description

[Description]

**Usage**: `/skill-name [arguments]`

## What This Does

[Clear explanation]

## How It Works

### Step 1: [Phase]
[Instructions]

### Step 2: [Phase]
[Instructions]

## Edge Cases

[List and handling]

## Examples

[Usage examples]

## Success Criteria

[What success looks like]
```

### Phase 7: Save and Complete

```
✅ Skill created: .claude/commands/skill-name.md

Next steps:
1. Review the skill above
2. Test: /skill-name [args]
3. Refine: /crud update skill-name "changes"

Would you like to test it now? [Yes/No]
```

## Adaptive Questioning

Adjust follow-ups based on answers:

**If skill involves files:**
- Ask about formats, sizes, backups

**If skill uses APIs:**
- Ask about auth, rate limits, errors

**If skill generates code:**
- Ask about language, style, testing

**If skill is interactive:**
- Ask about UI/UX, accessibility

**If skill modifies files:**
- Ask about safety, undo, backups

## Clarification Strategy

When answers are unclear:
```
Thanks! A few clarifications:

1. You mentioned [X]. Did you mean [A] or [B]?
2. For [Y], could you provide an example?
3. I'm unclear about [Z]. Could you elaborate?
```

## Example Session

```
Claude: What would you like to name your skill?

User: "db-schema-diff" - compares database schemas and generates migration scripts

Claude: Great! What are the key steps?

User:
1. Connect to source and target databases
2. Extract schema definitions
3. Compare tables, columns, indexes
4. Generate migration SQL
5. Optionally apply migrations

Claude: What inputs does it need?

User: Database connection strings, optional auto-apply flag

[Session continues through all questions...]

Claude: Here's your complete skill definition...
```

## Success Criteria

A successful teach session creates:
- ✅ Clear skill name and purpose
- ✅ Comprehensive functionality list
- ✅ All inputs/outputs specified
- ✅ Edge cases identified
- ✅ Error handling addressed
- ✅ User experience considered
- ✅ Dependencies documented
- ✅ Multiple examples provided
- ✅ Ready-to-use skill file

---

**Execute guided skill creation now.**
