# frozen_string_literal: true

def update_field(param)
  procedure = Procedure.find_by(id: param[:procedure])
  if procedure.nil?
    puts "Procedure #{param[:procedure]} non trouvée"
    return
  end

  tdc = TypeDeChamp.where(revision: procedure.published_revision, libelle: param[:field])
  if tdc&.size == 1
    tdc = tdc[0]
    tdc.description = param[:description] if param[:description].present?
    tdc.save
    puts "Champ #{param[:field]} mis à jour sur la démarche #{param[:procedure]}:#{procedure.libelle}"
  else
    puts "Impossible de traiter le champ #{param[:field]}: #{tdc&.size} champ(s) trouvés: #{tdc}"
  end
end

namespace :after_party do
  desc 'Deployment task: Update'
  task update_res: :environment do
    puts "Running deploy task 'update_res'"

    ETAT_NOMINATIF = {
      procedure: 1275,
      field: 'Etat nominatif des salariés',
      description: <<~EOS
        Téléchargez et utilisez exclusivement le <a href="https://www.sefi.pf/SefiWeb/SefiPublic.nsf/ContenuWeb/RES3/$file/RES%20%C3%A9tat%20nominatif.xlsx">tableau RES état nominatif </a>, pour déclarer uniquement les salariés qui ont des jours suspendus.
      EOS
    }
    update_field(ETAT_NOMINATIF)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
