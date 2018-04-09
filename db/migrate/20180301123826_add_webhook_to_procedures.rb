class AddWebhookToProcedures < ActiveRecord::Migration[5.2]
  def change
    add_column :procedures, :web_hook_url, :string
  end
end
