class CreateProductVideosService < ActiveInteraction::Base
  integer   :id
  array     :videos, default: []

  def execute
    product.update(videos: load_videos)
    product
  end

  def to_model
    Spree::Product.new
  end

  private
  
  def product
    @product ||= Spree::Product.find(id) 
  end

  def load_videos
    videos.map{ |v| Video.find(v) }
  end
end