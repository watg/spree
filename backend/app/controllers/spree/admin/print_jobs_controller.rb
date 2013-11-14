module Spree
  module Admin

    class PrintJobsController < Spree::Admin::BaseController
      def index
        @curr_page, @per_page = pagination_helper(params)
        @print_jobs = Spree::PrintJob.order("print_time DESC").page(@curr_page).per(@per_page)
      end

      def show
        print_job = Spree::PrintJob.find(params[:id])
        filename = "#{print_job.job_type}.pdf"
        send_data(print_job.pdf, disposition: :inline, filename: filename, type: "application/pdf")
      end

      private

      def pagination_helper( params )
        per_page = params[:per_page].to_i
        per_page = per_page > 0 ? per_page : Spree::Config[:orders_per_page]
        page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
        curr_page = page || 1
        [curr_page, per_page]
      end

    end

  end
end
