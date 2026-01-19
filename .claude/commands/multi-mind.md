# Multi-Mind - Collaborative Analysis Using Multiple AI Specialists

Create multiple independent AI specialist agents that research a topic from different perspectives, then synthesize their findings into comprehensive insights.

**Usage**: `/multi-mind <topic> [rounds=3]`

## What This Does

This command creates 4-6 specialized AI agents (using the Task tool) that independently research a topic from different angles. Each specialist:
- Has a unique domain expertise (technical, business, UX, security, etc.)
- Conducts independent research using WebSearch
- Analyzes the topic from their perspective
- Reviews other specialists' findings and provides their expert critique
- Evolves their analysis over multiple rounds

The result is a comprehensive, multi-faceted analysis that no single perspective could achieve.

## How It Works

### Round 1: Initial Research
1. **Determine specialists needed** based on the topic (e.g., for "API design": technical architect, security expert, developer experience specialist, performance analyst)
2. **Launch parallel specialists** using the Task tool - each agent runs independently with access to WebSearch, Read, and analysis tools
3. **Each specialist researches** their domain: finds documentation, case studies, best practices
4. **Collect initial findings** from all specialists

### Round 2: Cross-Pollination
1. **Share all Round 1 findings** with every specialist
2. **Each specialist reviews** others' work from their perspective
3. **Challenge assumptions**: Specialists identify blind spots or conflicts
4. **Build on insights**: Find intersections between different viewpoints
5. **Refine analysis**: Each specialist deepens their investigation based on what they learned

### Round 3+: Synthesis & Iteration
1. **Identify patterns** emerging across specialist perspectives
2. **Focus on gaps**: Direct specialists to explore under-analyzed areas
3. **Resolve conflicts**: When specialists disagree, investigate further
4. **Final synthesis**: Combine insights without losing distinct viewpoints

## Launching Specialists

Use the Task tool to create each specialist as an independent agent. Example:

```
Task 1 (Technical Specialist):
Prompt: "As a technical specialist, research [topic] focusing on implementation details, architecture patterns, and technical challenges. Use WebSearch to find latest documentation and technical case studies. Provide specific technical recommendations."

Task 2 (Business Strategy Specialist):
Prompt: "As a business strategist, analyze [topic] from market dynamics, ROI, competitive landscape, and strategic positioning. Search for market reports and business analyses. Focus on business value and adoption factors."

Task 3 (UX Specialist):
Prompt: "As a user experience specialist, investigate [topic] from user needs, usability, adoption barriers, and human factors perspectives. Find user studies and experience reports. Focus on end-user impact."

[Launch 4-6 specialists total, each with distinct focus]
```

## Key Principles

**Maintain Distinct Perspectives**
- Each specialist should keep their unique viewpoint throughout
- Don't homogen

ize into a single "AI voice"
- Preserve disagreements and tensions between perspectives
- Value comes from diversity of analysis

**Avoid Repetition**
- Track what's been thoroughly covered vs. needs deeper exploration
- Redirect specialists away from rehashing previous points
- Push for new angles, deeper analysis, broader implications
- Each round should add genuinely new insights

**Leverage Specialists' Expertise**
- Technical specialist focuses on HOW it works
- Business specialist focuses on WHY it matters commercially
- UX specialist focuses on WHO uses it and their experience
- Security specialist focuses on RISKS and vulnerabilities
- Each brings knowledge and methodology unique to their field

## Output Format

```
=== MULTI-MIND ANALYSIS: [Topic] ===
Specialists: [List] | Rounds: [N]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ROUND 1: KNOWLEDGE ACQUISITION

🔬 Technical Specialist
[Research findings and analysis]

💼 Business Strategy Specialist
[Market analysis and business insights]

👤 UX Specialist
[User research and experience findings]

🔒 Security Specialist
[Security analysis and risk assessment]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ROUND 2: CROSS-POLLINATION & CRITIQUE

🔬 Technical Specialist responds to other findings:
[Reviews others' work, identifies technical implications]

💼 Business Specialist responds:
[Business perspective on technical/UX findings]

👤 UX Specialist responds:
[User impact of technical/business decisions]

🔒 Security Specialist responds:
[Security implications of proposed approaches]

⚖️ Moderator Synthesis:
[What we learned, what still needs exploration]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ROUND 3: DEEP DIVE & RESOLUTION

[Specialists explore gaps and conflicts identified in Round 2]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FINAL SYNTHESIS

🧠 Key Insights
[Most valuable discoveries from the collective analysis]

⚠️ Tensions & Trade-offs
[Where specialists disagree and why both perspectives matter]

🎯 Recommendations
[Actionable recommendations incorporating all perspectives]

❓ Remaining Questions
[What the analysis couldn't fully resolve]
```

## When To Use This

**Good use cases:**
- Complex technical decisions (architecture, technology selection)
- Strategic planning (new features, market entry)
- Risk assessment (security, compliance, business risk)
- Research topics with multiple facets (regulations, best practices)
- Understanding trade-offs (performance vs. usability vs. cost)

**Not ideal for:**
- Simple factual lookups (use WebSearch directly)
- Single-perspective questions (use standard conversation)
- Time-sensitive quick answers (multi-mind takes longer)

## Success Metrics

A successful multi-mind session produces:
- ✅ Genuinely new insights each round (not repetition)
- ✅ Distinct specialist voices throughout
- ✅ Fresh information from web research
- ✅ Insights from cross-pollination that no single specialist would reach
- ✅ Outcome that exceeds sum of individual contributions
- ✅ Different error types caught by different specialists

## Example Topics

- "API authentication strategies for mobile apps"
- "Implementing real-time collaboration features"
- "Database migration strategies for high-traffic systems"
- "Accessibility compliance for complex web applications"
- "Adopting microservices architecture"

---

**Execute multi-mind analysis by launching specialist agents with the Task tool.**
