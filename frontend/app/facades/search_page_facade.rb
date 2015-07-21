# Provides a page for the index view
class SearchPageFacade
  include IndexableInterface
  attr_reader :searcher
  attr_reader :context
  delegate :num_pages, to: :searcher

  def initialize(context: context, searcher: searcher)
    @searcher = searcher
    @context = context
    @preloader = ActiveRecord::Associations::Preloader.new
  end

  def suites
    searcher.results
  end

  def suites_with_details
    results = suites
    @preloader.preload(results, [:image, :tabs, :target])
    results
  end

  def available_suites?
    suites.any?
  end

  def title
    "Search results"
  end
end
