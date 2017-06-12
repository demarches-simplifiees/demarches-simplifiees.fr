class ProcedureOverview
  include Rails.application.routes.url_helpers
  attr_accessor :libelle, :notifications_count, :received_dossiers_count, :created_dossiers_count, :processed_dossiers_count, :date

  def initialize(procedure, start_date, notifications_count)
    @libelle = procedure.libelle
    @procedure_url = backoffice_dossiers_procedure_url(procedure)
    @notifications_count = notifications_count

    @received_dossiers_count = procedure.dossiers.where(state: :received).count
    @created_dossiers_count = procedure.dossiers
      .where(created_at: start_date..DateTime.now)
      .where.not(state: :draft)
      .count
    @processed_dossiers_count = procedure.dossiers.where(processed_at: start_date..DateTime.now).count
  end

  def had_some_activities?
    [received_dossiers_count,
     created_dossiers_count,
     processed_dossiers_count,
     notifications_count].reduce(:+) > 0
  end

  def to_html
    [libelle_description,
     dossiers_en_instruction_description,
     created_dossier_description,
     processed_dossier_description,
     notifications_description].compact.join('<br>')
  end

  private

  def libelle_description
    "<a href='#{@procedure_url}'><strong>#{libelle}</strong></a>"
  end

  def dossiers_en_instruction_description
    case received_dossiers_count
    when 0
      nil
    when 1
      "1 dossier est en cours d'instruction"
    else
      "#{received_dossiers_count} dossiers sont en cours d'instruction"
    end
  end

  def created_dossier_description
    case created_dossiers_count
    when 0
      nil
    when 1
      '1 nouveau dossier a été déposé'
    else
      "#{created_dossiers_count} nouveaux dossiers ont été déposés"
    end
  end

  def processed_dossier_description
    case processed_dossiers_count
    when 0
      nil
    when 1
      '1 dossier a été instruit'
    else
      "#{processed_dossiers_count} dossiers ont été instruits"
    end
  end

  def notifications_description
    case notifications_count
    when 0
      nil
    when 1
      '1 notification en attente sur les dossiers que vous suivez'
    else
      "#{notifications_count} notifications en attente sur les dossiers que vous suivez"
    end
  end
end
