require 'rails_helper'

RSpec.describe AutoArchiveProcedureJob, type: :job do
  let!(:procedure) { create(:procedure, :published, :with_gestionnaire, auto_archive_on: nil) }
  let!(:procedure_hier) { create(:procedure, :published, :with_gestionnaire, auto_archive_on: 1.day.ago) }
  let!(:procedure_aujourdhui) { create(:procedure, :published, :with_gestionnaire, auto_archive_on: Date.today) }
  let!(:procedure_demain) { create(:procedure, :published, :with_gestionnaire, auto_archive_on: 1.day.from_now) }

  subject { AutoArchiveProcedureJob.new.perform }

  context "when procedures have no auto_archive_on" do
    before do
      subject
      procedure.reload
    end

    it { expect(procedure.archivee?).to eq false }
  end

  context "when procedures have auto_archive_on set on yesterday or today" do
    let!(:dossier1) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:brouillon), archived: false) }
    let!(:dossier2) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:en_construction), archived: false) }
    let!(:dossier3) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:en_construction), archived: false) }
    let!(:dossier4) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:en_construction), archived: false) }
    let!(:dossier5) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:en_instruction), archived: false) }
    let!(:dossier6) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:accepte), archived: false) }
    let!(:dossier7) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:refuse), archived: false) }
    let!(:dossier8) { create(:dossier, procedure: procedure_hier, state: Dossier.states.fetch(:sans_suite), archived: false) }
    let!(:dossier9) { create(:dossier, procedure: procedure_aujourdhui, state: Dossier.states.fetch(:en_construction), archived: false) }
    let(:last_operation) { dossier2.dossier_operation_logs.last }

    before do
      subject

      [dossier1, dossier2, dossier3, dossier4, dossier5, dossier6, dossier7, dossier8, dossier9].each(&:reload)

      procedure_hier.reload
      procedure_aujourdhui.reload
    end

    it {
      expect(dossier1.state).to eq Dossier.states.fetch(:brouillon)
      expect(dossier2.state).to eq Dossier.states.fetch(:en_instruction)
      expect(last_operation.operation).to eq('passer_en_instruction')
      expect(last_operation.automatic_operation?).to be_truthy
      expect(dossier3.state).to eq Dossier.states.fetch(:en_instruction)
      expect(dossier4.state).to eq Dossier.states.fetch(:en_instruction)
      expect(dossier5.state).to eq Dossier.states.fetch(:en_instruction)
      expect(dossier6.state).to eq Dossier.states.fetch(:accepte)
      expect(dossier7.state).to eq Dossier.states.fetch(:refuse)
      expect(dossier8.state).to eq Dossier.states.fetch(:sans_suite)
      expect(dossier9.state).to eq Dossier.states.fetch(:en_instruction)
    }

    it {
      expect(procedure_hier.archivee?).to eq true
      expect(procedure_aujourdhui.archivee?).to eq true
    }
  end

  context "when procedures have auto_archive_on set on future" do
    before do
      subject
    end

    it { expect(procedure_demain.archivee?).to eq false }
  end
end
