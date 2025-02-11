# frozen_string_literal: true

module DatagouvCronSchedulableConcern
  extend ActiveSupport::Concern
  class_methods do
    def schedulable?
      return false if self == Cron::Datagouv::BaseJob
      Rails.application.config.ds_opendata_enabled
    end
  end
end
