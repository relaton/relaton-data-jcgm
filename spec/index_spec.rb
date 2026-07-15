# frozen_string_literal: true

# Validates the generated dataset (run `bundle exec ruby crawler.rb` first).
RSpec.describe "relaton-data-jcgm index" do
  index_path = File.join(REPO_ROOT, "index-v1.yaml")

  # Rows keyed by symbol :id/:file (Relaton::Index format); inner id keys are
  # strings (`_type`, `number`, ...).
  let(:rows) { YAML.safe_load(File.read(index_path), permitted_classes: [Symbol]) }

  it "has been generated" do
    expect(File).to exist(index_path)
    expect(File).to exist(File.join(REPO_ROOT, "index-v1.zip"))
  end

  it "stores every row as a Pubid::Jcgm identifier (no bespoke hashes)" do
    types = rows.map { |r| r[:id]["_type"] }
    expect(types).to all(match(%r{\Apubid:jcgm:}))
    expect(types.uniq.sort).to eq(
      %w[pubid:jcgm:corrigendum pubid:jcgm:guide
         pubid:jcgm:gum-guide pubid:jcgm:meeting],
    )
  end

  # Meetings are harvested from live metanorma/bipm-data-outcomes on a daily
  # cron, so their count grows as BIPM publishes new proceedings. The 11 guides
  # live in this repo's static/ dir, so that count is fixed: 9 guide (incl. the
  # bare "JCGM GUM" and "JCGM VIM-3") + 1 gum-guide (GUM-6:2020) + 1 corrigendum
  # (200:2008 Corrigendum).
  it "indexes every meeting plus all 11 static guides" do
    by_type = rows.group_by { |r| r[:id]["_type"] }
    meetings = by_type["pubid:jcgm:meeting"] || []
    guides = by_type["pubid:jcgm:guide"] || []
    gum_guides = by_type["pubid:jcgm:gum-guide"] || []
    corrigenda = by_type["pubid:jcgm:corrigendum"] || []

    expect(meetings.size).to be >= 16
    expect(guides.size).to eq(9)
    expect(gum_guides.size).to eq(1)
    expect(corrigenda.size).to eq(1)
    expect(rows.size)
      .to eq(meetings.size + guides.size + gum_guides.size + corrigenda.size)
  end

  it "indexes every static guide file (none skipped)" do
    files = rows.map { |r| r[:file] }
    Dir[File.join(REPO_ROOT, "static/jcgm/*.yaml")].each do |path|
      rel = "static/jcgm/#{File.basename(path)}"
      expect(files).to include(rel)
    end
  end

  describe "pubid round-trip" do
    it "reconstructs and re-renders every row stably" do
      rows.each do |r|
        id = Pubid::Jcgm::Identifier.from_hash(r[:id])
        rendered = id.to_s
        expect(rendered).to be_a(String)
        # Re-parsing the rendered id yields the same string (stable round-trip).
        expect(Pubid::Jcgm.parse(rendered).to_s).to eq(rendered)
      end
    end

    # The stored ids intentionally encode the JCGM/BIPM generator's naive
    # last-digit ordinal (no 11/12/13 teens exception), because that is what the
    # real docnumbers print ("JCGM 11st Meeting"). If pubid ever "fixes" the
    # ordinal to 11th/12th/13th, this expectation (and the stored data) change
    # together — update both.
    it "renders meeting ordinals with the naive 11st/12nd/13rd rule" do
      rendered = rows
        .select { |r| r[:id]["_type"] == "pubid:jcgm:meeting" }
        .map { |r| Pubid::Jcgm::Identifier.from_hash(r[:id]).to_s }
      expect(rendered).to include("JCGM 11st Meeting (2006)")
      expect(rendered).to include("JCGM 12nd Meeting (2007)")
      expect(rendered).to include("JCGM 13rd Meeting (2008)")
      expect(rendered).to include("JCGM 17th Meeting (2012)")
    end
  end

  it "reloads through pubid_class without an InvalidIndexError" do
    Relaton::Index.close(:jcgm) if Relaton::Index.respond_to?(:close)
    idx = nil
    expect do
      Dir.chdir(REPO_ROOT) do
        idx = Relaton::Index.find_or_create(
          :jcgm, file: "index-v1.yaml",
          pubid_class: Pubid::Jcgm::Identifier
        )
        idx.index # force deserialization
      end
    end.not_to raise_error
    expect(idx.index.size).to eq(rows.size)
  end

  describe "records load as Relaton::Jcgm items" do
    it "loads a meeting record" do
      yaml = File.read(File.join(REPO_ROOT, "data/jcgm/meeting/17.yaml"))
      item = Relaton::Jcgm::Item.from_yaml(yaml)
      expect(item.docidentifier.map(&:content))
        .to include("JCGM 17th Meeting (2012)")
    end

    it "loads a guide record" do
      yaml = File.read(File.join(REPO_ROOT, "static/jcgm/200-2012.yaml"))
      item = Relaton::Jcgm::Item.from_yaml(yaml)
      expect(item.docidentifier.map(&:content)).to include("JCGM 200:2012")
    end
  end
end
