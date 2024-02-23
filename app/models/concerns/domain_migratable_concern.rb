module DomainMigratableConcern
  extend ActiveSupport::Concern

  included do
    enum preferred_domain: { demarches_gouv_fr: 0, demarches_simplifiees_fr: 1 }, _prefix: true

    validates :preferred_domain, inclusion: { in: User.preferred_domains.keys, allow_nil: true }
    validates :cross_domain_token, uniqueness: true, allow_nil: true
  end
end
