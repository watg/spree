# Provides a page for the index view
class SearchPage
  include IndexableInterface
  attr_reader :searcher

  delegate :num_pages, to: :searcher

  def initialize(context: context, searcher: searcher, page: page, per_page: per_page)
    @searcher = searcher
    # @device = context[:device]
    # @user = context[:user]
    # @currency = context[:currency]
  end

  def suites
    searcher.results
  end

end
