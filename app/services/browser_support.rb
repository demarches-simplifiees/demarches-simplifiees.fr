class BrowserSupport
  def self.supported?(browser)
    # See .browserslistrc
    [
      browser.chrome? && browser.version.to_i >= 50 && !browser.platform.ios?,
      browser.edge? && browser.version.to_i >= 14 && !browser.compatibility_view?,
      browser.firefox? && browser.version.to_i >= 50 && !browser.platform.ios?,
      browser.opera? && browser.version.to_i >= 40,
      browser.safari? && browser.version.to_i >= 8,
      browser.platform.ios? && browser.platform.version.to_i >= 8
    ].any?
  end
end
