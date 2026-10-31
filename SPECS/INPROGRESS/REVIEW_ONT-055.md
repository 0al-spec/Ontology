# ONT-055 release workflow review

Reviewed source selection, build isolation, archive layout, token scope and
retry behavior. Release events verify the event's original release ID and SHA.
Manual backfill resolves an existing release from the default branch. The
publisher verifies the two archives' embedded identities and the remote asset
digests. PR builds and previews use read-only permissions. The checksum list
is uploaded last. The separate Linux Ubuntu smoke uses the extracted binary.

Review finding: the verifier should accept its own exact checksum file when
restarted in the same directory, and reject stale local checksum contents.
Add a regression before closing FLOW. The platform previews validate runner
behavior; real release publication is only exercised after workflow adoption.

Follow-up resolved: the verifier accepts its matching checksum file and fails
on conflicting contents before upload. All seven publication tests pass.
