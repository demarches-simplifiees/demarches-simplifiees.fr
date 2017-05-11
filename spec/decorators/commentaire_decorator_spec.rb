require 'spec_helper'

describe CommentaireDecorator do
  let(:time) { Time.utc(2008, 9, 1, 10, 5, 0) }
  let(:commentaire) { Timecop.freeze(time) { create :commentaire } }
  let(:decorator) { commentaire.decorate }

  describe 'created_at_fr' do
    subject { decorator.created_at_fr }

    context 'when created_at have a value' do
      it { is_expected.to eq time.localtime.strftime('%d/%m/%Y - %H:%M') }
    end
  end
end
