RSpec.describe GroupeGestionnaire::GroupeGestionnaireCommentaires::CommentaireComponent, type: :component do
    let(:component) do
      described_class.new(
        commentaire: commentaire,
        connected_user: connected_user
      )
    end
    let(:connected_user) { create(:administrateur) }
    let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: connected_user) }

    subject { render_inline(component).to_html }

    it { is_expected.to include("plop") }

    describe '#commentaire_date' do
      let(:present_date) { Time.zone.local(2018, 9, 2, 10, 5, 0) }
      let(:creation_date) { present_date }
      let(:commentaire) do
        Timecop.freeze(creation_date) { create(:commentaire_groupe_gestionnaire, sender: connected_user) }
      end

      subject do
        Timecop.freeze(present_date) { component.send(:commentaire_date) }
      end

      it 'doesn’t include the creation year' do
        expect(subject).to eq 'le 2 septembre à 10 h 05'
      end

      context 'when displaying a commentaire created on a previous year' do
        let(:creation_date) { present_date.prev_year }
        it 'includes the creation year' do
          expect(subject).to eq 'le 2 septembre 2017 à 10 h 05'
        end
      end

      context 'when formatting the first day of the month' do
        let(:present_date) { Time.zone.local(2018, 9, 1, 10, 5, 0) }
        it 'includes the ordinal' do
          expect(subject).to eq 'le 1er septembre à 10 h 05'
        end
      end
    end

    describe '#commentaire_issuer' do
      let(:commentaire) { create(:commentaire_groupe_gestionnaire, sender: connected_user) }

      subject { component.send(:commentaire_issuer) }

      context 'issuer is connected_user' do
        it 'returns "Vous"' do
          expect(subject).to include 'Vous'
        end
      end
    end
  end
