module Api
  module Search
    class PredictableSearch < ActiveInteraction::Base
      string :keywords
      interface :view,
                methods: %i(image_path spree)

      def execute
        filtered_suites(keywords: keywords).map do |suite|
          next unless suite.tabs.any?
          {
            title: suite.title,
            url: tab_type(suite, view),
            image_url: image(suite, view),
            target: suite.target.try(:name)
          }
        end.compact
      end

      private

      def tab_type(suite, view)
        view.spree.suite_url(id: suite, tab: suite.tabs.first.tab_type)
      end

      def image(suite, view)
        if suite.image.present?
          suite.image.attachment.url(:search)
        else
          view.image_path("product-group/placeholder-150x192.gif")
        end
      end

      def filtered_suites(keywords: keywords, scoped_suites: scoped_suites = Spree::Suite.indexable)
        return [] if keywords.blank?
        scoped_suites.includes(:image, :target, :tabs).where("title ~* ?", keywords).uniq
      end
    end
  end
end
