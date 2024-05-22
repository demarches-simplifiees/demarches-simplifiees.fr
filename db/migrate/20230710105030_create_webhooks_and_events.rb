class CreateWebhooksAndEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :webhooks do |t|
      t.boolean :enabled, default: true, null: false
      t.text :url, null: false
      t.text :label, null: false

      t.text :secret, null: false
      t.string :event_type, index: true, null: false, array: true
      t.references :procedure, foreign_key: true, index: true, null: false

      t.datetime :last_success_at
      t.datetime :last_error_at
      t.text :last_error_message
      t.integer :retries, default: 0, null: false

      t.timestamps
    end

    create_table :webhook_events, id: :uuid do |t|
      t.string :event_type, null: false, array: true
      t.string :resource_type, null: false
      t.string :resource_id, null: false
      t.string :resource_version, null: false
      t.datetime :enqueued_at, null: false
      t.datetime :delivered_at

      t.references :webhook, foreign_key: true, index: true, null: false

      t.timestamps
    end
  end
end
