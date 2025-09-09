#!/bin/bash
# Clean up auto-generated .h files that conflict with our .mm implementation
# Run this after Flutter build operations

cd "$(dirname "$0")/Runner"

echo "🧹 Cleaning up auto-generated header files..."

# Remove problematic header files if they exist
if [ -f "GeneratedPluginRegistrant.h" ]; then
    echo "  ❌ Removing GeneratedPluginRegistrant.h"
    rm -f GeneratedPluginRegistrant.h
fi

if [ -f "GeneratedPluginRegistrant.m" ]; then
    echo "  ❌ Removing GeneratedPluginRegistrant.m"
    rm -f GeneratedPluginRegistrant.m
fi

if [ -f "KeyboardDataSyncBridge.h" ]; then
    echo "  ❌ Removing KeyboardDataSyncBridge.h"
    rm -f KeyboardDataSyncBridge.h
fi

echo "✅ Header cleanup complete - using .mm files only"
