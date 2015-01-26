module Spree
  class ProductPagesController < Spree::StoreController

    rescue_from ActionController::UnknownFormat, with: :render_404

    before_filter :redirect_to_suites_pages, :only => :show

    def show
    end

  private

    def redirect_to_suites_pages
      permalink = params.delete(:id)
      params.delete(:controller)
      params.delete(:action)
      outcome = Spree::SuitePageRedirectionService.run(permalink: permalink, params: params)
      if outcome.valid?
        result = outcome.result
        redirect_to result[:url], status: result[:http_code]
      else
        redirect_to spree.root_path
      end
    end

  end
end
