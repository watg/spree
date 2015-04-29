module AdminHelper

  def admin_present(object, options, klass = nil)
    klass ||= "Admin::#{object.class.name.demodulize}Presenter".constantize
    presenter = klass.new(object, self, options)
    yield presenter if block_given?
    presenter
  end

end
