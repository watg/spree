require 'spec_helper'

describe Spree::Core::Search::SuitesBase do

  before do
    @taxon = create(:taxon, name: "Ruby on Rails")

    @suite1 = create(:suite, title: "RoR Mug")
    @suite1.taxons << @taxon
    @suite2 = create(:suite, title: "RoR Shirt")
  end

  it "returns all suites by default" do
    params = { :per_page => "" }
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(2)
  end

  it "switches to next page according to the page parameter" do
    @suite3 = create(:suite, title: "RoR Pants")

    params = { :per_page => "2" }
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(2)

    params.merge! :page => "2"
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(1)
  end

  it "uses ransack if scope not found" do
    params = { :per_page => "",
               :search => { "title_not_cont" => "Shirt" }}
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(1)
  end

  it "accepts a current user" do
    user = double
    searcher = described_class.new({})
    searcher.current_user = user
    expect(searcher.current_user).to eql(user)
  end

  it "returns suites matching the keywords using AND logic" do
    params = { :per_page => "", :keywords => "ror mug" }
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(1)
  end

  it "returns suites within taxons matching the keywords" do
    params = { :per_page => "", :keywords => "Rails" }
    searcher = described_class.new(params)
    expect(searcher.retrieve_suites.count).to eq(1)
  end
end
