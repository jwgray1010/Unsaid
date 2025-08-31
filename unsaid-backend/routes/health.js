// routes/health.js
const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({
    ok: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'unsaid-backend',
    version: '1.0.0'
  });
});

module.exports = router;
