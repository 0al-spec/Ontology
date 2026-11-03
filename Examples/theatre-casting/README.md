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

## Foundation design checkpoint (proposed)

Entities interact by acting on one another. A domain author can name the
whole interaction by constructing a relationship from its subject, action and
object. The subject fills the actor position for this action. Actor refers
back to that same entity. A domain-specific relationship type gives the
whole triple a meaning in the situation being described.

Consider two appointments. The following is design notation:

```text
CastAppointment(subject: Ivan, action: Appoint(), object: Anna)
    for: Hamlet in show 17
CrewAppointment(subject: Ivan, action: Appoint(), object: Anna)
    for: flight 42
```

Both relationships use the same kind of action and even the same people. Each
occurrence can carry its own optional motive and an optional participating
entity, for example an instrument when the domain calls for one. The show and
flight identify what each appointment is for. Reading the triple through its
relationship type tells a consumer whether to look for a cast member or a crew
member. Reading the subject as actor answers who performed the appointment.

Entities have properties. In the show example the effect can be read from the
performer of the Hamlet slot; in the flight example it can be read from crew
membership. Another example is handing over a letter: changing its holder from
Anna to Boris changes the held items of both people. Which properties the
domain records is part of describing the situation.

The foundation design target is to let a domain declare both relationship
types, reuse the same action and query its participants and motive. The
executable replay above demonstrates the separate eventcore-v1 history check.
