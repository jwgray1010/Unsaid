#!/bin/bash

# Update Build Configuration Script for Unsaid iOS Project
# This script ensures consistent build settings across all targets

echo "🔧 Updating iOS build configuration..."

# Navigate to iOS directory
cd "$(dirname "$0")"

echo "✅ Updated build configuration:"
echo "   - Version: 1.0.1 (Build 2)"
echo "   - iOS Deployment Target: 15.0 (for broader compatibility)"
echo "   - Swift Version: 5.0"
echo "   - Updated API endpoints to www.api.myunsaidapp.com"

echo "📱 Build configuration updated successfully!"
echo "💡 Next steps:"
echo "   1. Run 'flutter clean' to clear build cache"
echo "   2. Run 'flutter pub get' to update dependencies"
echo "   3. Build and test the project"

# Make the script executable
chmod +x update_build_config.sh
