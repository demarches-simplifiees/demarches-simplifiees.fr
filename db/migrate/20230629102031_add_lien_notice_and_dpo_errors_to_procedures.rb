# frozen_string_literal: true

class AddLienNoticeAndDpoErrorsToProcedures < ActiveRecord::Migration[7.0]
  def change
    add_column :procedures, :lien_notice_error, :text
    add_column :procedures, :lien_dpo_error, :text
  end
end
