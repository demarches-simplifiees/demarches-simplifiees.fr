# frozen_string_literal: true

class AddAccuseLectureAgreementToDossiers < ActiveRecord::Migration[7.0]
  def change
    add_column :dossiers, :accuse_lecture_agreement_at, :date
  end
end
