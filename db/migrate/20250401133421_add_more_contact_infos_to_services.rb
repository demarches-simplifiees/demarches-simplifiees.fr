# frozen_string_literal: true

class AddMoreContactInfosToServices < ActiveRecord::Migration[7.0]
  def change
    add_column :services, :faq_link, :string
    add_column :services, :contact_link, :string
    add_column :services, :other_contact_info, :text
  end
end
