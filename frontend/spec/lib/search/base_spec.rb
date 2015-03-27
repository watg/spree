require 'spec_helper'

module Search
  describe Base do
    let(:suite1) { create(:suite, :with_tab, title: "RoR Mug") }
    let(:suite2) { create(:suite, :with_tab, title: "RoR Shirt") }
    let(:taxon) { create(:taxon, name: "Ruby on Rails") }

    before do
      suite1.taxons << taxon
      suite2.taxons << taxon
    end

    it "returns all suites with tabs by default" do
      suite3 = create(:suite, title: "RoR Shirt2")
      params = {}

      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(2)
    end

    it "switches to next page according to the page parameter" do
      suite3 = create(:suite, :with_tab, title: "RoR Pants")

      params = { :per_page => "2" }
      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(2)

      params.merge! :page => "2"
      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(1)
    end

    # it "uses ransack if scope not found" do
    #   params = { :per_page => "",
    #              :search => { "title_not_cont" => "Shirt" }}
    #   searcher = described_class.new(params)
    #   expect(searcher.retrieve_suites.count).to eq(1)
    # end

    it "accepts a current user" do
      user = double
      searcher = described_class.new({})
      searcher.current_user = user
      expect(searcher.current_user).to eql(user)
    end

    it "returns suites matching the keywords using AND logic" do
      params = { :keywords => "ror mug" }
      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(1)
    end

    it "returns suites within taxons matching the keywords" do
      suite2.taxons = []
      params = {:keywords => "Rails" }
      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(1)
    end

    it "returns suites with keywords matching both suite and taxons" do
      params = {:keywords => "ruby shirt" }
      searcher = described_class.new(params)
      expect(searcher.retrieve_suites.count).to eq(1)
    end
  end
end
