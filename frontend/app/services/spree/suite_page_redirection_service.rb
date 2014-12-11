module Spree
  class SuitePageRedirectionService < ActiveInteraction::Base
    include Spree::Core::Engine.routes.url_helpers

    string :permalink
    hash   :params, strip: false

    def execute
      suite = Spree::Suite.where(permalink: permalink).first
      if suite
        { url: suite_path(suite, params), http_code: :moved_permanently }
      else
        { url: root_path, http_code: :temporary_redirect }
      end
    end

  end
end
