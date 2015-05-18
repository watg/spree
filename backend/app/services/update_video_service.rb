class UpdateVideoService < ActiveInteraction::Base
  integer   :id
  string    :title, :embed
  validates :title, :embed, presence: true, uniqueness: true
  validates :embed, format: { with: /\A(http).+.(youtube|vimeo)(.com)/ , 
                              message: 'youtube or vimeo urls only' }, 
                    :allow_blank => true

  def execute
    video.update(inputs)
    video.update(embed: embed_code)
  end

  def video
    @video ||= Video.find(id)
  end

  private

  def embed_code
    if youtube?
      Embed::Youtube.new(embed).embed_code
    elsif vimeo?
      Embed::Vimeo.new(embed).embed_code
    end
  end

  def youtube?
    embed[/^(http).+.(youtube.com)/]
  end

  def vimeo?
    embed[/^(http).+.(vimeo.com)/]
  end
end