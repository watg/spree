# Provides a page object for the taxon index view
class IndexPageFacade
  include IndexableInterface
  attr_reader :context, :taxon, :page

  def initialize(taxon: taxon, context: context, page: page, per_page: per_page)
    @taxon = taxon
    @context = context
    @page = page
    @per_page = per_page
    @preloader = ActiveRecord::Associations::Preloader.new
  end

  def available_suites?
    number_of_suites > 0
  end

  def suites
    @suites ||= begin
                  paginated_suites = Kaminari.paginate_array(fetch_suites)
                  found_suites = paginated_suites.page(curr_page).per(per_page)
                  if found_suites.empty? && curr_page > 1
                    found_suites = paginated_suites.page(1).per(per_page)
                  end
                  found_suites
                end
  end

  def suites_with_details
    @preloader.preload(suites, [:image, :target])
    suites
  end

  def num_pages
    @num_pages ||= (number_of_suites.to_f / per_page).ceil
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

  def title
    taxon.title
  end

  private

  def number_of_suites
    @number_of_suites ||= fetch_suites.count
  end

  def fetch_suites
    @fetch_suites ||= Spree::Suite.joins(:classifications, :tabs).includes(:tabs)
                      .merge(Spree::Classification.where(taxon_id: taxon.try(:id)))
                      .references(:classifications).to_a
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
