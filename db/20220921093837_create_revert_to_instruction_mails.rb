class CreateRevertToInstructionMails < ActiveRecord::Migration[6.1]
	def change
		create_table "revert_to_instruction_mails", id: :serial do |t|
		  t.text "body"
		  t.string "subject"
		  t.integer "procedure_id"
		  t.datetime "created_at", null: false
		  t.datetime "updated_at", null: false
		  t.index ["procedure_id"], name: "index_revert_to_instruction_mails_on_procedure_id"
		end

  		add_foreign_key "revert_to_construction_mails", "procedures"
	end
end