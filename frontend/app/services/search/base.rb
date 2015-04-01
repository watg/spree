module Search
  # Base search class for finding suites
  class Base
    def initialize(params)
      @keywords = params.key?(:keywords) ? params[:keywords] : nil
      @page = params.key?(:page) && params[:page].to_i > 0 ? params[:page] : 1
      @per_page = calc_per_page(params)
    end

    def results
      filtered_suites.page(@page).per(@per_page)
    end

    def num_pages
      (filtered_suites.count(:all).to_i + @per_page.to_i - 1) / @per_page.to_i
    end

    private

    def calc_per_page(params)
      @per_page = if params.key?(:per_page) && params[:per_page].to_i > 0
                    params[:per_page].to_i
                  else
                    Spree::Config[:products_per_page].to_i
                  end
    end

    def prepare_query(query)
      ActiveRecord::Base.sanitize(query).split.join("&")
    end

    def filtered_suites(scoped_suites = Spree::Suite.active, query = @keywords)
      unless query.blank?
        query = "to_tsquery('english',#{prepare_query(query)})"
        scoped_suites = scoped_suites
                        .joins(:indexed_search)
                        .select("spree_suites.*, ts_rank(document, #{query}) AS rank")
                        .where("indexed_searches.document @@ #{query}").uniq
      end
      scoped_suites
    end
  end
end
