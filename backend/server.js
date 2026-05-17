require('dotenv').config();

const express = require('express');
const cors    = require('cors');
const multer  = require('multer');
const OpenAI  = require('openai');
const path    = require('path');

const app  = express();
const port = process.env.PORT || 5050;

// ── OpenAI client ────────────────────────────────────────────────────────────
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ── Middleware ────────────────────────────────────────────────────────────────
app.use(cors());
app.use(express.json());

// Store upload in memory so we can base64-encode it directly (no disk I/O)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 4 * 1024 * 1024 }, // 4 MB — mirrors Flutter's client-side check
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Unsupported image type. Use JPEG, PNG, WebP, or GIF.'));
    }
  },
});

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'wreniq-backend' });
});

// ── GET /api/search-parts ────────────────────────────────────────────────────
// Query params: year, make, model, engine, partName, suggestedSearchTerms
//
// Phase 9: returns real vendor search URLs for 9 stores.
// Prices/stock are "Check store" — no fake inventory data.
app.get('/api/search-parts', (req, res) => {
  const {
    year     = '',
    make     = '',
    model    = '',
    engine   = '',
    partName = 'Part',
  } = req.query;

  const vehicle = `${year} ${make} ${model}`.trim();
  const q  = encodeURIComponent(`${partName} ${vehicle}`);
  const qe = encodeURIComponent(`${partName} ${vehicle} ${engine}`);

  res.json([
    {
      storeName:        'AutoZone',
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'Free store pickup or ship to home',
      productUrl:       `https://www.autozone.com/searchresult?searchText=${q}`,
      isLiveLink:       true,
      notes:            'Loan-A-Tool program available. Free battery and check-engine testing in-store.',
    },
    {
      storeName:        "O'Reilly Auto Parts",
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'Free store pickup or ship to home',
      productUrl:       `https://www.oreillyauto.com/search?q=${q}`,
      isLiveLink:       true,
      notes:            'Loan-A-Tool available. Price match guarantee.',
    },
    {
      storeName:        'Advance Auto Parts',
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'Free store pickup — online discount codes often available',
      productUrl:       `https://shop.advanceautoparts.com/web/endeca/search?searchTerm=${q}`,
      isLiveLink:       true,
      notes:            'Check for online-only promo codes before checkout.',
    },
    {
      storeName:        'NAPA Auto Parts',
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'In-store pickup or delivery',
      productUrl:       `https://www.napaonline.com/en/search?q=${q}`,
      isLiveLink:       true,
      notes:            'Pro-grade parts. Commercial accounts available.',
    },
    {
      storeName:        'RockAuto',
      partTitle:        `${partName} — Multiple grades available`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New / Remanufactured',
      shippingOrPickup: 'Ships from warehouse — no local pickup',
      productUrl:       'https://www.rockauto.com',
      isLiveLink:       true,
      notes:            'Search by year / make / model on site. Economy, Standard, and OEM grades available.',
    },
    {
      storeName:        'eBay Motors',
      partTitle:        `${partName} — ${vehicle} (New & Used listings)`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New & Used',
      shippingOrPickup: 'Varies by seller',
      productUrl:       `https://www.ebay.com/sch/i.html?_nkw=${qe}&_sacat=6030`,
      isLiveLink:       true,
      notes:            'Check seller rating and return policy. Inspect all photos before purchasing.',
    },
    {
      storeName:        'Amazon',
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'Prime delivery available on eligible items',
      productUrl:       `https://www.amazon.com/s?k=${q}&rh=n%3A15684181`,
      isLiveLink:       true,
      notes:            'Use the vehicle fitment filter on the results page. Verify seller reputation.',
    },
    {
      storeName:        'Walmart Auto',
      partTitle:        `${partName} — ${vehicle}`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'New',
      shippingOrPickup: 'Ship to home or same-day pickup at many locations',
      productUrl:       `https://www.walmart.com/search?q=${q}`,
      isLiveLink:       true,
      notes:            'Check the automotive section filter. Pickup may be available same-day.',
    },
    {
      storeName:        'Car-Part.com',
      partTitle:        `${partName} — Salvage / Used (${vehicle})`,
      estimatedPrice:   'Check store',
      stockStatus:      'Check availability',
      condition:        'Used — Salvage',
      shippingOrPickup: 'Pickup from yard or freight shipping',
      productUrl:       'https://www.car-part.com/',
      isLiveLink:       true,
      notes:            'Search by year, make, and model on site. Verify mileage and OEM part number before ordering.',
    },
  ]);
});

// ── POST /api/mechanic-chat ───────────────────────────────────────────────────
// Body JSON: { message, vehicleInfo, scanContext, history: [{role,content}] }
// Returns:   { reply: "..." }
//
// Uses gpt-4o-mini — fast and cost-effective for conversational repair guidance.
app.post('/api/mechanic-chat', async (req, res) => {
  if (!process.env.OPENAI_API_KEY || process.env.OPENAI_API_KEY === 'put_your_key_here') {
    return res.status(503).json({ error: 'OPENAI_API_KEY not configured on server.' });
  }

  const { message, vehicleInfo = '', scanContext = '', history = [] } = req.body;

  if (!message || typeof message !== 'string' || !message.trim()) {
    return res.status(400).json({ error: 'message field is required.' });
  }

  const systemPrompt = buildChatSystemPrompt(vehicleInfo, scanContext);

  // Sanitise history: keep only role/content, cap at last 20 turns to limit tokens
  const safeHistory = history
    .filter(m => m && (m.role === 'user' || m.role === 'assistant') && typeof m.content === 'string')
    .slice(-20)
    .map(m => ({ role: m.role, content: m.content }));

  const messages = [
    { role: 'system', content: systemPrompt },
    ...safeHistory,
    { role: 'user',   content: message.trim() },
  ];

  try {
    const completion = await openai.chat.completions.create({
      model:      'gpt-4o-mini',
      messages,
      max_tokens: 800,
    });

    const reply = completion.choices?.[0]?.message?.content?.trim()
      || 'I could not generate a response. Please try again.';

    return res.json({ reply });
  } catch (err) {
    const status = err.status || 500;
    if (status === 401) return res.status(401).json({ error: 'Invalid OpenAI API key.' });
    if (status === 429) return res.status(429).json({ error: 'Rate limit reached. Try again shortly.' });
    return res.status(status).json({ error: `OpenAI error: ${err.message || 'Unknown error'}` });
  }
});

// ── POST /api/scan-part ───────────────────────────────────────────────────────
// Accepts multipart/form-data:
//   image  — the part photo (required)
//   year   — vehicle year  (optional, default 'Unknown')
//   make   — vehicle make  (optional)
//   model  — vehicle model (optional)
//   trim   — trim/engine   (optional)
//
// Returns JSON matching Flutter's ScanResult model schema.
app.post('/api/scan-part', upload.single('image'), async (req, res) => {
  // Guard: key must be configured
  if (!process.env.OPENAI_API_KEY || process.env.OPENAI_API_KEY === 'put_your_key_here') {
    return res.status(503).json({ error: 'OPENAI_API_KEY not configured on server.' });
  }

  // Guard: image required
  if (!req.file) {
    return res.status(400).json({ error: 'No image provided. Send the file under the "image" field.' });
  }

  const year  = (req.body.year  || 'Unknown').toString().trim();
  const make  = (req.body.make  || 'Unknown').toString().trim();
  const model = (req.body.model || 'Unknown').toString().trim();
  const trim  = (req.body.trim  || 'Unknown').toString().trim();

  const vehicleContext = `${year} ${make} ${model}, Trim/Engine: ${trim}`;

  // Base64-encode image straight from memory buffer
  const base64Image = req.file.buffer.toString('base64');
  const mimeType    = req.file.mimetype;

  const prompt = buildPrompt(vehicleContext);

  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: {
                url:    `data:${mimeType};base64,${base64Image}`,
                detail: 'high',
              },
            },
          ],
        },
      ],
      max_tokens:      2000,
      response_format: { type: 'json_object' },
    });

    const content = completion.choices?.[0]?.message?.content;
    if (!content) {
      return res.status(502).json({ error: 'OpenAI returned an empty response.' });
    }

    let partJson;
    try {
      partJson = JSON.parse(content);
    } catch {
      return res.status(502).json({ error: 'OpenAI response was not valid JSON.' });
    }

    // Normalise and forward to Flutter
    return res.json(normaliseScanResult(partJson, vehicleContext));
  } catch (err) {
    // Surface OpenAI API errors with a safe message
    const status = err.status || 500;
    if (status === 401) return res.status(401).json({ error: 'Invalid OpenAI API key.' });
    if (status === 413) return res.status(413).json({ error: 'Image too large for OpenAI.' });
    if (status === 429) return res.status(429).json({ error: 'OpenAI rate limit hit. Try again in a moment.' });
    return res.status(status).json({ error: `OpenAI error: ${err.message || 'Unknown error'}` });
  }
});

// ── Multer error handler (file too large, wrong type) ─────────────────────────
app.use((err, _req, res, _next) => {
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({ error: 'Image exceeds 4 MB limit.' });
  }
  return res.status(400).json({ error: err.message || 'Bad request.' });
});

// ── Helpers ────────────────────────────────────────────────────────────────────

function buildPrompt(vehicleContext) {
  return `You are an expert automotive parts identification assistant for the Wreniq app.

Vehicle context: ${vehicleContext}

Analyze the image and identify the car part. Return ONLY a valid JSON object — no markdown, no extra text — with exactly these fields:

{
  "partName": "specific part name, e.g. Front Brake Caliper",
  "confidence": 0.85,
  "explanation": "2–3 sentences describing the visual features that identify this part",
  "fitmentWarning": "specific fitment warning for this part type and vehicle combination",
  "estimatedPriceLow": 85.0,
  "estimatedPriceHigh": 200.0,
  "repairDifficulty": "Intermediate",
  "toolsNeeded": ["tool 1", "tool 2", "tool 3"],
  "repairSteps": ["Step 1.", "Step 2.", "Step 3."],
  "suggestedSearchTerms": ["search term 1", "search term 2"],
  "compatibleParts": ["OEM Part Type", "Aftermarket Option"],
  "safetyWarnings": ["Safety warning 1.", "Safety warning 2."]
}

Rules:
- partName: be specific (e.g. "Front Brake Caliper", not just "brake part")
- confidence: 0.0–1.0 (>0.85 = clear image and high certainty; <0.5 = unclear/unidentifiable)
- repairDifficulty: must be exactly one of: Beginner, Intermediate, Advanced
- estimatedPriceLow / estimatedPriceHigh: typical aftermarket USD prices, not dealer/OEM
- toolsNeeded: 3–6 specific tools required for replacement
- repairSteps: 6–12 detailed, ordered steps written for a home mechanic
- suggestedSearchTerms: 4–6 useful search queries for finding this exact part
- compatibleParts: 2–4 part variants (OEM, reman, performance, etc.)
- safetyWarnings: 2–4 critical safety points specific to this part and repair
- If the part cannot be clearly identified, set confidence below 0.5 and explain why in explanation
- Always include the vehicle context in the fitmentWarning if relevant`;
}

function buildChatSystemPrompt(vehicleInfo, scanContext) {
  let ctx = '';
  if (vehicleInfo) ctx += `\nVehicle: ${vehicleInfo}`;
  if (scanContext) ctx += `\nPart context: ${scanContext}`;

  return `You are Wreniq AI, an automotive repair assistant by Digiscope. Give clear, safe, beginner-friendly repair guidance. Never guarantee fitment. Always remind users to verify VIN/year/make/model/engine. Warn when a repair is unsafe for beginners.

Safety rules:
- Airbags, SRS, and pre-tensioners: always warn these are high-risk and recommend a professional.
- Brakes: warn about proper bleeding, torque specs, and bedding-in procedure.
- Fuel system: warn about fire risk, pressure relief, and ventilation requirements.
- High-voltage hybrid/EV systems (orange cables): always recommend a certified EV technician.
- Jack and lift safety: always remind the user to use rated jack stands and never work under a vehicle supported only by a floor jack.
- Steering and suspension: note that alignment is required after most repairs and that errors affect vehicle control.
- Electrical systems: advise disconnecting the battery negative terminal before working.
- Never instruct the user to bypass, defeat, or disable any safety system.
- If a repair requires specialized tools, training, or poses serious risk to a beginner, clearly recommend a qualified mechanic.
- Always recommend verifying part fitment using the vehicle's VIN before purchasing.
${ctx}

Keep answers concise, practical, and formatted in short paragraphs. If asked about something unrelated to vehicles or automotive repair, politely redirect to automotive topics.`;
}

function safeStringList(val) {
  if (Array.isArray(val)) return val.map(String);
  return [];
}

function normaliseScanResult(json, vehicleInfo) {
  const confidence = Math.min(1.0, Math.max(0.0, Number(json.confidence) || 0.5));
  const priceLow   = Number(json.estimatedPriceLow)  || 0;
  const priceHigh  = Number(json.estimatedPriceHigh) || 0;

  const validDifficulties = ['Beginner', 'Intermediate', 'Advanced'];
  const difficulty = validDifficulties.includes(json.repairDifficulty)
    ? json.repairDifficulty
    : 'Intermediate';

  const priceEstimate = priceLow > 0
    ? `$${Math.round(priceLow)} – $${Math.round(priceHigh)}`
    : 'Price unavailable';

  return {
    partName:             json.partName         || 'Unknown Part',
    confidence:           confidence,
    explanation:          json.explanation      || '',
    fitmentWarning:       json.fitmentWarning   || 'Always verify fitment using your VIN before purchasing.',
    estimatedPriceLow:    priceLow,
    estimatedPriceHigh:   priceHigh,
    priceEstimate,
    repairDifficulty:     difficulty,
    toolsNeeded:          safeStringList(json.toolsNeeded),
    repairSteps:          safeStringList(json.repairSteps),
    suggestedSearchTerms: safeStringList(json.suggestedSearchTerms),
    compatibleParts:      safeStringList(json.compatibleParts),
    safetyWarnings:       safeStringList(json.safetyWarnings),
    vehicleInfo,
    buyOptions: [
      { store: 'AutoZone',      priceRange: 'Search on site', url: 'autozone.com' },
      { store: 'RockAuto',      priceRange: 'Search on site', url: 'rockauto.com' },
      { store: "O'Reilly Auto", priceRange: 'Search on site', url: 'oreillyauto.com' },
    ],
  };
}

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(port, () => {
  console.log(`Wreniq backend running on port ${port}`);
  if (!process.env.OPENAI_API_KEY || process.env.OPENAI_API_KEY === 'put_your_key_here') {
    console.warn('  WARNING: OPENAI_API_KEY not set — scan-part endpoint will return 503');
  }
});
