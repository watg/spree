module Spree
  module Core
    module ControllerHelpers
      module Analytics
        extend ActiveSupport::Concern
        
        included do
          helper_method :tracking_cookie
          before_filter :set_tracking_cookie
          skip_before_filter :set_tracking_cookie, :only => [:destroy]
        end

        def set_tracking_cookie(user=nil)
          data = {value: nil, expires: 1.year.from_now }
          data[:value] = UUID.generate               if cookies[:watgtc].blank?
          data[:value] = try_spree_current_user.uuid if (try_spree_current_user rescue nil)
          data[:value] = user.uuid                   if user

          cookies[:watgtc]= data unless data[:value].blank?
        end

        def delete_tracking_cookie
          cookies[:watgtc] = nil
        end

        def tracking_cookie
          cookies[:watgtc]
        end
        
      end
    end
  end
end
