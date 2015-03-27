module Search
  # Base search class for finding suites
  class Base
    attr_accessor :properties
    attr_accessor :current_user
    attr_accessor :current_currency

    def initialize(params)
      @current_currency = Spree::Config[:currency]
      @properties = {}
      prepare(params)
    end

    def retrieve_suites
      @suites_scope = get_base_scope
      curr_page = page || 1

      @suites = @suites_scope
      @suites = @suites.page(curr_page).per(per_page)
    end

    def method_missing(name)
      if @properties.has_key? name
        @properties[name]
      else
        super
      end
    end

  protected
    def get_base_scope
      base_scope = Spree::Suite.active
      # base_scope = base_scope.in_taxon(taxon) unless taxon.blank? # not used at present
      base_scope = get_suites_conditions_for(base_scope, keywords)
      # base_scope = add_search_scopes(base_scope) # not used at present
      base_scope
    end

    def add_search_scopes(base_scope)
      search.each do |name, scope_attribute|
        scope_name = name.to_sym
        if base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
          base_scope = base_scope.send(scope_name, *scope_attribute)
        else
          base_scope = base_scope.merge(Spree::Suite.ransack({scope_name => scope_attribute}).result)
        end
      end if search
      base_scope
    end

    # method should return new scope based on base_scope
    def get_suites_conditions_for(base_scope, query)
      unless query.blank?
        query = sanitize(query)
        base_scope = base_scope.joins(:taxons)
          .where("to_tsvector('english', spree_taxons.name || ' ' || spree_suites.title) @@ to_tsquery(:q)", q: query)
      end
      base_scope
    end

    def prepare(params)
      @properties[:taxon] = params[:taxon].blank? ? nil : Spree::Taxon.find(params[:taxon])
      @properties[:keywords] = params[:keywords]
      @properties[:search] = params[:search]

      per_page = params[:per_page].to_i
      @properties[:per_page] = per_page > 0 ? per_page : Spree::Config[:products_per_page]
      @properties[:page] = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
    end


    def sanitize(query)
      join_with_and_logic(query.split)
    end

    def join_with_and_logic(query)
      query.join('&')
    end

  end
end
