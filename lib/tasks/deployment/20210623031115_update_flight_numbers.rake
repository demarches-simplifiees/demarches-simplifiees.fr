def update_field(param)
  procedure = Procedure.find_by(id: param[:procedure])
  if procedure.nil?
    puts "Procedure #{param[:procedure]} non trouvée"
    return
  end

  tdc = TypeDeChamp.where(revision: procedure.published_revision, libelle: param[:field])
  if tdc&.size == 1
    tdc = tdc[0]
    tdc.description = param[:description]
    tdc.options["drop_down_options"] = param[:options];
    tdc.save
    puts "Champ #{param[:field]} mis à jour sur la démarche #{param[:procedure]}:#{procedure.libelle}"
  else
    puts "Impossible de traiter le champ #{param[:field]}: #{tdc&.size} champ(s) trouvés: #{tdc}"
  end
end

namespace :after_party do
  desc 'Deployment task: update_list_of_flight_numbers_in_health_procedures'
  task update_flight_numbers: :environment do
    puts "Running deploy task 'update_flight_numbers'"

    # Put your task implementation HERE.

    ARRIVAL1 = {
      procedure: 1126,
      field: 'Numéro du vol',
      options: ['AF66', 'AF74', 'AF76', 'BF710', 'BF712', 'BF714', 'BF718', 'HA481', 'SB600', 'TN7', 'TN111', 'TN67', 'UA115', 'Militaire'],
      description: <<~EOS
        Indiquez le numéro du <b>dernier vol</b> vous permettant d'atterrir en Polynésie française.
        Attention: Pour la France, ne donnez pas le numéro d'un vol intérieur (type AF1122) mais bien le numéro du vol <b>en partance de Paris</b>.
        Vous pouvez <b>ajouter un numéro de vol</b> lorsqu'il n'est pas listé en cliquant dans la case blanche du menu déroulant et en pressant la touche Entrée pour valider.
        <font color='#B34D86'><b><font color='#B34D86'>Flight number: </font></b>Specify the number of the <b><font color='#B34D86'>last flight</font></b> allowing you to land in French Polynesia.
        Please note: For France, do not specify the number of a domestic flight (e.g. AF1122) but the number of the flight <b><font color='#B34D86'>departing from Paris</font></b>.
        You can <b><font color='#B34D86'>enter a flight number</font></b> if it is not listed by clicking in the menu's blank field and use Enter key to validate.</font>
      EOS
    }
    ARRIVAL2 = ARRIVAL1.merge(procedure: 1148)

    DEPARTURE = {
      procedure: 1100,
      field: 'Numéro du vol',
      options: ['AF67', 'AF75', 'AF77', 'BF713', 'BF715', 'BF716', 'BF717', 'BF719', 'HA482', 'SB601', 'TN2', 'TN8', 'TN68', 'UA114', 'Militaire'],
      description: <<~EOS
        Indiquez le numéro du vol vous permettant de partir de Polynésie française.
        Vous pouvez <b>ajouter un numéro de vol</b> lorsqu'il n'est pas listé en cliquant dans la case blanche du menu déroulant et en pressant la touche Entrée pour valider.
        <font color='#B34D86'><b><font color='#B34D86'>Flight number: </font></b><br>
        You can <b><font color='#B34D86'>enter a flight number</font></b> if it is not listed by clicking in the menu's blank field and use Enter key to validate.</font>
      EOS
    }
    update_field(ARRIVAL1)
    update_field(ARRIVAL2)
    update_field(DEPARTURE)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
