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

An action is a directed relationship in which one entity acts on another.
Its subject is the actor by definition. The object is the entity acted upon.
The same entity can be the object of one action and the actor of another.
Composition such as a show containing a vacant cast slot is also a relationship.
It describes structure and can be queried before anyone performs an action.

Every action has a consequence. Describe it as a change to named properties of
the participating entities. A motive may be attributed to the actor for that
particular action. A missing attribution leaves the reason open. An instrument,
when present, identifies what the actor used.

### Worked example for the proposed base vocabulary

On stage Anna hands Boris a letter. The domain declares the giver as subject
and the recipient as object. The letter is the item transferred.

| Query about this handover | Expected answer |
| --- | --- |
| Who is the subject? Who is the actor? | Both resolve to the same entity, Anna. |
| Who is the object? | Boris. |
| What changes for Anna? | Her held items include the letter before the handover and exclude it afterwards. |
| What changes for Boris? | His held items exclude the letter before the handover and include it afterwards. |
| Why did Anna do this? | The example supplies no motive. The action and its consequence are still expressible. |

Both property changes can be read from a single update of the letter's holder
from Anna to Boris. A consumer storing this relation once can derive both
participants' held items. The model describes the effect independently of the
storage layout.

The foundation acceptance target is to express these queries with only a
foundation import. The executable casting replay above currently checks the
seat occupancy delta with eventcore-v1. It supplies no observation of a change
to Ivan. One design question remains for actions where the model describes a
change on only one side: must every action change an observable property of
each participant, or may its effect on one participant be empty?
