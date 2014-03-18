module Spree
  class UpdateAllPersonalisationService < Mutations::Command
    required do
      duck :params 
    end

    def execute
      ActiveRecord::Base.transaction do
        params.each do |id, attributes|
          personalisation = Spree::Personalisation.find(id)

          # Delete the colour key for now, as it is an array and does not play well 
          # with hstore and update_attributes
          colours = attributes.delete('colours')
          personalisation.assign_attributes( attributes )
          if colours
            personalisation.colours = colours.map(&:to_i).join(',')
          end
          personalisation.save
        end
      end
    rescue Exception => e
      Rails.logger.error "[UpdateAllPersonalisationsService] #{e.message} -- #{e.backtrace}"
      add_error(:product, :exception, e.message)
    end

  end
end
