module Spree
  module Api
    class PinterestController < Spree::Api::BaseController
      before_filter :disable_require_login

      def show
        outcome = Spree::PinterestService.run(params)
        
        if outcome.success?
          @pinterest = outcome.result
          respond_with(@pinterest)
        else
          # not_found # just an alternative
          invalid_resource!(outcome)
        end
      end
    
    private

      def disable_require_login
        Spree::Api::Config[:requires_authentication] = false
      end

    end

  end
end
