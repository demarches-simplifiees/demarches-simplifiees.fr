# frozen_string_literal: true

module DomainMigratableConcern
  extend ActiveSupport::Concern

  included do
    enum :preferred_domain, { demarches_numerique_gouv_fr: 0, demarches_simplifiees_fr: 1 }, prefix: true

    validates :preferred_domain, inclusion: { in: User.preferred_domains.keys, allow_nil: true }

    def update_preferred_domain(host)
      case host
      when ApplicationHelper::APP_HOST
        preferred_domain_demarches_numerique_gouv_fr!
      when ApplicationHelper::APP_HOST_LEGACY
        preferred_domain_demarches_simplifiees_fr!
      end
    end
  end
end
