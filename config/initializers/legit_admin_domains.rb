# frozen_string_literal: true

domains = [
  "assurance-maladie.fr",
  "caf.fr",
  "cci.fr",
  "cnafmail.fr",
  "cnamts.fr",
  "gouv.fr",
  "justice.fr",
  "msa.fr",
  "sante.fr",
]
LEGIT_ADMIN_DOMAINS = ENV["LEGIT_ADMIN_DOMAINS"]&.split(';') || domains
