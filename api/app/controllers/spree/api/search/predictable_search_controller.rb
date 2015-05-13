module Spree
  module Api
    module Search
      # Rest Interface for the predictable search
      class PredictableSearchController < Api::BaseController
        skip_before_filter :authenticate_user
        def search
          response = ::Api::Search::PredictableSearch.
            run!(keywords: params[:keywords], view: view_context)
          render json: response.to_json
        end
      end
    end
  end
end
