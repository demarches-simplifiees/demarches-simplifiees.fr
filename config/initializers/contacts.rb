# todo: will be externally configurable
if !defined?(CONTACT_EMAIL)
  CONTACT_EMAIL = ENV.fetch("CONTACT_EMAIL", 'mes-demarches' + 64.chr + 'modernisation.gov.pf')
  EQUIPE_EMAIL = ENV.fetch("EQUIPE_EMAIL", 'rgpd-mes-demarches' + 64.chr + 'informatique.gov.pf')
  TECH_EMAIL = ENV.fetch("TECH_EMAIL", 'mes-demarches' + 64.chr + 'modernisation.gov.pf')
  NO_REPLY_EMAIL = ENV.fetch("NO_REPLY_EMAIL", 'Ne pas répondre <ne-pas-repondre' + 64.chr + 'modernisation.gov.pf>')
  CONTACT_PHONE = ENV.fetch("CONTACT_PHONE", '40 47 24 75')

  OLD_CONTACT_EMAIL = ENV.fetch("OLD_CONTACT_EMAIL", 'mes.demarches.en.polynesie' + 64.chr + 'gmail.com')
  CONTACT_ADDRESS = ENV.fetch("CONTACT_ADDRESS", "Direction de la modernisation et des réformes de l'administration / DMRA\n27 avenue Pouvanaa a Oopa, bâtiment du gouvernement, 1er étage, Papeete\nCe site est créé par l'Incubateur de Services Numériques / beta.gouv.fr et adapté/géré par le Service Informatique de la Polynésie française / SIPf")
end
