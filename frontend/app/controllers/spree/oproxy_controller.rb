module Spree
  class OproxyController < Spree::StoreController
    include Olapic::Stream
    protect_from_forgery
    def show
      render text: olapic_data(params[:url], api_params)
    end

    private
    def api_params
      hsh = params.dup
      hsh.delete(:action)
      hsh.delete(:controller)
      hsh
    end
  end
end
