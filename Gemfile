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

# The JCGM flavor (Relaton::Jcgm::DataFetcher / Bibliography) is now merged to
# relaton `main`, so track it from github over HTTPS (anonymous clone,
# CI-friendly). It is not yet on a released gem, hence the git ref.
gem "relaton", git: "https://github.com/relaton/relaton.git", branch: "main"

group :development, :test do
  gem "rspec", "~> 3.13"
end
