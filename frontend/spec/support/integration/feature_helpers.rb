module FeatureHelpers
  def kill_popups
    # visit('/')
    # browser = Capybara.current_session.driver.browser
    # browser.manage.add_cookie(:name => "signupPopKilled", :value => true)
    # browser.manage.add_cookie(:name => "showCookieMessage", :value => true)
    page.driver.set_cookie('signupPopKilled', 'true')
    page.driver.set_cookie('showCookieMessage', 'true')
  end
end
