module Spree
  module Api
    class PinterestController < Spree::Api::BaseController
      skip_before_filter :check_for_user_or_api_key
      skip_before_filter :authenticate_user
      
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
