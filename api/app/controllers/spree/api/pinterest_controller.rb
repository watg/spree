module Spree
  module Api
    class PinterestController < Spree::Api::BaseController
      respond_to :json
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
    
    end

  end
end
