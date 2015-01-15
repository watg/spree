module Spree
  class IndexPagesController < Spree::StoreController

    before_filter :redirect_to_taxon_pages

    PER_PAGE = 3
    TAXON_ALIASES = {
      'whats-new-kids' => 'whats-new/kids',
      'whats-new-women' => 'whats-new/women',
      'whats-new-men' => 'whats-new/men',
      'whats-new-seen-in-press' => 'whats-new/seen-in-press',

      'whats-new-seen-in-press' => 'whats-new/seen-in-press',

      # old top level static pages. Can't redirect due to routes preference
      # 'knitting/men' => 'knit-kits/men',
      # 'knitting/women' => 'knit-kits/women',
      # 'knitting/kids' => 'knit-kits/kids',

      'knitting/beginner-knit-kits' => 'knit-kits/beginner-kits',
      'knitting/easy-knit-kits' => 'knit-kits/easy-kits',
      'knitting/intermediate-knit-kits' => 'knit-kits/intermediate-kits',
      'knitting/advanced-knit-kits' => 'knit-kits/advanced-kits',

      'knitting/cotton' => 'yarn-and-patterns/yarn/cotton',
      'knitting/wool-and-cotton' => 'yarn-and-patterns/yarn/wool-and-merino-wool',
      'knitting/patterns' => 'yarn-and-patterns/patterns',
      'knitting/needles' => 'yarn-and-patterns/supplies/needles',

      'knitting/mens-knit-kits' => 'knit-kits/men',
      'knitting/womens-knit-kits' => 'knit-kits/women',
      'knitting/summer-knit-projects' => 'knit-kits/spring-slash-summer-kits',
      'knitting/winter-knit-projects' => 'knit-kits/autumn-slash-winter-kits',
      'knitting/kids/mini-gang' => 'knit-kits/mini-gang',
      'knitting/kids/baby-gang' => 'knit-kits/baby-gang',
      'knitting/knit-kits' => 'knit-kits',
      'knitting-bag-knit-kits' => 'knit-kits/bags',
      'knitting/new-arrivals' => 'knit-kits/new-arrivals',

      'knitting/men/scarves-and-snoods'  => 'men/scarves-and-snoods',

      # 3 left:
      # /knitting-bag-knit-kits
      # /knitting/knit-your-own
      # /knitting/new-arrivals
    }

    def show
    end

    def redirect_to_taxon_pages
      permalink = Spree::IndexPagesController::TAXON_ALIASES[params[:id]] || params[:id]

      taxon = Spree::Taxon.with_deleted.where(permalink: permalink).first
      if taxon
        redirect_to spree.nested_taxons_path(taxon), status: :moved_permanently
      else
        redirect_to root_path, status: :temporary_redirect
      end
    end

  end
end
