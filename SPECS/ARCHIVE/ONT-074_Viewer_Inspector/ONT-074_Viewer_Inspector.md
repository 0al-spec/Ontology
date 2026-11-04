# ONT-074 — Follow an action from the Viewer inspector

The ONT-073 export carries the relationship action and each typed field target.
A reader currently has to expand declaration JSON to find them.

1. On an action-bearing relation, identify its Subject, Action and Object. Follow the action to its declaration.
2. Read an instance-reference field on the action and select the declared target class, using its qualified identity.
3. Keep ordinary binary relations readable, handle multiple object types, and preserve existing filter and selection behavior. A target without a loaded declaration remains readable.
4. Exercise both clicks on the repository membership example in Chromium. The compiler, serialized graph and canvas edge model remain compatible.
