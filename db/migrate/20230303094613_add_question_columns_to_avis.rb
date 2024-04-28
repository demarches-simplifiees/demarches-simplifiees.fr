# frozen_string_literal: true

class AddQuestionColumnsToAvis < ActiveRecord::Migration[6.1]
  def change
    add_column :avis, :question_label, :string
    add_column :avis, :question_answer, :boolean
  end
end
