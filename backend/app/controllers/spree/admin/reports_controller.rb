module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html

      AVAILABLE_REPORTS = {
        #:sales_total => { :name => Spree.t(:sales_total), :description => Spree.t(:sales_total_description) },
        :order_summary => { :name => Spree.t(:order_summary), :description => Spree.t(:order_summary_description), date: true },
        :list_sales => { :name => Spree.t(:list_sales), :description => Spree.t(:list_sales_description), date: true },
        :stock => { :name => Spree.t(:stock), :description => Spree.t(:stock_description), date: false },
        :gift_card => { :name => "Gift Card", :description => "Export all registered gift cards", date: false },
        :gang_sales => { :name => Spree.t(:gang_sales), :description => Spree.t(:gang_sales_description), date: true },
        :tara_stiles => { :name => "Tara Stiles",  :description => "Get sales data for TS Hoodie, Tree Huggers, Hot Top, Shatki Shorts, Strala T-Shirt", date: true },
        :rachel_rutt => { :name => "Rachel Rutt",  :description => "Get a report about Rachel Rutt Sales", date: true },
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
        # kind of feels the report should be created here and passed in
        @report.trigger_csv_generation(@name, params[:q])
        flash[:notice] = "We're generating your CSV file. Refresh the page in a minute or so to download it."
      end


      # TODO: provide link in the view to download once job has finished
      def download
        @report = Spree::Report.find(params[:id])
        send_data @report.data, :filename => @report.filename
      end

      private

      def model_class
        Spree::Admin::ReportsController
      end

    end
  end
end
