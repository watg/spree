module Spree
  module BannerHelper

      BANNERS = {
        'collections/gang-collection' => [ 'gang-banner-sml.jpg', 'gang-banner-lrg.jpg', '#madeunique', 'by the gang'],
        'women/hats-and-scarves' => [ 'women-hats-and-scarves-banner-sml.jpg','women-hats-and-scarves-banner-lrg.jpg' ],
        'women/scarves-and-snoods' => [ 'women_scarves_snoods_sml.jpg','women_scarves_snoods_lrg.jpg', 'super chunky', 'knits' ],
        'women/new-arrivals' => [ 'women_new_arrivals_sml.jpg','women_new_arrivals_lrg.jpg'],
        'women/accessories' => [ 'women_bags_sml.jpg','women_bags_lrg.jpg'],
        'women' => [ 'women_sml.jpg','women_lrg.jpg','#madeunique', 'be unique'],
        'collections' => [ 'gifts_sml.jpg','gifts_lrg.jpg','made by the gang','or knit your own'],
        'collections/knit-kits' => [ 'gifts_knit_kits_sml.jpg','gifts_knit_kits_lrg.jpg'],
        'collections/women' => [ 'gifts_women_sml.jpg','gifts_women_lrg.jpg','made by the gang','or knit your own'],
        'collections/men' => [ 'gifts_men_sml.jpg','gifts_men_lrg.jpg','#madeunique', 'by the gang'],
        'collections/personalised-gifts' => [ 'personalised_gifts_sml.jpg','personalised_gifts_lrg.jpg'],
        'knit-your-own/knit-kits' => [ 'knit_kits_sml.jpg','knit_kits_lrg.jpg'],
        'collections/personalise-and-monograms' => [ 'personalised_and_monograms_sml.jpg','personalised_and_monograms_lrg.jpg'],
        'men/scarves' => [ 'men_scarves_sml.jpg','men_scarves_lrg.jpg'],
        'men/hats-and-scarves' => [ 'men_hats_sml.jpg','men_hats_lrg.jpg'],
      }

    def banner(permalink)
      if BANNERS[permalink]
        small_url = cdn_url("static/#{BANNERS[permalink][0]}")
        large_url = cdn_url("static/#{BANNERS[permalink][1]}")
        [ small_url, large_url, BANNERS[permalink][2], BANNERS[permalink][3] ]
      end
    end
  end
end
