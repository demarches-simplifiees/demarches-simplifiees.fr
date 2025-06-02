# frozen_string_literal: true

domains = ["gouv.fr", "sante.fr", "cnafmail.fr", "cnamts.fr", "cci.fr", "caf.fr", "msa.fr", "assurance-maladie.fr"]
LEGIT_ADMIN_DOMAINS = ENV["LEGIT_ADMIN_DOMAINS"]&.split(';') || domains
