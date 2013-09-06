module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html
      around_filter :get_report_class, only: [ :report, :create, :download, :refresh ] 

      AVAILABLE_REPORTS = {
        :sales_total => { :name => Spree.t(:sales_total), :description => Spree.t(:sales_total_description) },
        :order_summary => { :name => Spree.t(:order_summary), :description => Spree.t(:order_summary_description) },
        :line_sales => { :name => Spree.t(:line_sales), :description => Spree.t(:line_sales_description) },
        :stock => { :name => Spree.t(:stock), :description => Spree.t(:stock_description) },
      }.with_indifferent_access

      def index
        @reports = AVAILABLE_REPORTS
      end

      def report
      end

      def refresh
        @csv_object = @class.find(params[:id])
        render :create 
      end

      def create
        @csv_object = @class.create
        @csv_object.trigger_csv_generation( params )
        flash[:notice] = "We're generating your CSV file. Refresh the page in a minute or so to download it."
      end


      def download
        send_file @class.find(params[:id]).csv_file_file_name, :type=>"application/csv", :x_sendfile=>true
      end

      private

      def get_report_class
        @name = params[:name]
        if AVAILABLE_REPORTS.has_key?( @name ) 
          @class = "Spree::#{@name.camelize}Report".constantize
          yield
        else
          redirect_to spree.admin_reports_path 
        end
      end

      def model_class
        Spree::Admin::ReportsController
      end

    end
  end
end
