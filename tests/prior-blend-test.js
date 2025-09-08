// tests/prior-blend-test.js
// Minimal runtime test (no framework) for prior blending utilities.
const { normalizeScores, defaultPriorWeight } = require('../api/_lib/utils/priors');

function assertAlmostEqual(a,b,msg){ if(Math.abs(a-b)>1e-6){ throw new Error(msg+` expected ${b} got ${a}`);} }

(function run(){
  const prior = normalizeScores({ anxious: 3, avoidant: 1, disorganized: 0, secure: 1 });
  const server = normalizeScores({ anxious: 1, avoidant: 3, disorganized: 0, secure: 1 });
  const w0 = defaultPriorWeight(0,7); // ~1
  const w7 = defaultPriorWeight(7,7); // floor 0.2
  if(w7 < 0.19 || w7 > 0.21) throw new Error('Floor weight mismatch');
  const blendEarly = normalizeScores({
    anxious: prior.anxious*w0 + server.anxious*(1-w0),
    avoidant: prior.avoidant*w0 + server.avoidant*(1-w0),
    disorganized: prior.disorganized*w0 + server.disorganized*(1-w0),
    secure: prior.secure*w0 + server.secure*(1-w0),
  });
  const sum = Object.values(blendEarly).reduce((a,b)=>a+b,0);
  assertAlmostEqual(sum,1,'Blend not normalized');
  console.log('✅ prior-blend-test passed');
})();
