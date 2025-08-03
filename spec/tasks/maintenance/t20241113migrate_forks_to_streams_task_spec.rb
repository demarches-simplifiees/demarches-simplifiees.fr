# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20241113migrateForksToStreamsTask do
    describe "#process" do
      subject(:process) { described_class.process(fork) }
      let(:procedure) { create(:procedure, types_de_champ_public: [{}, { type: :piece_justificative }, { type: :repetition, children: [{}] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:fork) { dossier.owner_editing_fork }
      let(:champ_text) { fork.champs.first }
      let(:repetition_type_de_champ) { dossier.revision.types_de_champ.find(&:repetition?) }

      before {
        champ_for_update(champ_text).update!(value: "new value")
        fork.repetition_remove_row(repetition_type_de_champ, fork.repetition_row_ids(repetition_type_de_champ).first, updated_by: 'test')
        fork.repetition_add_row(repetition_type_de_champ, updated_by: 'test')
      }

      it { expect { subject }.to change { dossier.reload.send(:champs_on_user_buffer_stream).count }.from(0).to(3) }
      it { expect { subject }.to change { Dossier.exists?(fork.id) }.from(true).to(false) }
      it do
        subject
        rows, champs = dossier.reload.send(:champs_on_user_buffer_stream).partition(&:row?)
        expect(rows.map(&:discarded?)).to match_array([true, false])
        expect(champs.size).to eq(1)
      end
    end
  end
end
