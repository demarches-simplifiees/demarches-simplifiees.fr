Apipie.configure do |config|
  config.app_name                = "API TPS"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/docs"
  config.api_controllers_matcher = File.join(Rails.root, "app", "controllers","api","v1", "**","*.rb")
  config.markup                  = Apipie::Markup::Markdown.new
  config.default_version         = '1.0'
  config.validate                = false
  config.copyright               = "© SGMAP"
  config.namespaced_resources    = true
  config.show_all_examples       = true

  config.app_info                = <<-EOS
Description

  EOS
end
