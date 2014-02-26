class Spree::IndexPageDecorator < Draper::Decorator
  delegate_all

  def apply_background_color
    ('style="background-color: #' + object.background_color + '"').html_safe if object.background_color.present?
  end

  def column_class(counter = 0)
    return "large-8" if counter % 9 == 0
    return "large-4"
  end

end
