# Provides an object for the search view
class SearchPage
  attr_reader :currency

  delegate :suites, :num_pages, to: :searcher

  def initialize(context: context, searcher: searcher, page: page, per_page: per_page)
    # @device = context[:device]
    # @user = context[:user]
    # @currency = context[:currency]
  end

end
