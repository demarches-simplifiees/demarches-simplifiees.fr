class DossierOperationLog < ApplicationRecord
  enum operation: {
    passer_en_instruction: 'passer_en_instruction',
    repasser_en_construction: 'repasser_en_construction',
    accepter: 'accepter',
    refuser: 'refuser',
    classer_sans_suite: 'classer_sans_suite',
    supprimer: 'supprimer'
  }

  belongs_to :dossier
  belongs_to :gestionnaire
  belongs_to :administration
end
