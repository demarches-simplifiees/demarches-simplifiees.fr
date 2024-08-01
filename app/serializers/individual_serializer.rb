# frozen_string_literal: true

class IndividualSerializer < ActiveModel::Serializer
  attribute :gender, key: :civilite
  attributes :nom, :prenom
  attribute :birthdate, key: :date_naissance, if: :include_birthdate?

  def include_birthdate?
    object&.dossier&.groupe_instructeur&.procedure&.ask_birthday
  end
end
