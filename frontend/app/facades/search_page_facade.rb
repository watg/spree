# Provides a page for the index view
class SearchPageFacade
  include IndexableInterface
  attr_reader :searcher
  attr_reader :context
  delegate :num_pages, to: :searcher

  def initialize(context: context, searcher: searcher)
    @searcher = searcher
    @context = context
  end

  def suites
    searcher.results
  end

  def title
    "Search results"
  end
end
