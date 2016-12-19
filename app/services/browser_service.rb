class BrowserService

  def self.get_browser request
    BROWSER.value = Browser.new(request.user_agent)
  end

  def self.recommended_browser?
    browser = BROWSER.value

    return false if browser.chrome? && browser.version.to_i < 40
    return false if browser.ie?(["<10"])
    return false if browser.firefox? && browser.version.to_i < 45
    return false if browser.opera? && browser.version.to_i < 19
    return false if browser.safari? && browser.version.to_i < 8

    true
  end

end