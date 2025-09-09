// api/index.js
const serverless = require('serverless-http');

// Reuse across invocations to keep the function warm & fast
let handler;

module.exports = async (req, res) => {
  if (!handler) {
    // Lazily require so cold start builds the app once
    const app = require('../app'); // <-- your Express app from earlier
    handler = serverless(app, {
      // Ensure Express sets correct IP/Proto behind Vercel
      requestId: 'x-vercel-id' // optional; you already generate reqId in middleware
    });
  }
  return handler(req, res);
};