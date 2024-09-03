# frozen_string_literal: true

class Dropfeedbackstable < ActiveRecord::Migration[6.1]
  def up
    drop_table(:feedbacks, if_exists: true)
  end
end
