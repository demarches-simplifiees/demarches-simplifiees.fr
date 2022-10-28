module DatagouvCronSchedulableConcern
  extend ActiveSupport::Concern
  class_methods do
    def schedulable?
      ENV.fetch('OPENDATA_ENABLED', nil) == 'enabled'
    end
  end
end
