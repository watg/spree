module Admin 
  class VideoPresenter
    attr_reader :product, :video

    def initialize(video, product)
      @video   = video
      @product = product  
    end

    def id
      video.id
    end

    def title
      video.title
    end

    def embed
      video.embed
    end

    def status
      product.videos.exists?(video) && %[checked]  
    end
  end
end