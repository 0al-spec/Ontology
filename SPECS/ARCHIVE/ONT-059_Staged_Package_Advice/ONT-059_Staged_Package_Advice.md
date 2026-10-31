# ONT-059 — Staged Package Advice

An author can stage a package change and forget to run the compiler. At commit time show the same diagnostics as `ontologyc check` for staged regular YAML packages. The notification includes the original path, severity, diagnostic code, field and message. A valid package without findings and a commit containing only unrelated files are quiet. Errors in a package or the advisory itself leave the commit available.

Use a repository-local Git hook alongside existing hooks. Read the active index, including partially staged files, new files and rename destinations. Treat unrelated YAML and symlinks separately. Do not build tools, fetch packages, write generated files, edit the index or change the strict check in this path. Deliver the check in the same executable as the compiler. Exercise it using real Git commits, both on valid and invalid input, and check that an independent failing hook keeps its ordinary behavior.
