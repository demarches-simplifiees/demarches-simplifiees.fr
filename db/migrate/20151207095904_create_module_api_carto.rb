class CreateModuleAPICarto < ActiveRecord::Migration
  def change
    create_table :module_api_cartos do |t|
      t.string :name
    end

    add_reference :module_api_cartos, :procedure, references: :procedures
  end
end
