# frozen_string_literal: true

module Maintenance
  class ResetPreferredDomain < MaintenanceTasks::Task
    def collection
      User.where.not(preferred_domain: nil)
    end

    def process(user)
      user.update_attribute(:preferred_domain, User.column_defaults['preferred_domain'])
    end
  end
end
