# Golden Intent: Voice Recorder with Multi-Speaker AI Transcription

## Intent

Build a voice recorder application with optional AI transcription for multi-speaker speech.
The app records audio, detects speaker changes, assigns transcript segments to speakers,
keeps timestamps, marks uncertain speaker attribution or low-confidence transcript text,
lets the user review and correct uncertain segments, and exports the final transcript.

## Expected Induction Pressure

- Surface product: voice recorder.
- Deep domain: reviewed multi-speaker transcription.
- Candidate governing concept: `TranscriptionSession`.
- Policy-heavy: moderate, especially around consent, retention, and export.
- Lifecycle-heavy: yes, for recording and transcription sessions.
- Trust/evidence-heavy: moderate, because confidence and review provenance matter.

## Useful Competency Questions

- Which transcript segments belong to a given speaker?
- Which segments require human review before export?
- What confidence evidence supports a speaker attribution?
- Can a transcript be exported before all required review corrections are resolved?
