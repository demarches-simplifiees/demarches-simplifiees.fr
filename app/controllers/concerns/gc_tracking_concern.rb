# frozen_string_literal: true

module GcTrackingConcern
  extend ActiveSupport::Concern

  included do
    around_action :track_gc_stat, if: :track_gc?

    def track_gc_stat
      before = GC.stat
      yield
      after = GC.stat

      begin
        @query_info ||= {}
        @query_info[:gc_stat_count] = after[:count] - before[:count] # number of gc
        @query_info[:gc_stat_heap_available_slots] = after[:heap_available_slots] - before[:heap_available_slots]
      rescue => e
        Sentry.capture_exception(e)
      end
    end

    def track_gc?
      ENV['TRACK_GC_ENABLED'] == 'enabled'
    end
  end
end
