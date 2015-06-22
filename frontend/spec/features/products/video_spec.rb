require 'spec_helper'

feature 'video' do
  let!(:hat)     { create(:product, :with_marketing_type, name: 'hat', slug: 'hat-1') }
  let!(:kit)     { create(:product_type, :kit) }
  let!(:suite)   { create(:suite, name: 'Hat', permalink: 'hat') }
  let!(:tab)     { create(:suite_tab, tab_opts) }
  let(:tab_opts) { { tab_type: "knit-your-own", suite: suite, product: hat, in_stock_cache: true } }

  before         { hat.update(product_type: kit) }

  feature 'with video', js: true do
    let(:embed)    { %[<iframe src="https://www.youtube.com/embed/ssbkMawpE-M"></iframe>] }
    let(:expected) { %[<iframe src=\"https://www.youtube.com/embed/ssbkMawpE-M\"></iframe>] }
    before         { hat.videos.create(embed: embed) }

    scenario 'shows video' do
      visit '/product/hat'
      click_link 'Video'
      expect(page.body).to include expected
    end
  end

  feature 'without video', js: true do
    scenario 'doesnt show video' do
      visit '/product/hat'
      expect(page).to_not have_content('Sun Dance Hat')
      expect(page).to_not have_link('Video', href: '#panel_video')
    end
  end
end
