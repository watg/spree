require 'active_support/all'
module ControllerHacks
  def api_get(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "GET")
  end

  def api_post(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "POST")
  end

  def api_put(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "PUT")
  end

  def api_patch(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "PATCH")
  end

  def api_delete(action, params={}, session=nil, flash=nil)
    api_process(action, params, session, flash, "DELETE")
  end

  def api_process(action, params={}, session=nil, flash=nil, method="get")
    scoping = respond_to?(:resource_scoping) ? resource_scoping : {}
    process(action, method, params.merge(scoping).reverse_merge!(:use_route => :spree, :format => :json), session, flash)
  end
end

RSpec.configure do |config|
  config.include ControllerHacks, type: :controller

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end
