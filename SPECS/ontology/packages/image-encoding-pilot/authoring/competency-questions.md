# Competency questions — Image Encoding Pilot

| Question | Representation | Checked boundary |
|---|---|---|
| Which image is selected? | ImageDocument.entityKey and reencodeTarget | Cross-object identity and actual selected input need consumer evidence |
| Does overwrite preserve identity? | Reencode.identityMode = in_place | Explicit model rule; matching filenames is insufficient |
| Is a copy the same entity? | Reencode.identityMode = copy | A distinct result identity needs explicit representation; no silent rebinding |
| Who acts and which encoder is used? | Optional reencodeContext and reencodeEncoder | Actor/instrument interpretation remains scoped; no inferred psychology |
| What action is requested? | Reencode.actionKind | jpeg_reencode is a descriptive value; generated string schema does not execute it |
| Must dimensions stay unchanged? | Reencode.dimensions and ImageState width/height | Consumer compares supplied before/after dimensions |
| Is quality a measurement of bytes or visual acceptance? | Encoder.quality versus ImageState.byteLength | Configuration, observed result and acceptance remain separate |
| Is the goal reduction or final size? | SizeGoal.basis | reduction uses both byte lengths; final_size uses the after measurement |
| Is the quantity exact or a bound? | SizeGoal.comparison and targetBytes | No silent exactly/at_least/at_most substitution; units already converted to bytes |
| What if a required observation is missing? | No fabricated ImageState; missingInput unknown | Unknown when data cannot decide; known-false conjuncts may establish not_satisfied |
| Are image measurements admitted physical snapshots? | ImageState | No eventcore:StateSnapshot, physical provenance receipt or exact Delta is synthesized |
| Does package approval establish implementation fidelity? | Draft package and manual policies | Actual code/evidence and formal claims require a separate bounded method |
