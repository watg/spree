module FeatureHelpers
  def kill_popups
    # page.driver.browser.manage.add_cookie(:name => "signupPopKilled", :value => true)
    # page.driver.browser.manage.add_cookie(:name => "showCookieMessage", :value => true)
    page.driver.set_cookie('signupPopKilled', 'true')
    page.driver.set_cookie('showCookieMessage', 'true')
  end
end
