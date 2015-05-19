class CreateVideoService < ActiveInteraction::Base
  string    :title, :url
  validates :title, :url, presence: true, uniqueness: true
  validates :url, format: { with: /\A(http).+.(youtube|vimeo)(.com)/ , 
                              message: 'youtube or vimeo urls only' }, 
                    :allow_blank => true

  def execute
    video.update(embed: embed_code)
    video
  end

  def to_model
    Video.new
  end
  
  private

  def video
    @video ||= Video.create(inputs)
  end

  def embed_code
    Embed.build(url).embed_code
  end
end
