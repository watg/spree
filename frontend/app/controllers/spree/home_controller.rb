module Spree
  class HomeController < Spree::StoreController
    respond_to :html

    def index
      redirect_to '/'
    end
  end
end
