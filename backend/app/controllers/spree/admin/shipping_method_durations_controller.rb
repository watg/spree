module Spree
  module Admin
    class ShippingMethodDurationsController < ResourceController
      def index
      end

      def permitted_resource_params
        params.require(object_name).permit(:min, :max)
      end
    end
  end
end
