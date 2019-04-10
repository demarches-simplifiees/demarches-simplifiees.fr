class DossierOperationLog < ApplicationRecord
  enum operation: {
    passer_en_instruction: 'passer_en_instruction',
    repasser_en_construction: 'repasser_en_construction',
    accepter: 'accepter',
    refuser: 'refuser',
    classer_sans_suite: 'classer_sans_suite',
    supprimer: 'supprimer',
    modifier_annotation: 'modifier_annotation',
    demander_un_avis: 'demander_un_avis'
  }

  belongs_to :dossier
  store_accessor :payload, :author, :subject, :operation_date

  before_create :set_operation_date

  def automatic_operation?
    author.nil?
  end

  def self.serialize_author(author)
    case author
    when User
      { id: "Usager##{author.id}", email: author.email }
    when Gestionnaire
      { id: "Instructeur##{author.id}", email: author.email }
    when Administrateur
      { id: "Administrateur##{author.id}", email: author.email }
    when Administration
      { id: "Manager##{author.id}", email: author.email }
    else
      nil
    end
  end

  def self.serialize_subject(subject)
    case subject
    when Dossier
      DossierSerializer.new(subject).as_json
    when Champ
      ChampSerializer.new(subject).as_json
    when Avis
      AvisSerializer.new(subject).as_json
    when DeletedDossier
      DeletedDossierSerializer.new(subject).as_json
    end
  end

  private

  def set_operation_date
    self.operation_date = Time.zone.now.iso8601
  end
end
