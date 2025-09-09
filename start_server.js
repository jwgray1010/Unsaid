#!/usr/bin/env node

/**
 * Simple server starter for testing keyboard controller endpoints
 */

const path = require('path');

console.log('🚀 Starting Keyboard Controller API Server...');
console.log('📍 Current directory:', process.cwd());

// Set environment
process.env.NODE_ENV = process.env.NODE_ENV || 'development';

try {
  // Load the backend app
  const app = require('./unsaid-backend/app.js');
  
  const port = process.env.PORT || 3000;
  
  const server = app.listen(port, () => {
    console.log(`✅ Server running on http://localhost:${port}`);
    console.log('📱 Keyboard Controller Endpoints:');
    console.log(`   Health: http://localhost:${port}/health/live`);
    console.log(`   Version: http://localhost:${port}/version`);
    console.log(`   Tone Analysis: POST http://localhost:${port}/api/tone`);
    console.log(`   Suggestions: POST http://localhost:${port}/api/suggestions`);
    console.log();
    console.log('🛑 Press Ctrl+C to stop');
  });
  
  // Graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down server...');
    server.close(() => {
      console.log('✅ Server stopped');
      process.exit(0);
    });
  });
  
} catch (error) {
  console.error('❌ Failed to start server:', error.message);
  console.error('\n🔧 Troubleshooting:');
  console.error('1. Check that all dependencies are installed');
  console.error('2. Verify data files exist in unsaid-backend/data/');
  console.error('3. Ensure services are properly configured');
  process.exit(1);
}
