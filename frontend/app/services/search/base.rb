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
      (filtered_suites.length.to_i + @per_page.to_i - 1) / @per_page.to_i
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
      ActiveRecord::Base.send(:sanitize_sql_array,
                              [
                                "to_tsquery('english', ?)",
                                ActiveRecord::Base.sanitize(query.split.join("&"))
                              ]
      )
    end

    def filtered_suites(scoped_suites = Spree::Suite.active, query = @keywords)
      return scoped_suites if query.blank?
      scoped_suites.select("DISTINCT ON (spree_suites.id) spree_suites.*,
                ts_rank(document, #{prepare_query(query)}) AS rank")
        .joins(:indexed_search)
        .where("indexed_searches.document @@ #{prepare_query(query)}")
        .order("spree_suites.id, rank desc")
    end
  end
end
