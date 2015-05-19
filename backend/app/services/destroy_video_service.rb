class DestroyVideoService < ActiveInteraction::Base
  integer :id

  def execute
    video.delete
  end

  def video
    Video.find(id)  
  end
end