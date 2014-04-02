module Spree
  class OproxyController < Spree::StoreController
    include Olapic::Stream
    protect_from_forgery
    def show
      render text: olapic_data(params[:url])
    end
  end
end
