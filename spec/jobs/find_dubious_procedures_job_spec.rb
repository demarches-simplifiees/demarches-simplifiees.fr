require 'rails_helper'

RSpec.describe FindDubiousProceduresJob, type: :job do
  describe 'perform' do
    let(:mailer_double) { double('mailer', deliver_now: true) }
    let(:procedure) { create(:procedure) }
    let(:allowed_tdc) { create(:type_de_champ, libelle: 'fournir') }

    before do
      allow(AdministrationMailer).to receive(:dubious_procedures) do |arg|
        @dubious_procedures_args = arg
      end.and_return(mailer_double)

      procedure.types_de_champ << tdcs
      FindDubiousProceduresJob.new.perform
    end

    context 'with suspicious champs' do
      let(:forbidden_tdcs) do
        [
          create(:type_de_champ, libelle: 'num de securite sociale, stp'),
          create(:type_de_champ, libelle: "t'aurais une carte bancaire ?")
        ]
      end

      let(:tdcs) { forbidden_tdcs + [allowed_tdc] }

      it 'mails tech about the dubious procedure' do
        receive_procedure, receive_forbidden_tdcs = @dubious_procedures_args[0]

        expect(receive_procedure).to eq(procedure)
        expect(receive_forbidden_tdcs).to match(forbidden_tdcs)
      end

      context 'and a whitelisted procedure' do
        let(:procedure) { create(:procedure, whitelisted_at: DateTime.now) }

        it { expect(AdministrationMailer).not_to have_received(:dubious_procedures) }
      end

      context 'and a archived procedure' do
        let(:procedure) { create(:procedure, archived_at: DateTime.now) }

        it { expect(AdministrationMailer).not_to have_received(:dubious_procedures) }
      end
    end

    context 'with no suspicious champs' do
      let(:tdcs) { [allowed_tdc] }

      it { expect(AdministrationMailer).not_to receive(:dubious_procedures) }
    end
  end
end
