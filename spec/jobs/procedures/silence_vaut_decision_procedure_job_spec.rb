require 'rails_helper'

RSpec.describe Procedures::SilenceVautDecisionProcedureJob, type: :job do
  let!(:procedure) { create(:procedure, :published, auto_archive_on: nil, silence_vaut_decision_enabled: silence_vaut_decision_enabled, silence_vaut_decision_status: silence_vaut_decision_status, silence_vaut_decision_delais: silence_vaut_decision_delais) }

  let(:silence_vaut_decision_delais) { 6 }

  let!(:dossier1) { create(:dossier, procedure: procedure, created_at: created_at) }
  let!(:dossier2) { create(:dossier, :en_construction, procedure: procedure, created_at: created_at) }
  let!(:dossier3) { create(:dossier, :en_instruction, procedure: procedure, created_at: created_at) }
  let!(:dossier4) { create(:dossier, :processed, procedure: procedure, state: 'accepte', created_at: created_at) }
  let!(:dossier5) { create(:dossier, :processed, procedure: procedure, state: 'refuse', created_at: created_at) }
  let!(:dossier6) { create(:dossier, :processed, procedure: procedure, state: 'sans_suite', created_at: created_at) }

  let(:now) { DateTime.now.beginning_of_hour }
  let(:created_at){ now - 10.days }

  subject do
    Timecop.freeze(now) do
      Procedures::SilenceVautDecisionProcedureJob.new.perform
    end
    [procedure, dossier1, dossier2, dossier3, dossier4, dossier5, dossier6].each(&:reload)
  end

  context "when silence_vaut_decision_enabled is false" do
    let(:silence_vaut_decision_enabled){ false }

    let(:silence_vaut_decision_status){ "accepte" }

    it do
      d1_attributes = dossier1.attributes
      subject

      expect(d1_attributes). to eq(dossier1.attributes)
    end

    it { expect{ subject }.to_not change(dossier1, :attributes) }
    it { expect{ subject }.to_not change(dossier2, :attributes) }
    it { expect{ subject }.to_not change(dossier3, :attributes) }
    it { expect{ subject }.to_not change(dossier4, :attributes) }
    it { expect{ subject }.to_not change(dossier5, :attributes) }
    it { expect{ subject }.to_not change(dossier6, :attributes) }
  end

  context "when silence_vaut_decision_enabled is true" do
    let(:silence_vaut_decision_enabled){ true }
    let(:silence_vaut_decision_status){ "accepte" }

    it { expect{ subject }.to_not change(dossier1, :attributes) }
    it { expect{ subject }.to_not change(dossier2, :attributes) }
    it { expect{ subject }.to change(dossier3, :state).to("accepte") }
    it { expect{ subject }.to change(dossier3, :processed_at).to(now) }
    it { expect{ subject }.to_not change(dossier4, :attributes) }
    it { expect{ subject }.to_not change(dossier5, :attributes) }
    it { expect{ subject }.to_not change(dossier6, :attributes) }

    context "when silence_vaut_decision_status eq refuse" do
      let(:silence_vaut_decision_status){ "refuse" }

      it { expect{ subject }.to change(dossier3, :state).to("refuse") }
      it { expect{ subject }.to change(dossier3, :processed_at).to(now) }
    end

    context "when dossier.en_instruction_at is one hour before silence_vaut_decision_delais" do
      let(:created_at){ now - silence_vaut_decision_delais.days + 1.hour }

      it { expect{ subject }.to_not change(dossier3, :attributes) }
    end

    context "when dossier.en_instruction_at is one hour after silence_vaut_decision_delais" do
      let(:created_at){ now - silence_vaut_decision_delais.days - 1.hour }

      it { expect{ subject }.to change(dossier3, :state).to("accepte") }
      it { expect{ subject }.to change(dossier3, :processed_at).to(now) }
    end
  end
end
