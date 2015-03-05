module Spree
  module Admin
    class ShippingMethodDurationsController < ResourceController
      def index
      end

      def permitted_resource_params
        params.require(object_name).permit(:description)
      end
    end
  end
end
