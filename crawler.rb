# frozen_string_literal: true

# Rebuilds the JCGM dataset consumed by Relaton::Jcgm::Bibliography.
#
# Two record sets feed index-v1.yaml:
#   * meeting proceedings — harvested by Relaton::Jcgm::DataFetcher from a local
#     checkout of metanorma/bipm-data-outcomes into data/jcgm/meeting/*.yaml.
#   * curated guide/GUM/VIM records — hand-maintained YAMLs in this repo's
#     static/ dir. The DataFetcher deliberately leaves the "which static files"
#     policy to the data repo, exposing the public, guarded #add_to_index so the
#     guides go through the same pubid-backed (`_type: pubid:jcgm:*`), sorted
#     indexing path the meetings use.
#
# Must run from the repo root: the meeting glob (./bipm-data-outcomes/...) and the
# static glob (./static/...) are CWD-relative, and each row's :file is stored
# verbatim.
require "fileutils"
require "yaml"

# The meeting source is a public metanorma repo. CI clones it fresh; local dev
# usually symlinks it (see .gitignore). Clone only when neither is present.
unless File.exist?("bipm-data-outcomes")
  system("git", "clone", "https://github.com/metanorma/bipm-data-outcomes",
         "bipm-data-outcomes") || abort("failed to clone bipm-data-outcomes")
end

require "relaton/jcgm/data_fetcher"

# Start clean so removed sources never leave orphan files/rows behind.
FileUtils.rm_rf "data"
FileUtils.rm_f Dir.glob("index-v1.*")

# Meetings: writes data/jcgm/meeting/*.yaml and their index rows, then saves.
Relaton::Jcgm::DataFetcher.fetch("bipm-data-outcomes")

# Static guides: index each through the gem's public guarded add_to_index. The
# fetcher shares the pooled :jcgm index (already holding the meeting rows), so
# this appends the guides; index.save then re-writes the sorted index.
fetcher = Relaton::Jcgm::DataFetcher.new("data", "yaml")
Dir["static/**/*.{yml,yaml}"].sort.each do |file|
  doc = YAML.safe_load(File.read(file, encoding: "UTF-8"),
                       permitted_classes: [Date, Time])
  fetcher.add_to_index doc["docnumber"], file
end
fetcher.index.save

# index-v1.yaml holds the structured Pubid::Jcgm identifier index (rows keyed by
# `_type: pubid:jcgm:*`) — this flavor has no separate flat v1 / structured v2
# split. index.save writes only the .yaml, but Bibliography downloads
# index-v1.zip, so produce the zip here (rubyzip is a relaton runtime dependency).
require "zip"
Zip::File.open("index-v1.zip", Zip::File::CREATE) do |zip|
  zip.add "index-v1.yaml", "index-v1.yaml"
end

puts "Wrote index-v1.yaml + index-v1.zip"
