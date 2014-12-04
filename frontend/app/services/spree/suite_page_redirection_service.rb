module Spree
  class SuitePageRedirectionService < ActiveInteraction::Base
    include Spree::Core::Engine.routes.url_helpers

    string :permalink
    string :tab

    def execute
      suite = Spree::Suite.where(permalink: permalink).first

      if suite
        { url: suite_path(suite, tab: tab), http_code: :moved_permanently }
      else
        { url: root_path, http_code: :temporary_redirect }
      end
    end

  end
end
