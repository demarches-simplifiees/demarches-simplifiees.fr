require 'spec_helper'

describe CommentaireDecorator do
  let(:commentaire) { Timecop.freeze(Time.utc(2008, 9, 1, 10, 5, 0)) {create :commentaire} }
  let(:decorator) { commentaire.decorate }

  describe 'created_at_fr' do
    subject { decorator.created_at_fr }

    context 'when created_at have a value' do
      it { is_expected.to eq '01/09/2008 - 10:05' }
    end
  end
end
