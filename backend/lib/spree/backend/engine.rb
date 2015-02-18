module Spree
  module Backend
    class Engine < ::Rails::Engine
      config.middleware.use "Spree::Backend::Middleware::SeoAssist"

      config.autoload_paths += %W(#{config.root}/lib)

      initializer "spree.backend.environment", :before => :load_config_initializers do |app|
        Spree::Backend::Config = Spree::BackendConfiguration.new
      end

      # filter sensitive information during logging
      initializer "spree.params.filter" do |app|
        app.config.filter_parameters += [:password, :password_confirmation, :number]
      end

      # sets the manifests / assets to be precompiled, even when initialize_on_precompile is false
      initializer "spree.assets.precompile", :group => :all do |app|
        app.config.assets.precompile += %w[
          spree/backend/all*
          spree/backend.js
          spree/backend.css
          spree/backend/orders/edit_form.js
          spree/backend/address_states.js
          jqPlot/excanvas.min.js
          spree/backend/images/new.js
          jquery.jstree/themes/apple/*
          fontawesome-webfont*
          select2_locale*
          jquery.alerts/images/*
        ]
      end

      def self.activate
        %w(reports jobs doc).each do |folder|
          Dir.glob(File.join(File.dirname(__FILE__), "../../../app/#{folder}/**/*.rb")) do |c|
            Rails.env.production? ? require(c) : load(c)
          end
        end
      end

      config.to_prepare &method(:activate).to_proc
    end
  end
end
