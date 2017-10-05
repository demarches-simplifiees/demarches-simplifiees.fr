require 'rails_helper'

RSpec.describe PocDeclaratoireJob, type: :job do
  describe "perform" do
    let(:date) { Time.utc(2017, 9, 1, 10, 5, 0) }

    before { Timecop.freeze(date) }

    subject { PocDeclaratoireJob.new.perform(procedure_id) }

    context "with some dossiers" do
      let(:dossier1) { create(:dossier, :initiated) }
      let(:dossier2) { create(:dossier, :initiated, procedure: dossier1.procedure) }
      let(:dossier3) { create(:dossier, :received, procedure: dossier2.procedure) }
      let(:dossier4) { create(:dossier, procedure: dossier3.procedure) }
      let(:procedure_id) { dossier4.procedure_id }

      it do
        subject
        expect(dossier1.reload.received?).to be true
        expect(dossier1.reload.received_at).to eq(date)

        expect(dossier2.reload.received?).to be true
        expect(dossier2.reload.received_at).to eq(date)

        expect(dossier3.reload.received?).to be true
        expect(dossier3.reload.received_at).to eq(date)

        expect(dossier4.reload.draft?).to be true
        expect(dossier4.reload.received_at).to eq(nil)
      end
    end
  end
end
