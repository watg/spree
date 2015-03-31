# Provides a page object for the taxon index view
class IndexPage
  include Indexable

  def initialize(taxon: taxon, context: context, page: page, per_page: per_page)
    @taxon = taxon
    @page = page
    @per_page = per_page
    # @device = context[:device]
    # @currency = context[:currency]
  end

  def suites
    @suites ||= fetch_suites
  end

  def num_pages
    @num_pages ||= suites.count
  end

  def meta_description
    taxon.meta_description
  end

  def meta_keywords
    taxon.meta_keywords
  end

  def meta_title
    taxon.meta_title.present? ? taxon.meta_title : taxon.title
  end

  private

  attr_reader :taxon

  def fetch_suites
    selector = Spree::Suite.joins(:classifications, :tabs).includes(:image, :tabs, :target)
      .merge(Spree::Classification.where(taxon_id: taxon.id))
      .references(:classifications)

    # Ensure that if for some reason the page you are looking at is
    # now empty then re-run the query with the first page
    suites = selector.page(curr_page).per(per_page)
    if suites.empty? and curr_page > 1
      params[:page] = 1
      suites = selector.page(curr_page).per(per_page)
    end
    suites
  end

  def per_page
    per_page = @per_page.to_i
    (per_page <= 0) ? PER_PAGE : per_page
  end

  def curr_page
    curr_page = @page.to_i
    (curr_page <= 0) ? 1 : curr_page
  end
end
