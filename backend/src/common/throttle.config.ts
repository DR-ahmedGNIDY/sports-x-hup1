// Per-route overrides of the app-wide default (100/min, ThrottlerModule
// .forRoot in app.module.ts). Shared here rather than declared per
// controller because the same two limits apply across the clubs, players
// and invitations controllers, and they only mean anything if they agree.
// (auth.controller.ts keeps its own AUTH_THROTTLE — credential endpoints
// are a different threat model and a much tighter limit.)

// Public-code lookups (GET /clubs/by-code/:code, GET /players/by-code/:code).
// Codes are sequential, so this is the one surface where enumerating them in
// bulk would otherwise be cheap. Generous enough for a human typing or
// pasting codes, far too slow to walk the whole range.
export const CODE_LOOKUP_THROTTLE = { default: { limit: 20, ttl: 60_000 } };

// Sending an invitation. Caps how fast one account can spray invitations
// across the platform — the duplicate-pending unique index already stops
// repeats to the *same* counterpart, so this is specifically about breadth.
export const INVITATION_SEND_THROTTLE = { default: { limit: 10, ttl: 60_000 } };
