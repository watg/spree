module Search
  # Base search class for finding suites
  class Base
    attr_reader :keywords, :page, :per_page

    def initialize(params)
      @keywords = params.key?(:keywords) ? params[:keywords] : nil
      @page = params.key?(:page) && params[:page].to_i > 0 ? params[:page] : 1
      @per_page = calc_per_page(params)
    end

    def results
      @results ||= Kaminari.paginate_array(suites).page(page).per(per_page)
    end

    def num_pages
      (suites.length.to_i + per_page.to_i - 1) / per_page.to_i
    end

    private

    def calc_per_page(params)
      if params.key?(:per_page) && params[:per_page].to_i > 0
        params[:per_page].to_i
      else
        IndexableInterface::PER_PAGE
      end
    end

    # sanitize and convert the keywords for a tsquery
    def prepare_keywords
      sanitized_keywords = keywords.gsub(/[\\,']/, "")
      ActiveRecord::Base.send(:sanitize_sql_array,
                              ["(to_tsquery('english', :q) || to_tsquery('simple', :q))",
                               q: ActiveRecord::Base.sanitize(sanitized_keywords.split.join("&"))]
      )
    end

    def suites
      @suites ||= filtered_suites.to_a
    end

    def filtered_suites
      scoped_suites = Spree::Suite.indexable.joins(:tabs)
      return scoped_suites.select("DISTINCT ON (spree_suites.id) spree_suites.*") if keywords.blank?
      # Wrap the query in a subquery, allowing the use of order on all fields
      prepared_keywords = prepare_keywords
      subquery = scoped_suites.select("DISTINCT ON (spree_suites.id) spree_suites.*,
                ts_rank(document, #{prepared_keywords}) AS rank")
                 .joins(:indexed_search)
                 .where("indexed_searches.document @@ #{prepared_keywords}").to_sql
      Spree::Suite.select("spree_suites.*").from("(#{subquery}) spree_suites")
        .order("rank desc")
    end
  end
end
