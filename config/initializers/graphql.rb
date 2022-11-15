GraphQL::RailsLogger.configure do |config|
  config.white_list = {
    'API::V2::GraphqlController' => ['execute']
  }
end
