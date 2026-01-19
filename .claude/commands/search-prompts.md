# Search Prompts - Find Past Conversations

Search through your Claude Code conversation history to find previous discussions, solutions, and insights.

**Usage**: `/search-prompts <search terms>`

## What This Does

Searches multiple sources where Claude Code stores conversation data:
1. **SQLite database** - Main conversation storage (`~/.claude/__store.db`)
2. **Project history** - Project-specific JSON files (`~/.claude.json`)
3. **Session files** - Individual conversation sessions

Returns ranked results showing where your search terms appeared in past conversations.

## How It Works

### Search Strategy

**Execute searches in this order:**

1. **Database Search** (fastest, most comprehensive)
2. **Project History Search** (project-specific context)
3. **Session Search** (recent conversations)

### Step 1: Database Search

Search the main SQLite database:

```bash
sqlite3 ~/.claude/__store.db "
SELECT
    b.session_id,
    datetime(b.timestamp, 'unixepoch') as date,
    substr(u.message, 1, 150) as preview
FROM user_messages u
JOIN base_messages b ON u.uuid = b.uuid
WHERE u.message LIKE '%$ARGUMENTS%'
ORDER BY b.timestamp DESC
LIMIT 20;
"
```

This finds:
- User messages containing search terms
- When they were sent (dates)
- Which session they're from
- Preview of the context

### Step 2: Project History Search

Search project-specific history (if exists):

```python
import json

# Read Claude project config
with open(os.path.expanduser('~/.claude.json'), 'r') as f:
    data = json.load(f)

# Search through project histories
results = []
for project_path, project_data in data.get('projects', {}).items():
    for item in project_data.get('history', []):
        if search_term.lower() in str(item).lower():
            results.append({
                'project': project_path,
                'text': item,
                'relevance': str(item).lower().count(search_term.lower())
            })

# Sort by relevance
results.sort(key=lambda x: x['relevance'], reverse=True)
```

### Step 3: Time-Filtered Search

Search recent conversations (last 7 days):

```bash
sqlite3 ~/.claude/__store.db "
SELECT
    b.session_id,
    datetime(b.timestamp, 'unixepoch') as date,
    u.message
FROM user_messages u
JOIN base_messages b ON u.uuid = b.uuid
WHERE u.message LIKE '%$ARGUMENTS%'
AND b.timestamp > strftime('%s', 'now', '-7 days')
ORDER BY b.timestamp DESC;
"
```

## Output Format

```
🔍 SEARCH RESULTS: "$ARGUMENTS"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 SUMMARY
• Database: 12 matches
• Recent (7 days): 5 matches
• Projects: 3 matches

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 TOP MATCHES (by relevance)

1. Session: abc123 | Date: 2026-01-18 15:30
   Project: KahloStudio
   Preview: "Working on the BrowserPanel search feature..."
   Relevance: 5 mentions

2. Session: def456 | Date: 2026-01-15 10:22
   Project: KahloStudio
   Preview: "Need to implement token search in the database..."
   Relevance: 3 mentions

3. Session: ghi789 | Date: 2026-01-10 14:45
   Project: VectorKit
   Preview: "The search algorithm should use fuzzy matching..."
   Relevance: 2 mentions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔗 RESUME SESSIONS

To continue any of these conversations:
• claude --resume abc123
• claude --resume def456
• claude --resume ghi789

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 SEARCH TIPS

Try these variations:
• "search algorithm" (exact phrase)
• search OR algorithm (either term)
• "browser panel" filtering (multiple terms)
```

## Search Tips

**Effective searches:**
- Use specific technical terms unique to your work
- Try variations (plurals, different tenses)
- Search for file names or function names
- Use project names to filter context
- Combine with time filters for recent vs. historical

**Examples:**
```bash
/search-prompts "BrowserPanel filtering"
/search-prompts "database schema"
/search-prompts "workout routes GPX"
/search-prompts "compile stylesheet"
```

## Advanced Searches

### Find by Session ID
```bash
sqlite3 ~/.claude/__store.db "
SELECT * FROM base_messages
WHERE session_id = 'abc123'
ORDER BY timestamp;
"
```

### Find All Sessions
```bash
sqlite3 ~/.claude/__store.db "
SELECT DISTINCT
    session_id,
    datetime(MIN(timestamp), 'unixepoch') as start,
    datetime(MAX(timestamp), 'unixepoch') as end,
    COUNT(*) as messages
FROM base_messages
GROUP BY session_id
ORDER BY MAX(timestamp) DESC
LIMIT 10;
"
```

### Search Conversation Summaries
```bash
sqlite3 ~/.claude/__store.db "
SELECT summary, datetime(updated_at, 'unixepoch')
FROM conversation_summaries
WHERE summary LIKE '%$ARGUMENTS%'
ORDER BY updated_at DESC;
"
```

## Related Features

**After finding relevant conversations:**
- Use `claude --resume SESSION_ID` to continue that conversation
- Use `/page` to save current conversation before resuming old one
- Review saved session files in your project directory

## Common Use Cases

**"What did we decide about...?"**
```bash
/search-prompts "database migration strategy"
```

**"How did we solve...?"**
```bash
/search-prompts "overlay positioning bug"
```

**"Where did we discuss...?"**
```bash
/search-prompts "VectorKit compilation"
```

**"When did we work on...?"**
```bash
/search-prompts "workout routes panel"
```

## Database Location

Claude Code stores conversations in:
- **Main database**: `~/.claude/__store.db` (SQLite)
- **Project config**: `~/.claude.json` (JSON)
- **Session files**: `~/.claude/projects/<project>/` (varies)

## Success Criteria

A successful search:
- ✅ Finds relevant past conversations
- ✅ Shows dates and context
- ✅ Ranks by relevance
- ✅ Provides session IDs for resuming
- ✅ Searches multiple data sources
- ✅ Returns results quickly

---

**Execute comprehensive search across all conversation sources now.**
