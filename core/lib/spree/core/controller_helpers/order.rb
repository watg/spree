# maybe require the file in an engine instead
require 'spree/core/controller_helpers/currency_helpers'

module Spree
  module Core
    module ControllerHelpers
      module Order
        extend ActiveSupport::Concern
        include CurrencyHelpers

        def self.included(base)
          base.class_eval do
            helper_method :simple_current_order
            helper_method :current_order
            helper_method :current_currency
            before_filter :set_current_order
          end
        end

        # Used in the link_to_cart helper.
        def simple_current_order
          @order ||= Spree::Order.find_by(id: session[:order_id], currency: current_currency)
        end

        # The current incomplete order from the session for use in cart and during checkout
        def current_order(options = {})
          options[:create_order_if_necessary] ||= false
          options[:lock] ||= false


          return @current_order if @current_order

          if session[:order_id]
            current_order = Spree::Order.includes(:adjustments).lock(options[:lock]).find_by(id: session[:order_id], currency: current_currency)
            @current_order = current_order unless current_order.try(:completed?)
          end

          if options[:create_order_if_necessary] and (@current_order.nil? or @current_order.completed?)
            @current_order = Spree::Order.new(currency: current_currency)
            @current_order.user ||= try_spree_current_user
            # See issue #3346 for reasons why this line is here
            @current_order.created_by ||= try_spree_current_user
            @current_order.save!

            # make sure the user has permission to access the order (if they are a guest)
            if try_spree_current_user.nil?
              session[:access_token] = @current_order.token
            end
          end

          if @current_order
            @current_order.last_ip_address = ip_address
            session[:order_id] = @current_order.id
            return @current_order
          end
        end

        def associate_user
          @order ||= current_order
          if try_spree_current_user && @order
            @order.associate_user!(try_spree_current_user) if @order.user.blank? || @order.email.blank?
          end

          session[:guest_token] = nil
        end

        def set_current_order
          if user = try_spree_current_user
            last_incomplete_order = user.last_incomplete_spree_order
            if session[:order_id].nil? && last_incomplete_order
              session[:order_id] = last_incomplete_order.id
            elsif current_order && last_incomplete_order && current_order != last_incomplete_order
              # This will ensure that any redeemed gift cards that are not on completed orders
              # will be reactivated
              last_incomplete_order.reactivate_gift_cards
              current_order.merge!(last_incomplete_order, user)
            end
          end
        end

        def current_currency
          # from multi currency 
          # ensure session currency is supported
          #
          if session.key?(:currency) && supported_currencies.map(&:iso_code).include?(session[:currency])
            session[:currency]
          else
            Spree::Config[:currency]
          end
          # from multi currency 
        end

        def ip_address
          request.remote_ip
        end
      end
    end
  end
end
