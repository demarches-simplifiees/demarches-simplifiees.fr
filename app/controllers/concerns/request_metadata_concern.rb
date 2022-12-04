module RequestMetadataConcern
  extend ActiveSupport::Concern

  included do
    around_action :use_request_metadata
  end

  private

  def use_request_metadata(&block)
    Rails.configuration.event_store.with_metadata(request_metadata, &block)
  end

  def request_metadata
    { user_id: current_user&.uuid }
  end
end
