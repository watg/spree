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

  private 

  def video
    @video ||= Video.find(id)
  end

  def embed_code
    Embed.build(embed).embed_code
  end
end