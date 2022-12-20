module DatagouvCronSchedulableConcern
  extend ActiveSupport::Concern
  class_methods do
    def schedulable?
      Rails.application.config.ds_opendata_enabled
    end
  end
end
