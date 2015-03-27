# Provides an object for the search view
class SearchPage
  attr_reader :params, :currency

  def initialize(context)
    @params = context[:params]
    # @device = context[:device]
    @user = context[:user]
    @currency = context[:currency]
  end

  def suites
    @suites ||= begin
      searcher = build_searcher
      searcher.retrieve_suites.all
    end
  end

  private

  attr_reader :user

  def build_searcher
    Spree::Core::Search::SuitesBase.new(params).tap do |searcher|
      searcher.current_user = user
      searcher.current_currency = currency
    end
  end
end
