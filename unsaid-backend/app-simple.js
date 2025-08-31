// app.js - Simplified working version
const express = require('express');
const cors = require('cors');

const app = express();

// Basic middleware
app.use(express.json({ limit: '1mb' }));
app.use(cors());

// Health check
app.get('/health', (req, res) => {
  res.json({ ok: true, status: 'healthy' });
});

// API routes (only load working ones)
try {
  const suggestionsRoutes = require('./api/suggestions');
  app.use('/api/suggestions', suggestionsRoutes);
  console.log('✅ Suggestions API loaded');
} catch(e) {
  console.log('❌ Suggestions API error:', e.message);
}

try {
  const toneRoutes = require('./api/tone');
  if (typeof toneRoutes === 'function') {
    app.use('/api/tone', toneRoutes);
    console.log('✅ Tone API loaded');
  } else {
    console.log('❌ Tone API is not a function');
  }
} catch(e) {
  console.log('❌ Tone API error:', e.message);
}

// 404 handler
app.use((req, res) => {
  res.status(404).json({ ok: false, error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ ok: false, error: 'Internal Server Error' });
});

module.exports = app;
