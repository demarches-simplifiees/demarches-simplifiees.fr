require 'spec_helper'

describe AccompagnateurService do
  describe '#change_assignement!' do

    let(:procedure) { create :procedure }
    let(:accompagnateur) { create :gestionnaire }

    subject { AccompagnateurService.change_assignement! accompagnateur, procedure, to }

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