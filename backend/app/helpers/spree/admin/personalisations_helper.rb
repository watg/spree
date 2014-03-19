module Spree
  module Admin
    module PersonalisationsHelper

      #TODO: this should be Rails.application.config.spree.personalisations
      PERSONALISATIONS = [ Spree::Personalisation::Monogram, Spree::Personalisation::Dob ]

      def options_for_product_personalisation_types(product)
        existing = product.personalisations.map { |p| p.class.name }
        personalisations_names = PERSONALISATIONS.map(&:name).reject{ |p| existing.include? p }
        #options = personalisations_names.map { |name| [ Spree.t("personalisation_types.#{name.demodulize.underscore}.name"), name] }
        options = personalisations_names.map { |name| [ name.split('::').last, name] }
        options_for_select(options)
      end

    end
  end
end

