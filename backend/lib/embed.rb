module Embed
  def self.build(url)
    if url[/^(http).+.(youtube.com)/]
      Embed::Youtube.new(url)
    elsif url[/^(http).+.(vimeo.com)/]
      Embed::Vimeo.new(url)
    end
  end
end