namespace :after_party do
  desc 'Deployment task: sefi_instructeur_setup'
  task sefi_instructeur_setup: :environment do
    puts "Running deploy task 'sefi_instructeur_setup'"

    # Put your task implementation HERE.
    sefi_instructeurs =
      [
        'amelie.pons-hirigoyen#sefi.pf',
        'beatrice.maitere#sefi.pf',
        'bennett.turouru#gmail.com',
        'carinne.normand-ricard#sefi.pf',
        'claude.legrand#jeunesse.gov.pf',
        'dominique.lestage#sefi.pf',
        'eric.cheung#sefi.pf',
        'fan#ccism.pf',
        'felix.chenon#informatique.gov.pf',
        'floriana.lai#sefi.pf',
        'gilles.lorphelin#modernisation.gov.pf',
        'heimana.apeang#sefi.pf',
        'heinarii.tiare#sefi.pf',
        'heipua.lucas#sefi.pf',
        'heiroti.tchen#sefi.pf',
        'henriette.tamata#sefi.pf',
        'isabelle#ccism.pf',
        'jean.claret#sefi.pf',
        'julienne.chung#sefi.pf',
        'june.teauna#sefi.pf',
        'lmyrna#hotmail.fr',
        'mael.congard#informatique.gov.pf',
        'maima.paia#sefi.pf',
        'manava.teriitetofa#sefi.pf',
        'manava.teriitetoofa#sefi.pf',
        'manuela.mauahiti#sefi.pf',
        'marau.brothers#sefi.pf',
        'marotea.teapehu#travail.gov.pf',
        'mediation#museetahiti.pf',
        'philomène#ccism.pf',
        'poema.tang#gmail.com',
        'poerani.crawford#jeunesse.gov.pf',
        'raina.fongsung#sefi.pf',
        'raphael.costa#tourisme.gov.pf',
        'sandrine.yan#sefi.pf',
        'stephanie.cheunghi#modernisation.gov.pf',
        'tamahere.chanson#sefi.pf',
        'tauhia.tekurarere#tourisme.gov.pf',
        'teaha.raina#gmail.com',
        'teani.ihopu#jeunesse.gov.pf',
        'terii.pellissier#sefi.pf',
        'teva.claveau#sefi.pf',
        'tinihau.tavahe#sefi.pf',
        'tinihautav#hotmail.fr',
        'titiagras#hotmail.com',
        'tom.tefaaora#sefi.pf',
        'turouru.bennett#sefi.pf',
        'vaea.terorohauepa#sefi.pf',
        'vaeheana.labaste#travail.gov.pf',
        'vaiana.clark#sefi.pf',
        'vaihaunui.tahi#sefi.pf',
        'vaihere.frogier#sefi.pf',
        'vaimana17#hotmail.fr',
        'vatea#ccism.pf',
        'veronique.martinez-sola#ccism.pf',
        'virginie.amaru#modernisation.gov.pf',
        'weillina.reva#sefi.pf'
      ]
    # sefi_remaining_instructeurs =
    #   [
    #     'heirani.caron#sefi.pf',
    #     'steven.wong#sefi.pf',
    #     'vaitia.buchin#sefi.pf',
    #     'stephanie.baricault#sefi.pf',
    #     'clautier#idt.pf',
    #     'william.joseph#modernisation.gov.pf ',
    #     'leonard.tavae#informatique.gov.pf',
    #     'rava.domingo#sefi.pf',
    #     'heilani.lissant#sefi.pf',
    #     'david.cheon#sefi.pf',
    #     'poeiti.mallegoll#sefi.pf',
    #     'hina.grepin-louison#sefi.pf',
    #     'valerie.cholet#sefi.pf',
    #     'miriama.faivre#sefi.pf'
    #   ]
    ids_to_assign =
      []
    ids_to_unassign =
      [
        216,  # Demande de Revenu Exceptionnel de Solidarité [RES]
        217,  # Demande de Revenu Exceptionnel de Solidarité [RES]
        220,  # Demande d’Indemnité de Solidarité [IS]
        222,  # Demande d’Indemnité de Solidarité [IS] (Papier / T
        223,  # Demande d'Indemnité Exceptionnelle [IE] (- de 10 p
        225,  # Demande d'Indemnité Exceptionnelle [IE] (Papier /
        226,  # Demande de Revenu Exceptionnel de Solidarité [RES]
        232,  # Demande d'Indemnité Exceptionnelle [IE] (+ de 10 p
        253,  # Test 01 [CSP]
        254,  # Demande de Revenu Exceptionnel de Solidarité (RES)
        260,  # Demande de [RES]
        263,  # Particulier-employeur sans numéro TAHITI - Demande
        266,  # Demande de Revenu Exceptionnel de Solidarité (RES)
        305,  # Particulier-employeur [Papier / mail / téléphone]
        309,  # [DEV] Particulier-employeur sans numéro TAHITI - D
        312,  # 2ème période [IS] Demande d’Indemnité de Solidarit
        314,  # 2ème période [RES] Demande de Revenu Exceptionnel
        320,  # 2ème période [RES] Demande de Revenu Exceptionnel
        327,  # 2ème période [RES Papier / Téléphone] Demande de R
        335,  # 2ème période [IS Papier / Téléphone] Demande d’Ind
        348,  # RECTIFICATIF : Demande de Revenu Exceptionnel de S
        349,  # 2ème Période [CSP] Chèques Service aux Particulier
        350,  # 2ème période [CSP Papier / Téléphone] Chèques Serv
        351,  # 2ème période Particulier-employeur sans numéro TAH
        352   # 2ème période Particulier-employeur [téléphone mail
      ]
    progress = ProgressReport.new(sefi_instructeurs.size)

    puts "Processing instructeurs"
    procedures_to_assign = Procedure.where(id: ids_to_assign).to_a
    procedures_to_unassign = Procedure.where(id: ids_to_unassign).to_a

    sefi_instructeurs
      .map(&:strip)
      .map(&:downcase)
      .map { |email| email.tr('#', '@') }
      .filter { |email| URI::MailTo::EMAIL_REGEXP.match?(email) }
      .each do |email|
      instructeur = Instructeur.by_email(email)
      if instructeur
        instructeur.followed_dossiers.each do |dossier|
          instructeur.unfollow(dossier) if ids_to_unassign.include?(dossier.procedure.id)
        end
        procedures_to_assign.each { |procedure| instructeur.assign_to_procedure(procedure) }
        procedures_to_unassign.each { |procedure| instructeur.remove_from_procedure(procedure) }
      end
      progress.inc
    end
    progress.finish
    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
