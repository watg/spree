class CreateVideoService
  attr_reader :video

  WIDTH = 460

  def initialize(video)
    @video = video
  end

  def run
    @video.embed = embed
    @video.save
  end

  private

  def embed
    if youtube?
      Embed::Youtube.new(video).embed_code
    elsif vimeo?
      Embed::Vimeo.new(video).embed_code
    end
  end

  def youtube?
    video.embed[/^(http).+.(youtube.com)/]
  end

  def vimeo?
    video.embed[/^(http).+.(vimeo.com)/]
  end
end
