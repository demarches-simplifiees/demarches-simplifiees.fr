require 'spec_helper'

describe AccompagnateurService do
  let(:procedure) { create :procedure, :published }
  let(:accompagnateur) { create :gestionnaire }

  let(:accompagnateur_service) { AccompagnateurService.new accompagnateur, procedure, to }

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
end
