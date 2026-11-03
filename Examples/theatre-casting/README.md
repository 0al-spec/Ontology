# Who acts in this show?

In show 17, the place of Hamlet starts vacant. Ivan appoints Anna at 09:00 UTC.
At 10:00 he replaces her with Boris. The two questions use different records.

| Question | Read | Answer |
| --- | --- | --- |
| Who plays Hamlet now? | Occupancy fact in the most recent after-snapshot for this place | Boris |
| Who appointed Anna and when? | Actor and appointee in the first event interpretation, plus its recorded time | Ivan at 09:00 UTC |

[The domain package](../../SPECS/ontology/examples/theatre.yaml) needs only a place, a person and the optional performedBy relation to describe the current cast. The history fixture uses the existing eventcore-v1 observation profile and its role bindings. A performer is the appointee in an appointment and can be the actor in a performance. A fire can occupy the actor role in an account of damage to the set. The relation supplies that reading.

From the repository root, run the replay with a built CLI:

```sh
python3 Examples/theatre-casting/replay.py /path/to/ontologyc
```

The replay queries the [two synthetic records](appointments.json), validates each replacement against the before/after snapshots and checks three mutations. Omitting Anna's removal violates the exact delta. An absent director reference fails resolution. Attributing the first appointment to Boris passes the structural check because he exists; the report still records sourceTruthVerified as false.
