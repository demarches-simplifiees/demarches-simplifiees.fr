# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe FixOpenProceduresWithClosingReasonTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }
      let(:procedure) { create(:procedure, :published) }

      before do
        procedure.update_column(:closing_reason, 'internal_procedure')
      end

      it do
        subject
        expect(procedure.closing_reason).to be_nil
      end
    end
  end
end
