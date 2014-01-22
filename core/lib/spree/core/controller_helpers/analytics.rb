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
          if user
            cookies[:watgtc]= {value: user.uuid, expires: 1.year.from_now }
          elsif cookies[:watgtc].blank? && try_spree_current_user
            cookies[:watgtc]= { value: try_spree_current_user.uuid, expires: 1.year.from_now } 
          end
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
