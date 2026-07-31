const asyncHandler = require('express-async-handler');
const axios = require('axios');

const ALLOWED_KINDS = new Set([
    'pass', 'screen', 'cut', 'shoot', 'dribble', 'switchDefense', 'inbound',
    'flare', 'staggerScreen', 'handoff', 'pickAndRoll', 'roll', 'pop',
    'drive', 'spacing', 'other'
]);

const clampSlot = (value) => {
    const slot = Number(value);
    return Number.isInteger(slot) && slot >= 1 && slot <= 5 ? slot : null;
};

const sanitizeStep = (step, index) => {
    if (!step || typeof step !== 'object') return null;
    const actorSlot = clampSlot(step.actorSlot);
    if (!actorSlot || !ALLOWED_KINDS.has(step.kind)) return null;

    const clean = {
        id: `ai_${index + 1}`,
        kind: step.kind,
        actorSlot,
        isDefense: step.isDefense === true,
    };

    const targetSlot = clampSlot(step.targetSlot);
    if (targetSlot) {
        clean.targetSlot = targetSlot;
        clean.targetIsDefense = step.targetIsDefense === true;
    }

    const dx = Number(step.toNorm?.dx);
    const dy = Number(step.toNorm?.dy);
    if (Number.isFinite(dx) && Number.isFinite(dy)) {
        clean.toNorm = {
            dx: Math.max(0, Math.min(1, dx)),
            dy: Math.max(0, Math.min(1, dy)),
        };
    }

    if (typeof step.note === 'string' && step.note.trim()) {
        clean.note = step.note.trim().slice(0, 120);
    }
    return clean;
};

const compactCommand = (steps) => steps.map((step) => {
    const actor = `${step.isDefense ? 'D' : 'P'}${step.actorSlot}`;
    const target = step.targetSlot
        ? ` ${step.targetIsDefense ? 'D' : 'P'}${step.targetSlot}`
        : '';
    return `${actor} ${step.kind}${target}`;
}).join(' → ');

const SYSTEM_PROMPT = `You convert a basketball coach's natural-language instruction into BallChart play steps.
Return JSON only with {"steps":[...],"confidence":0.0-1.0}.
Players P1-P5 are offense; D1-D5 are defense. Preserve spoken order and implied possession.
Allowed kind values: ${[...ALLOWED_KINDS].join(', ')}.
Every step requires kind, actorSlot (1-5), and isDefense. Add targetSlot and targetIsDefense for passes, screens, handoffs, switches, or movement toward a player.
For movement to a court area, use toNorm with dx/dy from 0 to 1. Court landmarks: top=(0.5,0.72), left wing=(0.18,0.70), right wing=(0.82,0.70), left corner=(0.08,0.88), right corner=(0.92,0.88), paint=(0.5,0.85), basket=(0.5,0.90).
Resolve pronouns from context. Ignore conversational filler. Never invent a player, action, or destination. If ambiguous, omit the uncertain step and lower confidence. Maximum 20 steps.`;

const callGemini = async (command) => {
    const model = process.env.GEMINI_COMMAND_MODEL || 'gemini-2.5-flash';
    const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
            systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
            contents: [{ role: 'user', parts: [{ text: command }] }],
            generationConfig: {
                temperature: 0,
                responseMimeType: 'application/json',
            },
        },
        {
            timeout: 30000,
            headers: {
                'x-goog-api-key': process.env.GEMINI_API_KEY,
                'Content-Type': 'application/json',
            },
        }
    );
    return response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '{}';
};

const callOpenAI = async (command) => {
    const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
            model: process.env.OPENAI_COMMAND_MODEL || 'gpt-4o-mini',
            temperature: 0,
            response_format: { type: 'json_object' },
            messages: [
                { role: 'system', content: SYSTEM_PROMPT },
                { role: 'user', content: command },
            ],
        },
        {
            timeout: 30000,
            headers: {
                Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
                'Content-Type': 'application/json',
            },
        }
    );
    return response.data?.choices?.[0]?.message?.content || '{}';
};

// @desc Convert natural coaching language into BallChart animation steps
// @route POST /api/tactical/parse-command
// @access Private
const parseCommand = asyncHandler(async (req, res) => {
    const command = req.body?.command?.toString().trim() || '';
    if (!command) {
        res.status(400);
        throw new Error('Command is required');
    }
    if (command.length > 2000) {
        res.status(400);
        throw new Error('Command is too long');
    }

    let rawJson;
    if (process.env.GEMINI_API_KEY) {
        rawJson = await callGemini(command);
    } else if (process.env.OPENAI_API_KEY) {
        rawJson = await callOpenAI(command);
    } else {
        res.status(503);
        throw new Error('AI command parser is not configured');
    }

    let parsed;
    try {
        parsed = JSON.parse(rawJson);
    } catch (_) {
        res.status(502);
        throw new Error('AI returned an invalid command');
    }

    const steps = (Array.isArray(parsed.steps) ? parsed.steps : [])
        .slice(0, 20)
        .map(sanitizeStep)
        .filter(Boolean);

    if (!steps.length) {
        res.status(422);
        throw new Error('No supported tactical actions were recognized');
    }

    res.json({
        intent: steps.length > 1 ? 'sequence' : 'playerPass',
        entities: {},
        confidence: Math.max(0, Math.min(1, Number(parsed.confidence) || 0.75)),
        alternatives: [],
        normalizedCommand: compactCommand(steps),
        steps,
    });
});

module.exports = { parseCommand };
