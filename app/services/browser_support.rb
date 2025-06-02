# frozen_string_literal: true

class BrowserSupport
  def self.supported?(browser)
    [
      browser.chrome? && browser.version.to_i >= 79 && !browser.platform.ios?,
      browser.edge? && browser.version.to_i >= 79 && !browser.compatibility_view?,
      browser.firefox? && browser.version.to_i >= 67 && !browser.platform.ios?,
      browser.opera? && browser.version.to_i >= 50,
      browser.safari? && browser.version.to_i >= 12,
      browser.platform.ios? && browser.platform.version.to_i >= 12,
      browser.samsung_browser? && browser.version.to_i >= 12
    ].any?
  end
end
