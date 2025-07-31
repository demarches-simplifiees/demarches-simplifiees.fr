# frozen_string_literal: true

# rubocop:disable DS/ApplicationName
# todo: will be externally configurable
if !defined?(CONTACT_EMAIL)
  CONTACT_EMAIL = ENV.fetch("CONTACT_EMAIL", "contact@demarches-simplifiees.fr")
  NO_REPLY_EMAIL = ENV.fetch("NO_REPLY_EMAIL", "Démarches Simplifiées <ne-pas-repondre@demarches-simplifiees.fr>")
  CONTACT_PHONE = ENV.fetch("CONTACT_PHONE", "01 76 42 02 87")

  OLD_CONTACT_EMAIL = ENV.fetch("OLD_CONTACT_EMAIL", "contact@tps.apientreprise.fr")
  CONTACT_ADDRESS = ENV.fetch("CONTACT_ADDRESS", "Incubateur de Services Numériques / beta.gouv.fr\nServices du Premier Ministre, 20 avenue de Ségur, 75007 Paris")
end
# rubocop:enable DS/ApplicationName
