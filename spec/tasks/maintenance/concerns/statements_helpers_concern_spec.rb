# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maintenance::StatementsHelpersConcern do
  let(:dummy_class) do
    Class.new do
      include Maintenance::StatementsHelpersConcern
    end
  end

  let(:instance) { dummy_class.new }

  describe '#with_statement_timeout' do
    it 'applies the statement timeout and raises an error for long-running queries' do
      expect {
        instance.with_statement_timeout('1ms') do
          # Cette requête devrait prendre plus de 1ms et donc déclencher un timeout
          ActiveRecord::Base.connection.execute("SELECT pg_sleep(1)")
        end
      }.to raise_error(ActiveRecord::StatementInvalid, /canceling statement due to statement timeout/i)
    end

    it 'allows queries to complete within the timeout and returns the result' do
      result = instance.with_statement_timeout('1s') do
        ActiveRecord::Base.connection.execute("SELECT 42 AS answer").first['answer']
      end
      expect(result).to eq 42
    end
  end
end
