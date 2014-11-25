module Spree
  class PolyvorFeedJob < BaseFeedJob
    NAME = 'polyvor'

    CURRENCY = 'USD'
    HEADER = [
        'title',
        'brand',
        'url',
        'cpc_tracking_url',
        'imgurl',
        'price',
        'sale_price',
        'currency',
        'description',
        'color',
        'sizes',
        'tags',
        'target',
        'category',
        'cpc_labels'
      ]
    CATEGORY = 'Clothing'
    DEFAULT_IMAGE_URL = nil

    def feed
      CSV.generate(col_sep: "\t") do |csv|
        csv << header

        all_variants do |suite, tab, product, variant|
          csv << format_csv(suite, tab, product, variant)
        end
      end
    end


  private

    def header
      HEADER
    end

    def format_csv(suite, tab, product, variant)
      [
        suite.name, # title
        BRAND, # brand
        variant_url(suite, tab, variant),
        nil, # cpc_tracking_url
        variant_image_url(variant, suite, tab),
        variant.price_normal_in(CURRENCY).amount, # price
        current_price(variant), # normal or sale price when in_sale?
        CURRENCY,
        product.clean_description_for(suite.target), # description
        colour(variant), # color
        nil, # sizes
        nil, # tags
        gender(suite), # target
        CATEGORY, # category
        nil, # cpc_labels
      ]
    end


    def gender(suite)
      suite.target ? suite.target.name.humanize : 'Unisex'
    end

  end
end
