# Provides a page object for the taxon index view
class IndexPage
  include IndexableInterface

  def initialize(taxon: taxon, context: context, page: page, per_page: per_page)
    @taxon = taxon
    @page = page
    @per_page = per_page
    # @device = context[:device]
    # @currency = context[:currency]
  end

  def suites
    @suites ||= begin
      selector = fetch_suites

      # Ensure that if for some reason the page you are looking at is
      # now empty then re-run the query with the first page
      found_suites = selector.page(curr_page).per(per_page)
      if found_suites.empty? and curr_page > 1
        found_suites = selector.page(1).per(per_page)
      end
      found_suites
    end
  end

  def num_pages
    @num_pages ||= fetch_suites.count.to_f / per_page
    @num_pages.ceil
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
    Spree::Suite.joins(:classifications, :tabs).includes(:image, :tabs, :target)
      .merge(Spree::Classification.where(taxon_id: taxon.try(:id)))
      .references(:classifications)
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
