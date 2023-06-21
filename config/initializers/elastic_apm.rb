APM_IGNORE_LIST = ['PingsController#index', 'ActiveStorage::Blobs::RedirectController#show'].freeze

ElasticAPM.add_filter(:filter_pings) do |payload|
  payload[:transactions]&.reject! do |t|
    APM_IGNORE_LIST.include?(t[:name])
  end

  payload
end
