module Admin
  class ShippingMethodPresenter < Spree::BasePresenter
    presents :shipping_method
    delegate :id, :name, :admin_name, to: :shipping_method

    def display_name
      admin_name.present? ? "#{name} (#{admin_name})" : name
    end

  end
end
