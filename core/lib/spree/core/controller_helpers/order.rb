module Spree
  module Core
    module ControllerHelpers
      module Order
        extend ActiveSupport::Concern
        include CurrencyHelpers

        included do
            helper_method :current_order
            helper_method :current_currency
            before_filter :set_current_order
        end

        # The current incomplete order from the session for use in cart and during checkout
        def current_order(create_order_if_necessary = false)

          return @current_order if @current_order
          if session[:order_id]
            current_order = Spree::Order.find_by_id_and_currency(session[:order_id], current_currency, :include => :adjustments)
            @current_order = current_order unless current_order.try(:completed?)
          end

          if create_order_if_necessary and (@current_order.nil? or @current_order.completed?)
            @current_order = Spree::Order.new(:currency => current_currency)
            @current_order.save!

            # make sure the user has permission to access the order (if they are a guest)
            if try_spree_current_user.nil?
              session[:access_token] = @current_order.token
            end
          end
         
          if @current_order
            # Try and add the last billing and shipping address for this user
            @current_order.user ||= try_spree_current_user
            @current_order.last_ip_address = ip_address
            session[:order_id] = @current_order.id
            return @current_order
          end
        end

        def associate_user
          @order ||= current_order
          if try_spree_current_user && @order
            if @order.user.blank? || @order.email.blank?
              @order.associate_user!(try_spree_current_user)
            end
          end

          # This will trigger any "first order" promotions to be triggered
          # Assuming of course that this session variable was set correctly in
          # the authentication provider's registrations controller
          if session[:spree_user_signup] && @order
            fire_event('spree.user.signup', :user => try_spree_current_user, :order => @order)
            session[:spree_user_signup] = nil
          end

          session[:guest_token] = nil
        end

        def set_current_order
          if user = try_spree_current_user
            last_incomplete_order = user.last_incomplete_spree_order
            if session[:order_id].nil? && last_incomplete_order
              session[:order_id] = last_incomplete_order.id
            elsif current_order(true) && last_incomplete_order && current_order != last_incomplete_order
              current_order.merge!(last_incomplete_order)
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
          request.env['HTTP_X_REAL_IP'] || request.env['REMOTE_ADDR']
        end
      end
    end
  end
end
