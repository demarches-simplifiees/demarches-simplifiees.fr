require 'spec_helper'

describe TypeDeChampPolicy do
  let(:procedure) { create(:procedure) }
  let!(:type_de_champ) { create(:type_de_champ_text, procedure: procedure) }

  let(:pundit_user) { create(:user) }
  subject { Pundit.policy_scope(pundit_user, TypeDeChamp) }

  context 'when the user has only user rights' do
    it 'can not access' do
      expect(subject.find_by(id: type_de_champ.id)).to eq(nil)
    end
  end

  context 'when the user has administrateur rights' do
    let(:pundit_user) { procedure.administrateurs.first }

    it 'can access' do
      expect(subject.find(type_de_champ.id)).to eq(type_de_champ)
    end
  end
end
