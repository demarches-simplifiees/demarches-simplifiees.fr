RSpec.describe Cron::FindDubiousProceduresJob, type: :job do
  describe 'perform' do
    let(:mailer_double) { double('mailer', deliver_later: true) }
    let(:procedure) { create(:procedure, types_de_champ: tdcs) }
    let(:allowed_tdc) { build(:type_de_champ, libelle: 'fournir') }

    before do
      procedure

      allow(AdministrationMailer).to receive(:dubious_procedures) do |arg|
        @dubious_procedures_args = arg
      end.and_return(mailer_double)

      Cron::FindDubiousProceduresJob.new.perform
    end

    context 'with suspicious champs' do
      let(:forbidden_tdcs) do
        [
          build(:type_de_champ, libelle: 'num de securite sociale, stp'),
          build(:type_de_champ, libelle: "t'aurais une carte bancaire ?"),
          build(:type_de_champ, libelle: 'Parents biologiques'),
          build(:type_de_champ, libelle: 'Salaire de base')
        ]
      end

      let(:tdcs) { forbidden_tdcs + [allowed_tdc] }

      it 'mails tech about the dubious procedure' do
        receive_procedure, receive_forbidden_tdcs = @dubious_procedures_args[0]

        expect(receive_procedure).to eq(procedure)
        expect(receive_forbidden_tdcs).to match_array(forbidden_tdcs)

        expect(AdministrationMailer).to have_received(:dubious_procedures).with(@dubious_procedures_args)
      end

      context 'and a whitelisted procedure' do
        let(:procedure) { create(:procedure, :whitelisted) }

        it { expect(AdministrationMailer).to_not have_received(:dubious_procedures) }
      end

      context 'and a closed procedure' do
        let(:procedure) { create(:procedure, :closed) }

        it { expect(AdministrationMailer).to_not have_received(:dubious_procedures) }
      end

      context 'and a discarded procedure' do
        let(:procedure) { create(:procedure, :discarded) }

        it { expect(AdministrationMailer).to_not have_received(:dubious_procedures) }
      end
    end

    context 'with no suspicious champs' do
      let(:tdcs) { [allowed_tdc] }

      it { expect(AdministrationMailer).to_not have_received(:dubious_procedures) }
    end
  end
end
