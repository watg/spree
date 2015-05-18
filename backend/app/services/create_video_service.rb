class CreateVideoService < ActiveInteraction::Base
  string    :title, :embed
  validates :title, :embed, presence: true, uniqueness: true
  validates :embed, format: { with: /\A(http).+.(youtube|vimeo)(.com)/ , 
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
    Embed.build(embed).embed_code
  end
end
