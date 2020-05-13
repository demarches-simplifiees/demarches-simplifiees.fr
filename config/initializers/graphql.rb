GraphQL::RailsLogger.configure do |config|
  config.white_list = {
    'API::V2::GraphqlController' => ['execute']
  }
end

GraphqlPlayground::Rails.configure do |config|
  config.title = "demarches-simplifiees.fr"
  config.settings = {
    "schema.polling.enable": false
  }
end
