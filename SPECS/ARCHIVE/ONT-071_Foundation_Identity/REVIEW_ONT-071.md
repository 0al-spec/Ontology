# Review of ONT-071

The compiler resolves the package identity before choosing a default namespace.
This preserves legacy imports that omit their namespace and checks both identities
against the same member inventory. Hypercode generation uses a distinct local
alias when the authored package itself owns ont. The historical SDK fixtures and
instance graph profile digests remain reproducible. Consumers with a pinned
foundation catalog should adopt the new catalog in their own versioned update.
