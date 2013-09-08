module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html

      AVAILABLE_REPORTS = {
        #:sales_total => { :name => Spree.t(:sales_total), :description => Spree.t(:sales_total_description) },
        :order_summary => { :name => Spree.t(:order_summary), :description => Spree.t(:order_summary_description), date: true },
        :list_sales => { :name => Spree.t(:list_sales), :description => Spree.t(:list_sales_description), date: true },
        :stock => { :name => Spree.t(:stock), :description => Spree.t(:stock_description), date: false },
        :gang_sales => { :name => Spree.t(:gang_sales), :description => Spree.t(:gang_sales_description), date: true },
      }.with_indifferent_access

      def index
        @reports = AVAILABLE_REPORTS
      end

      def report
        @name = params[:name]
      end

      def refresh
        @report = Spree::Report.find(params[:id])
        @name = params[:name]
        render :create 
      end

      def create
        @name = params[:name]
        @report = Spree::Report.create
        @report.trigger_csv_generation(@name, params[:q])
        flash[:notice] = "We're generating your CSV file. Refresh the page in a minute or so to download it."
      end

      def download
        send_file Spree::Report.find(params[:id]).filename, :type=>"application/csv", :x_sendfile=>true
      end

      private

        def model_class
        Spree::Admin::ReportsController
      end

    end
  end
end
