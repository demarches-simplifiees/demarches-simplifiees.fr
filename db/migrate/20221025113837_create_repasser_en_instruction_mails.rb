# class CreateRepasserEnInstructionMails < ActiveRecord::Migration[6.1]
# 	def change
# 		create_table "repasser_en_instruction_mails", id: :serial do |t|
# 		  t.text "body"
# 		  t.string "subject"
# 		  t.integer "procedure_id"
# 		  t.datetime "created_at", null: false
# 		  t.datetime "updated_at", null: false
# 		  t.index ["procedure_id"], name: "index_repasser_en_instruction_mails_on_procedure_id"
# 		end

#   		add_reference :repasser_en_instruction_mails, :procedures, index: true
#     	add_foreign_key :repasser_en_instruction_mails, :procedures, validate: false
# 	end
# end