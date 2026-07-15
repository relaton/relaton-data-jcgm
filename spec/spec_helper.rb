# frozen_string_literal: true

require "yaml"
require "relaton"
require "relaton/jcgm"

RSpec.configure do |config|
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Repo root (the crawler writes index-v1.yaml / data / static here).
REPO_ROOT = File.expand_path("..", __dir__)
