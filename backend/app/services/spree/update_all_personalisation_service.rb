module Spree
  class UpdateAllPersonalisationService < Mutations::Command
    required do
      duck :params 
    end

    def execute
      ActiveRecord::Base.transaction do
        params.each do |id, attributes|
          personalisation = Spree::Personalisation.find(id)
          personalisation.update_attributes( attributes )
        end
      end
    rescue Exception => e
      Rails.logger.error "[UpdateAllPersonalisationsService] #{e.message} -- #{e.backtrace}"
      add_error(:product, :exception, e.message)
    end

  end
end
