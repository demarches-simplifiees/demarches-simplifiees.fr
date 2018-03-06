Apipie.configure do |config|
  config.app_name                = "API demarches-simplifiees.fr"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/docs"
  config.api_controllers_matcher = Rails.root.join("app", "controllers"," api", "v1", "**", "*.rb")
  config.markup                  = Apipie::Markup::Markdown.new
  config.default_version         = '1.0'
  config.validate                = false
  config.namespaced_resources    = true
  config.show_all_examples       = true

  config.languages               = ['fr']
  config.default_locale          = 'fr'

  config.app_info                = <<~EOS
    Description

  EOS
end
