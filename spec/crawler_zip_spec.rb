# frozen_string_literal: true

require "tmpdir"
require "zip"

# Regression: rubyzip 3 removed Zip::File::CREATE, so the crawler's zip step
# raised NameError in CI. Run the crawler's own zip block against the bundled
# rubyzip, so an API change surfaces here and not in the daily crawl.
RSpec.describe "crawler.rb index-v1.zip step" do
  zip_step = File.read(File.join(REPO_ROOT, "crawler.rb"), encoding: "UTF-8")[
    /^Zip::File\.open\(.*?^end$/m
  ]

  it "is present in crawler.rb" do
    expect(zip_step).not_to be_nil
  end

  it "writes index-v1.zip holding index-v1.yaml" do
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("index-v1.yaml", "- :id: test\n")
        eval(zip_step)

        Zip::File.open("index-v1.zip") do |zip|
          expect(zip.read("index-v1.yaml")).to eq("- :id: test\n")
        end
      end
    end
  end
end
