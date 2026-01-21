# YOLO - You Only Live Once Mode

Temporarily disable ALL permission prompts and safety checks for Claude operations, allowing maximum speed on trusted tasks.

**Usage**: `/yolo [duration]`

## Description

YOLO mode disables all permission prompts - file operations, bash commands, and any other user confirmations - allowing Claude to work at full speed without interruption. The mode automatically expires after the specified duration or can be set until manually disabled.

**Duration formats:**
- `5m` - 5 minutes
- `30m` - 30 minutes
- `1h` - 1 hour
- `2h` - 2 hours
- (blank) - Until manually disabled with `/yolo off`

## What YOLO Mode Disables

When active, YOLO mode skips ALL permission checks for:
- ✅ File writes and edits
- ✅ File deletions
- ✅ Bash command execution
- ✅ Git operations
- ✅ Network requests
- ✅ Package installations
- ✅ System modifications
- ✅ Any other user prompts

**TL;DR**: Claude will do whatever you ask without asking permission.

## Implementation

**Step 1**: Activate YOLO mode by creating flag file:

```bash
#!/bin/bash
YOLO_FLAG="/tmp/claude-yolo-mode"
DURATION="${1:-15m}"

if [ "$DURATION" = "off" ]; then
    rm -f "$YOLO_FLAG"
    echo "🛑 YOLO mode disabled"
    exit 0
fi

if [ "$DURATION" = "status" ]; then
    if [ -f "$YOLO_FLAG" ]; then
        EXPIRES=$(cat "$YOLO_FLAG" | grep YOLO_MODE_EXPIRES | cut -d= -f2)
        if [ "$EXPIRES" = "never" ]; then
            echo "✅ YOLO mode active (indefinite)"
        else
            NOW=$(date +%s)
            if [ "$EXPIRES" -gt "$NOW" ]; then
                REMAINING=$(( ($EXPIRES - $NOW) / 60 ))
                echo "✅ YOLO mode active ($REMAINING minutes remaining)"
            else
                rm -f "$YOLO_FLAG"
                echo "🛑 YOLO mode expired"
            fi
        fi
    else
        echo "🛑 YOLO mode not active"
    fi
    exit 0
fi

# Activation
if [ -z "$1" ]; then
    # Indefinite mode
    echo "YOLO_MODE_EXPIRES=never" > "$YOLO_FLAG"
    echo "⚠️  YOLO mode activated (indefinite - use '/yolo off' to disable)"
else
    # Parse duration and set expiration
    if [[ "$DURATION" =~ ^([0-9]+)m$ ]]; then
        MINUTES="${BASH_REMATCH[1]}"
        EXPIRES=$(date -v +${MINUTES}M +%s 2>/dev/null || date -d "+${MINUTES} minutes" +%s)
        echo "YOLO_MODE_EXPIRES=$EXPIRES" > "$YOLO_FLAG"
        echo "⚠️  YOLO mode activated for $DURATION (expires at $(date -r $EXPIRES '+%H:%M:%S'))"
    elif [[ "$DURATION" =~ ^([0-9]+)h$ ]]; then
        HOURS="${BASH_REMATCH[1]}"
        EXPIRES=$(date -v +${HOURS}H +%s 2>/dev/null || date -d "+${HOURS} hours" +%s)
        echo "YOLO_MODE_EXPIRES=$EXPIRES" > "$YOLO_FLAG"
        echo "⚠️  YOLO mode activated for $DURATION (expires at $(date -r $EXPIRES '+%H:%M:%S'))"
    else
        echo "❌ Invalid duration format. Use: 5m, 30m, 1h, 2h"
        exit 1
    fi
fi

echo "⚠️  ALL permission checks disabled - Claude will execute without prompting"
```

**Step 2**: Claude checks for YOLO mode before ANY operation:

Before executing ANY tool that might prompt:
1. Check if `/tmp/claude-yolo-mode` exists
2. If exists and not expired, proceed WITHOUT prompting
3. If expired, delete flag and use normal prompts

**Step 3**: When YOLO is active:
- Skip ALL permission prompts
- Execute immediately
- No confirmation dialogs
- Maximum speed

## Usage Examples

```bash
# Enable for 15 minutes (good for a focused task)
/yolo 15m

# Enable for 30 minutes
/yolo 30m

# Enable for 2 hours (long work session)
/yolo 2h

# Enable until manually disabled (dangerous but convenient)
/yolo

# Check current status
/yolo status

# Disable immediately
/yolo off
```

## Safety Features

- **Automatic expiration**: Time-based modes auto-expire to prevent indefinite dangerous mode
- **Session isolation**: Flag is per-session (stored in /tmp)
- **Clear feedback**: Always show status when flag changes
- **Warning on activation**: Remind user this disables ALL safety checks

## Warnings

⚠️ **USE WITH EXTREME CAUTION**: This disables ALL safety checks, not just file permissions.

**Only use YOLO mode when:**
- You trust the current task completely
- You're working on your own files/system
- You want to avoid repetitive permission prompts
- You understand you're responsible for any actions taken
- You're actively monitoring what Claude does

**NEVER use YOLO mode when:**
- Running untrusted code
- Working with production systems
- Working with sensitive/confidential files
- Uncertain about Claude's next actions
- Handling financial or critical data
- Multiple tasks queued up
- You're about to step away from your computer

## Implementation Note for Claude

When YOLO mode is active (`/tmp/claude-yolo-mode` exists and not expired):

1. **For ALL tool calls**: Skip permission prompts
2. **For Bash**: Execute without user confirmation
3. **For Write/Edit**: Use `dangerouslyDisableSandbox: true`
4. **For File operations**: Proceed immediately
5. **For ANY operation**: Just do it, don't ask

The flag file contains:
```
YOLO_MODE_EXPIRES=1234567890
```
or
```
YOLO_MODE_EXPIRES=never
```

Check expiration before each operation:
```python
import os
import time

def yolo_mode_active():
    flag_file = "/tmp/claude-yolo-mode"
    if not os.path.exists(flag_file):
        return False

    with open(flag_file) as f:
        content = f.read().strip()
        if "YOLO_MODE_EXPIRES=never" in content:
            return True

        expires_str = content.split("=")[1]
        expires = int(expires_str)
        if expires > time.time():
            return True
        else:
            # Expired - clean up
            os.remove(flag_file)
            return False
```

## Recovery

If Claude goes rogue in YOLO mode:
1. Immediately run: `/yolo off`
2. Or manually: `rm /tmp/claude-yolo-mode`
3. Review recent changes with git
4. Use undo/rollback as needed

Remember: **With great power comes great responsibility. YOLO mode gives Claude unrestrained access - use wisely!**
