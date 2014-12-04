module Spree
  class SuitesController < Spree::StoreController

    rescue_from ActionController::UnknownFormat, with: :render_404
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404

    def show
      @suite = Suite.find_by!(permalink: params[:id])
      @tabs = @suite.tabs

      if @tabs.size > 0
        @selected_tab = @tabs.detect { |tab| tab.tab_type == params[:tab] }

        unless @selected_tab
          redirect_to spree.suite_url(id: @suite, tab: @tabs.first.tab_type)
        end

        @selected_tab = @tabs.first unless @selected_tab && @selected_tab.product_id
        @context = { currency: current_currency, target: @suite.target, device: device }
      else
        flash[:notice] = Spree.t("the_page_you_requested_no_longer_exists")
        redirect_to(:back)
      end
    end

  private

    def accurate_title
      if @suite
        @suite.meta_title.blank? ? @suite.name : @suite.meta_title
      else
        super
      end
    end

  end
end
