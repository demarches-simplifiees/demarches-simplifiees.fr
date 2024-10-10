# frozen_string_literal: true

class Cron::Datagouv::ChampFilledByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:10"
  FILE_NAME = "nb_champ_rempli_par_mois"
  HEADERS = ["mois", "procedure_id", "type_de_champ_id", "type_champ", "libelle", "obligatoire", "nb_champ_rempli"]

  def perform(*args)
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, HEADERS, data) do |file|
      begin
        APIDatagouv::API.upload(file, :statistics_dataset)
      ensure
        FileUtils.rm(file)
      end
    end
  end

  def data
    # possible adjustment: procedure with at least 300 folders
    type_de_champ_data(300).map! do |procedure_id, tdc_id, tdc_type_champ, tdc_libelle, tdc_mandatory, count_dossiers, count_value, count_data, champs_id|
      tdc_id = GraphQL::Schema::UniqueWithinType.encode('Champ', tdc_id)
      if tdc_mandatory == true
        [procedure_id, tdc_id, tdc_type_champ, tdc_libelle, tdc_mandatory, count_dossiers]
      else
        if champs_id.any?
          [procedure_id, tdc_id, tdc_type_champ, tdc_libelle, tdc_mandatory, champs_id.count { |id| !Champ.find(id).blank? }] # rubocop:disable Rails/Present
        elsif count_data > 0
          [procedure_id, tdc_id, tdc_type_champ, tdc_libelle, tdc_mandatory, count_data]
        else
          [procedure_id, tdc_id, tdc_type_champ, tdc_libelle, tdc_mandatory, count_value]
        end
      end
    end
  end

  def type_de_champ_data(nb_dossiers)
    TypeDeChamp.public_only
      .where.not(type_champ: ['header_section', 'repetition', 'explication', 'cnaf', 'dgfip', 'pole_emploi', 'mesri', 'cojo'])
      .joins('INNER JOIN procedure_revision_types_de_champ ON types_de_champ.id = procedure_revision_types_de_champ.type_de_champ_id')
      .joins('INNER JOIN procedures ON procedure_revision_types_de_champ.revision_id = procedures.published_revision_id')
      .merge(Procedure.publiee.where(estimated_dossiers_count: nb_dossiers.., opendata: true))
      .joins('INNER JOIN dossiers ON procedure_revision_types_de_champ.revision_id = dossiers.revision_id')
      .merge(Dossier.visible_by_user_or_administration.where(depose_at: 1.month.ago.all_month))
      .joins('INNER JOIN champs ON dossiers.id = champs.dossier_id AND types_de_champ.stable_id = champs.stable_id')
      .group('procedures.id, types_de_champ.stable_id, types_de_champ.type_champ, types_de_champ.libelle, types_de_champ.mandatory')
      .pluck(
            'procedures.id',
            'types_de_champ.stable_id',
            'types_de_champ.type_champ',
            'types_de_champ.libelle',
            'types_de_champ.mandatory',
            'COUNT(dossiers)',
            Arel.sql('COUNT(CASE WHEN types_de_champ.mandatory = false AND types_de_champ.type_champ NOT IN (\'piece_justificative\', \'titre_identite\', \'annuaire_education\', \'rnf\', \'carte\') THEN champs.value ELSE NULL END)'),
            Arel.sql('COUNT(CASE WHEN types_de_champ.mandatory = false AND types_de_champ.type_champ IN (\'annuaire_education\', \'rnf\') THEN champs.data ELSE NULL END)'),
            Arel.sql('array_agg(DISTINCT CASE WHEN types_de_champ.mandatory = false AND types_de_champ.type_champ IN (\'piece_justificative\', \'titre_identite\', \'carte\') THEN champs.id ELSE NULL END)')
          )
  end
end
