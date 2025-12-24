# frozen_string_literal: true

class FixMandatoryForPrivateAnnotations < ActiveRecord::Migration[7.2]
  BATCH_SIZE = 1000

  def up
    TypeDeChamp.where(private: true, mandatory: true).in_batches(of: BATCH_SIZE) do |batch|
      batch.update_all(mandatory: false)
    end
  end

  def down
    TypeDeChamp.where(private: true, mandatory: false).in_batches(of: BATCH_SIZE) do |batch|
      batch.update_all(mandatory: true)
    end
  end
end
