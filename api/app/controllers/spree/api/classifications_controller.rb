module Spree
  module Api
    class ClassificationsController < Spree::Api::BaseController
      def update
        authorize! :update, Suite
        authorize! :update, Taxon
        classification = Spree::Classification.find_by(
          :suite_id => params[:suite_id],
          :taxon_id => params[:taxon_id]
        )
        # Because position we get back is 0-indexed.
        # acts_as_list is 1-indexed.
        classification.insert_at(params[:position].to_i + 1)
        render :nothing => true
      end
    end
  end
end