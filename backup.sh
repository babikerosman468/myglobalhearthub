```bash
#!/data/data/com.termux/files/usr/bin/bash

BACKUP_FILE="myglobalhearthub_$(date +%Y%m%d_%H%M%S).zip"

echo "🗂️ Creating backup: $BACKUP_FILE ..."
zip -r "$BACKUP_FILE" * -x "*.zip" "*.log" "*.pid"
echo "✅ Backup created."

