GraphQL::RailsLogger.configure do |config|
  config.white_list = {
    'API::V2::GraphqlController' => ['execute']
  }
end

GraphqlPlayground::Rails.configure do |config|
  config.title = APPLICATION_NAME
  config.settings = {
    "schema.polling.enable": false
  }
end
