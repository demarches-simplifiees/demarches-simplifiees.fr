require 'rails_helper'

RSpec.describe AutoArchiveProcedureWorker, type: :worker do

  let!(:procedure) { create(:procedure, archived: false, auto_archive_on: nil )}
  let!(:procedure_hier) { create(:procedure, archived: false, auto_archive_on: 1.day.ago )}
  let!(:procedure_aujourdhui) { create(:procedure, archived: false, auto_archive_on: Date.today )}
  let!(:procedure_demain) { create(:procedure, archived: false, auto_archive_on: 1.day.from_now )}

  subject { AutoArchiveProcedureWorker.new.perform }

  context "when procedures have no auto_archive_on" do

    before do
      subject
      procedure.reload
    end

    it { expect(procedure.archived).to eq false }

  end

  context "when procedures have auto_archive_on set on yesterday or today" do

    describe "titi" do
      before do
        subject
        procedure_hier.reload
        procedure_aujourdhui.reload
      end

      it { expect(procedure_hier.archived).to eq true }
      it { expect(procedure_aujourdhui.archived).to eq true }

    end


    context "with dossiers" do

      let!(:dossier1) { create(:dossier, procedure: procedure_hier, state: 'draft', archived: false)}
      let!(:dossier2) { create(:dossier, procedure: procedure_hier, state: 'initiated', archived: false)}
      let!(:dossier3) { create(:dossier, procedure: procedure_hier, state: 'replied', archived: false)}
      let!(:dossier4) { create(:dossier, procedure: procedure_hier, state: 'updated', archived: false)}
      let!(:dossier5) { create(:dossier, procedure: procedure_hier, state: 'received', archived: false)}
      let!(:dossier6) { create(:dossier, procedure: procedure_hier, state: 'closed', archived: false)}
      let!(:dossier7) { create(:dossier, procedure: procedure_hier, state: 'refused', archived: false)}
      let!(:dossier8) { create(:dossier, procedure: procedure_hier, state: 'without_continuation', archived: false)}

      before do
        subject
        (1..8).each do |i|
          eval "dossier#{i}.reload"
        end
      end

      it { expect(dossier1.state).to eq 'draft' }
      it { expect(dossier2.state).to eq 'received' }
      it { expect(dossier3.state).to eq 'received' }
      it { expect(dossier4.state).to eq 'received' }
      it { expect(dossier5.state).to eq 'received' }
      it { expect(dossier6.state).to eq 'closed' }
      it { expect(dossier7.state).to eq 'refused' }
      it { expect(dossier8.state).to eq 'without_continuation' }

    end
  end

  context "when procedures have auto_archive_on set on future" do

    before do
      subject
    end

    it { expect(procedure_demain.archived).to eq false }

  end

end
