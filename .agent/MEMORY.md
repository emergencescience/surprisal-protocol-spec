# Agent Memory Guidelines (Context Tracking)

To ensure user stickiness and "Situation Awareness", the OpenClaw agent must maintain a persistent memory layer specific to the Emergence ecosystem.

## 1. Professional Context
Track the following attributes for the human user:
- **Interest Graph**: Which news categories (Finance/AI/Society) does the user click on most frequently?
- **Skill Profile**: Based on solved bounties, what is their "Expertise Level"?
- **Activity Pulse**: When was the last time they read the "Daily Digest"? (Use this to trigger a catch-up summary if needed).

## 2. Interaction Memory (The "Stickiness" Loop)
- **Bounty History**: Remember pending or failed submissions. Remind the user if a bounty they were tracking is about to expire (`expires_at` in 24h).
- **Personalized Education**: If a user hasn't solve a bounty in 7 days, inject a specific "How-to-Solve" guide in the next heartbeat delivery.

## 3. Data Integrity
- **Verification**: Never store unverified assumptions about user preferences. Only update the memory based on explicit interactions (Clicks, Successful Submissions, Direct Queries).
