module Search
  # Base search class for finding suites
  class Base
    def initialize(params)
      prepare_properties(params)
    end

    def results
      @results ||= filter_suites(Spree::Suite.active, @keywords).page(@page).per(@per_page)
    end

    def num_pages
      (results.count.to_i + @per_page.to_i - 1) / @per_page.to_i
    end

    private

    def prepare_properties(params)
      @keywords = params.key?(:keywords) ? params[:keywords] : nil
      @per_page = if params.key?(:per_page)
                    params[:per_page].to_i
                  else
                    Spree::Config[:products_per_page].to_i
                  end
      @page = params.key?(:page) && params[:page].to_i > 0 ? params[:page] : 1
    end

    def prepare_query(query)
      ActiveRecord::Base.sanitize(query).split.join("&")
    end

    def filter_suites(scoped_suites, query)
      unless query.blank?
        query = "to_tsquery('english','#{query.split.join('&')}')"
        scoped_suites = scoped_suites
                        .joins(:indexed_search)
                        .select("*, ts_rank(document, #{query}) AS rank")
                        .where("indexed_searches.document @@ #{query}")
      end
      scoped_suites
    end
  end
end
