# class CreateNouveauBrouillonMails < ActiveRecord::Migration[6.1]
# 	def change
# 		create_table "nouveau_brouillon_mails", id: :serial do |t|
# 		  t.text "body"
# 		  t.string "subject"
# 		  t.integer "procedure_id"
# 		  t.datetime "created_at", null: false
# 		  t.datetime "updated_at", null: false
# 		  t.index ["procedure_id"], name: "index_nouveau_brouillon_mails_on_procedure_id"
# 		end

#   		add_reference :nouveau_brouillon_mails, :procedures, index: true
#     	add_foreign_key :nouveau_brouillon_mails, :procedures, validate: false
# 	end
# end