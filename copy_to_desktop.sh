#!/bin/bash

# Copy Unsaid Project to Desktop for Xcode Development
# Run this script to copy the project to your desktop

echo "🚀 Copying Unsaid Project to Desktop..."
echo "======================================="

# Create desktop directory if it doesn't exist
mkdir -p ~/Desktop

# Copy the project
echo "📂 Copying Flutter project..."
cp -r /workspaces/Unsaid/Unsaid ~/Desktop/UnsaidProject

# Set proper permissions
echo "🔧 Setting permissions..."
chmod -R 755 ~/Desktop/UnsaidProject

echo "✅ Project copied successfully!"
echo ""
echo "📱 Next steps:"
echo "1. Open Xcode"
echo "2. File → Open"
echo "3. Navigate to ~/Desktop/UnsaidProject/ios/"
echo "4. Open 'Runner.xcworkspace'"
echo ""
echo "🎯 Project location: ~/Desktop/UnsaidProject"
echo "🎯 Xcode workspace: ~/Desktop/UnsaidProject/ios/Runner.xcworkspace"
echo ""
echo "🚀 Ready to build your App Store ready iOS app!"
