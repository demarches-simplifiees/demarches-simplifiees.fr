require 'spec_helper'

describe AccompagnateurService do
  let(:procedure) { create :procedure }
  let(:accompagnateur) { create :gestionnaire }

  let(:accompagnateur_service) { AccompagnateurService.new accompagnateur, procedure, to}

  describe '#change_assignement!' do
    subject { accompagnateur_service.change_assignement! }

    context 'when accompagnateur is not assign at the procedure' do
      let(:to) { AccompagnateurService::ASSIGN }

      before do
        subject
      end

      it { expect(accompagnateur.procedures).to include procedure }
    end

    context 'when accompagnateur is assign at the procedure' do
      let(:to) { AccompagnateurService::NOT_ASSIGN }

      before do
        create :assign_to, gestionnaire: accompagnateur, procedure: procedure
        subject
      end

      it { expect(accompagnateur.procedures).not_to include procedure }
    end
  end

  describe '#build_default_column' do
    subject { accompagnateur_service.build_default_column }

    context 'when to is not assign' do
      let(:to) { AccompagnateurService::NOT_ASSIGN }

      it { is_expected.to be_nil }
    end

    context 'when to is assign' do
      let(:to) { AccompagnateurService::ASSIGN }

      context 'when gestionnaire has already preference for this procedure' do
        before do
          create :preference_list_dossier, gestionnaire: accompagnateur, procedure: procedure
        end

        it { is_expected.to be_nil }
      end

      context 'when gestionnaire has not preference for this procedure' do
        before do
          subject
        end

        it { expect(accompagnateur.preference_list_dossiers.where('procedure_id IS NULL').size).to eq procedure.preference_list_dossiers.size }
      end
    end
  end
end
