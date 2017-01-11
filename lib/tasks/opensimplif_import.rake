require 'csv'
require 'json'

namespace :opensimplif_import do
  task :import_all => :environment do
    puts 'start opensimplif'

    Rake::Task['opensimplif_import:import_proposition'].invoke
    Rake::Task['opensimplif_import:import_piste'].invoke
    Rake::Task['opensimplif_import:import_mesure'].invoke

    puts 'end import opensimplif'
  end

  task :import_proposition do
    file_path = "lib/tasks/161102_OS_Inputs_test_propositions.csv"
    procedure_id = 35

    matching = [
        {id: 44, key: 'Intitulé de la proposition'},
        {id: 43, key: 'Champ concerné'},
        {id: 45, key: 'Champ ministériel chef de file'},
        {id: 59, key: 'Date de la proposition'},
        {id: 60, key: 'Moment de vie'},
        {id: 61, key: 'Source'},
        {id: 48, key: 'Description de la proposition'}
    ]

    puts 'start propositions'
    import file_path, procedure_id, matching
    puts 'done propositions'
  end

  task :import_piste do
    file_path = "lib/tasks/161102_OS_Inputs_test_pistes.csv"
    procedure_id = 36

    matching = [
        {id: 81, key: 'Intitulé de la piste *'},
        {id: 82, key: 'Usager concerné *'},
        {id: 83, key: 'Champ ministériel chef de file *'},
        {id: 84, key: 'Champ ministériel contributeur'},
        {id: 85, key: 'Date de saisine'},
        {id: 66, key: 'Moment de vie'},
        {id: 80, key: 'Source de la piste'},
        {id: 70, key: 'Description de la piste '},
        {id: 68, key: 'Objectifs / bénéfices attendus'},
        {id: 65, key: 'Description détaillée des démarches impactées par la piste'},
        {id: 69, key: 'Levier de mise en oeuvre'},
        {id: 67, key: 'Précision sur le levier de meo'},
        {id: 64, key: 'Calendrier de mise en oeuvre'}
    ]

    puts 'start piste'
    import file_path, procedure_id, matching
    puts 'done pistes'
  end

  task :import_mesure do
    file_path = "lib/tasks/161102_OS_Inputs_test_mesures.csv"
    procedure_id = 37

    matching = [
        {id: 107, key: 'Intitulé projet / mesure'},
        {id: 104, key: 'Champ concerné'},
        {id: 105, key: 'Champ ministériel chef de file'},
        {id: 112, key: 'Direction chef de file'},
        {id: 106, key: 'Champ ministériel contributeur'},
        {id: 113, key: 'Direction contributrice'},
        {id: 92, key: 'Moment de vie'},
        {id: 109, key: 'Date d\'annonce'},
        {id: 114, key: 'N° de la mesure'},
        {id: 115, key: 'Responsable ministère'},
        {id: 116, key: 'Responsable SGMAP'},
        {id: 89, key: 'Actions réalisées'},
        {id: 95, key: 'Etapes nécessaires à l\'atteinte de la cible et alertes'},
        {id: 102, key: 'Alertes'},
        {id: 101, key: 'Échéance initiale'},
        {id: 96, key: 'Échéance prévisionnelle / réelle'},
        {id: 94, key: 'Appréciation avancement'},
        {id: 91, key: 'Etat d\'avancement LOLF'},
        {id: 111, key: '§ de com'}
    ]

    puts 'start mesures'
    import file_path, procedure_id, matching
    puts 'done mesures'
  end

  def self.import file_path, procedure_id, matching
    user = User.find_or_create_by(email: 'import@opensimplif.modernisation.fr')

    unless user.valid?
      user.password = 'TPSpassword2016'
      user.save
    end

    file ||= CSV.open(file_path, :col_sep => ";", :headers => true).map { |x| x.to_h }.to_json
    file = JSON.parse(file)

    procedure = Procedure.find(procedure_id)

    user.dossiers.where(procedure_id: procedure.id).destroy_all

    file.each do |proposition|
      dossier = Dossier.create procedure: procedure, user: user, state: :initiated

      dossier.champs.each do |champ|
        matching.each do |match|
          if match[:id] == champ.type_de_champ.id
            champ.update_column :value, proposition[match[:key]]
            break
          end
        end
      end
    end
  end
end
