# ONT-072 follow-up — teach executable action modeling

Extend the portable action-modeling skill with the released 0.7.0 authoring
contract. Verify the example through the released compiler and the existing
typed appointments consumer. Keep conceptual modeling available on its own.

The letter-transfer example exercises a third participant. Ontology 0.7.0
checked the package and generated a TypeScript SDK with a required `letterId`
string. The consuming application resolves that ID to a particular letter.
