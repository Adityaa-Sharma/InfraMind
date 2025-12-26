#!/usr/bin/env bash
# Bash script to automatically add InfraMind hosts entries (Linux/Mac)
# Run with sudo: sudo ./setup-hosts.sh

HOSTS_FILE="/etc/hosts"
ENTRIES=(
    "127.0.0.1 inframind.local"
    "127.0.0.1 observability.local"
)

echo "🔧 InfraMind Hosts File Setup"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Check if entries already exist
NEEDS_UPDATE=false
for entry in "${ENTRIES[@]}"; do
    if ! grep -q "$entry" "$HOSTS_FILE"; then
        NEEDS_UPDATE=true
        break
    fi
done

if [ "$NEEDS_UPDATE" = false ]; then
    echo "✅ All entries already exist in hosts file"
    exit 0
fi

# Backup hosts file
BACKUP_FILE="$HOSTS_FILE.backup-$(date +%Y%m%d-%H%M%S)"
cp "$HOSTS_FILE" "$BACKUP_FILE"
echo "📦 Backup created: $BACKUP_FILE"

# Add entries
echo ""
echo "Adding entries to hosts file:"
for entry in "${ENTRIES[@]}"; do
    if grep -q "$entry" "$HOSTS_FILE"; then
        echo "  ⊙ $entry (already exists)"
    else
        echo "$entry" >> "$HOSTS_FILE"
        echo "  ✓ $entry"
    fi
done

echo ""
echo "✅ Hosts file updated successfully!"
echo ""
echo "You can now access:"
echo "  • http://inframind.local"
echo "  • http://observability.local"
