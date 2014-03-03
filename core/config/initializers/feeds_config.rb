FEEDS_CONFIG = YAML.load_file(File.join(Spree::Core::Engine.root, 'config/feeds.yml'))[Rails.env]
