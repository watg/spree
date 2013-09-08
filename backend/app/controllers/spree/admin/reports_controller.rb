module Spree
  module Admin
    class ReportsController < Spree::Admin::BaseController
      respond_to :html

      def index
        @reports = Spree::Report.available 
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
