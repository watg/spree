module Api
  module Search
    class PredictableSearch
      delegate :url_for, to: :@view
      def initialize(keywords, view_context)
        @keywords = keywords
        @view = view_context
      end

      def results
        filtered_suites(keywords: @keywords).map do |s|
          image =  if s.image.present?
                     s.image.attachment.url(:search)
                   else
                     @view.image_path("product-group/placeholder-150x192.gif")
                   end
          {
            title: s.title,
            url: @view.spree.suite_url(id: s, tab: s.tabs.first.tab_type),
            image_url: image,
            target: s.target.try(:name)
          }
        end
      end

      def filtered_suites(keywords: keywords, scoped_suites: scoped_suites = Spree::Suite.active)
        return [] if keywords.blank?
        scoped_suites.where("title ~* ?", keywords).uniq
      end
    end
  end
end
