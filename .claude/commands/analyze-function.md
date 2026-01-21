# Analyze Function - Detailed Line-by-Line Breakdown

Analyze the specified function from a given file with comprehensive technical explanation.

**Usage**: `/analyze-function filename:function_name` or `/analyze-function filename function_name`

---

## 🎯 Execution Directive

When this command is invoked, **immediately begin the analysis**. Do NOT ask for confirmation. Do NOT suggest alternatives. **Execute the analysis directly.**

---

## Arguments

- `filename`: The file containing the function to analyze
- `function_name`: The name of the function to analyze

## Analysis Framework

For the function `$ARGUMENTS`, execute this complete analysis:

### 1. Read and Locate

**Tool to use**: Read tool

- Read the specified file
- Locate the target function
- Extract the complete function code
- Note the line numbers

### 2. Provide Context

- Explain the function's role in the broader system
- Identify which class/module it belongs to
- Describe when and why it gets called
- Show calling patterns (who calls this function)

### 3. Line-by-Line Technical Analysis

For each significant line, explain:
- **What**: What the code does technically
- **Why**: Why it's implemented this way
- **Performance**: Performance implications or optimizations
- **Edge Cases**: Potential issues or corner cases
- **Context**: How it connects to the broader codebase

### 4. Highlight Critical Details

Point out:
- Implementation details easily missed on casual reading
- Subtle bugs or potential issues
- Performance bottlenecks
- Security considerations
- Memory management patterns

### 5. Design Patterns & Optimization

- Identify design patterns used
- Explain optimization techniques
- Discuss trade-offs made
- Note architectural decisions

### 6. Potential Improvements

- Identify areas of concern
- Suggest improvements (if any)
- Note technical debt
- Highlight best practices followed or violated

## Output Format

Structure the analysis as follows:

```
# Function Analysis: {function_name} in {filename}

## Context & Purpose
{High-level explanation of what this function does and why it exists}

## Line-by-Line Analysis

**Line {N}: {Code snippet}**
- **What**: {Technical description}
- **Why**: {Rationale}
- **Critical Detail**: {Important insight}
- **Performance**: {Performance implications}

{Repeat for each significant line}

## Critical Details You Might Miss

1. {Detail 1}
2. {Detail 2}
3. {Detail 3}

## Design Patterns & Optimizations

{List patterns and optimizations}

## Potential Issues or Improvements

{List concerns or suggestions}

## Overall Assessment

{Summary of the function's quality and effectiveness}
```

## Example Analysis Structure

See the example in the original command for reference on depth and style.

## Success Criteria

A complete analysis should:
- ✅ Explain every significant line of code
- ✅ Provide context beyond just "what" the code does
- ✅ Identify non-obvious implementation details
- ✅ Discuss performance and architectural implications
- ✅ Point out potential issues or areas of concern
- ✅ Be accessible to someone unfamiliar with this codebase

---

**Execute the function analysis now.**
