class AddEnInstructionCloseToExpirationToDossiers < ActiveRecord::Migration[5.2]
  def change
    add_column :dossiers, :en_instruction_close_to_expiration_notice_sent_at, :datetime
  end
end
