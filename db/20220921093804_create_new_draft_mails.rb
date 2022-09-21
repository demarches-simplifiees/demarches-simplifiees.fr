class CreateNewDraftMails < ActiveRecord::Migration[6.1]
	def change
		create_table "new_draft_mails", id: :serial do |t|
		  t.text "body"
		  t.string "subject"
		  t.integer "procedure_id"
		  t.datetime "created_at", null: false
		  t.datetime "updated_at", null: false
		  t.index ["procedure_id"], name: "index_new_draft_mails_on_procedure_id"
		end

  		add_reference :new_draft_mails, :procedures, index: true
    	add_foreign_key :new_draft_mails, :procedures
	end
end
	
	