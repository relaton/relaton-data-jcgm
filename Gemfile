# frozen_string_literal: true

source "https://rubygems.org"

# Pin psych: 5.3.0 silently breaks the YAML round-trip the index relies on (key
# ordering / quoting differences). Matches relaton-data-oiml / relaton-data-iho.
gem "psych", "~> 5.2.6"

# Pubid::Jcgm (meetings + the bare GUM/VIM-N guides and the Corrigendum suffix,
# plus the flattened `to_hash`/`from_hash` the index is serialized with) is merged
# to pubid `main`, so track it from github over HTTPS (anonymous clone,
# CI-friendly). It is not yet on a released gem, hence the git ref.
gem "pubid", git: "https://github.com/metanorma/pubid.git", branch: "main"

# The JCGM flavor (Relaton::Jcgm::DataFetcher / Bibliography) is NOT yet merged —
# it lives only on the unpushed relaton `feat/jcgm-flavor` worktree, so it must be
# pinned by local path for now. CI cannot resolve this until the flavor merges.
# TODO: swap to `gem "relaton", git: "https://github.com/relaton/relaton.git",
# branch: "main"` once feat/jcgm-flavor ships.
gem "relaton", path: "/work/relaton/relaton/.claude/worktrees/feat/jcgm-flavor"

group :development, :test do
  gem "rspec", "~> 3.13"
end
