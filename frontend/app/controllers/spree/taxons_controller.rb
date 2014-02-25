module Spree
  class TaxonsController < Spree::StoreController
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/products'
    helper 'spree/banner'

    before_filter :redirect_to_index_pages_controller

    respond_to :html

    MAX_SHOW_ALL = 60

    def show
      @taxon = Taxon.find_by_permalink(params[:id])
      @max_show_all = MAX_SHOW_ALL
      if @taxon.nil?
        redirect_to redirect_url(params[:id])
      else
        @curr_page, @per_page = pagination_helper( params )
      end
    end

    private
    def redirect_to_index_pages_controller
      if Flip.product_pages?
        taxon = Taxon.find_by_permalink(params[:id])
        path = (redirection_mapping[taxon.permalink] || '/') rescue '/'
        redirect_to path, status: 301
      end
    end

    def redirection_mapping
{"gifts/gift-cards"=>"/shop/items/gift-cards/made-by-the-gang",
 "collections/tara-stiles-x-watg"=>"/shop/knitwear/collections/tara-stiles-x-watg",
 "collections/personalise-and-monograms"=>
  "/shop/knitwear/collections/personalise-and-monograms",
 "men/sweaters-and-jumpers"=>"/shop/knitwear/men/sweaters-and-jumpers",
 "men/scarves"=>"/shop/knitwear/men/scarves-and-snoods",
 "men"=>"/shop/knitwear/men",
 "women/scarves-and-snoods"=>"/shop/knitwear/women/scarves-and-snoods",
 "women/vests"=>"/shop/knitwear/women/vests",
 "women/accessories"=>"/shop/knitwear/women/accessories",
 "knit-your-own/wool-and-cotton"=>"/shop/knitwear/knitting/wool-and-cotton",
 "women/dresses-and-skirts"=>"/shop/knitwear/women/dresses-skirts-and-shorts",
 "women/tops-and-t-shirts"=>"/shop/knitwear/women/tops-and-t-shirts",
 "collections/new-modern"=>"/shop/knitwear/collections",
 "collections/tartan-collection"=>"/shop/knitwear/collections/tartan",
 "knit-your-own/patterns"=>"/shop/items/patterns/made-by-the-gang",
 "collections"=>"/shop/knitwear/collections",
 "collections/Punk-Collection"=>"/shop/knitwear/collections/punk",
 "women/jumpers-and-sweaters"=>"/shop/knitwear/women/sweaters-and-jumpers",
 "collections/gang-collection"=>"/shop/knitwear/collections",
 "men/accessories"=>"/shop/knitwear/men/accessories",
 "knit-your-own/needles"=>"/shop/knitwear/knitting/needles",
 "women/capes-and-jackets"=>"/shop/knitwear/women/capes-and-jackets",
 "knit-your-own/kids-knit-kits"=>"/shop/knitwear/knitting/kids-knit-kits",
 "sale/knit-your-own"=>"/",
 "knit-your-own/bag-knit-kits"=>"/shop/knitwear/women/bags",
 "knit-your-own/new-arrivals"=>"/",
 "gifts/personalised-gifts"=>"/shop/knitwear/collections/personalise-and-monograms",
 "gifts/men"=>"/shop/items/gift-cards/made-by-the-gang",
 "sale/ready-made"=>"/",
 "sale"=>"/",
 "gifts"=>"/shop/items/gift-cards/made-by-the-gang",
 "men/hats-and-scarves"=>"/shop/knitwear/men",
 "women/new-arrivals"=>"/",
 "women/hats-and-scarves"=>"/shop/knitwear/women",
 "gifts/knit-kits"=>"/shop/items/gift-cards/made-by-the-gang",
 "knit-your-own/knit-kits"=>"/shop/knitwear/knitting",
 "knit-your-own"=>"/shop/knitwear/knitting",
 "gifts/women"=>"/shop/items/gift-cards/made-by-the-gang",
 "women"=>"/shop/knitwear/women"}
    end

    def redirect_url(permalink)
      permalink = permalink.split("/")[0..-2].join("/")
      if permalink.nil?
        root_path
      else
        root_path + 't/' + permalink
      end
    end

    def pagination_helper( params )
      per_page = params[:per_page].to_i
      per_page = per_page > 0 ? per_page : Spree::Config[:products_per_page]
      per_page = per_page > MAX_SHOW_ALL ? MAX_SHOW_ALL : per_page
      page = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
      curr_page = page || 1
      [curr_page, per_page]
    end

    def accurate_title
      if @taxon
        @taxon.seo_title
      else
        super
      end
    end

  end
end
