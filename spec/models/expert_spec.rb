RSpec.describe Expert, type: :model do
  describe 'an expert could be add to a procedure' do
    let(:procedure) { create(:procedure) }
    let(:expert) { create(:expert) }

    before do
      procedure.experts << expert
      procedure.reload
    end

    it { expect(procedure.experts).to eq([expert]) }
    it { expect(ExpertsProcedure.where(expert: expert, procedure: procedure).count).to eq(1) }
    it { expect(ExpertsProcedure.where(expert: expert, procedure: procedure).first.allow_decision_access).to be_falsy }
  end

  describe '#merge' do
    let(:old_expert) { create(:expert) }
    let(:new_expert) { create(:expert) }

    subject { new_expert.merge(old_expert) }

    context 'when the old expert does not exist' do
      let(:old_expert) { nil }

      it { expect { subject }.not_to raise_error }
    end

    context 'when an old expert access a procedure' do
      let(:procedure) { create(:procedure) }

      before do
        procedure.experts << old_expert
        subject
      end

      it 'transfers the access to the new expert' do
        expect(procedure.reload.experts).to match_array(new_expert)
      end
    end

    context 'when both expert access a procedure' do
      let(:procedure) { create(:procedure) }

      before do
        procedure.experts << old_expert
        procedure.experts << new_expert
        subject
      end

      it 'removes the old one' do
        expect(procedure.reload.experts). to match_array(new_expert)
      end
    end

    context 'when an old expert has a commentaire' do
      let(:dossier) { create(:dossier) }
      let(:commentaire) { CommentaireService.create(old_expert, dossier, body: "Mon commentaire") }

      before do
        commentaire
        subject
      end

      it 'transfers the commentaire to the new expert' do
        expect(new_expert.reload.commentaires).to match_array(commentaire)
      end
    end

    context 'when an old expert claims for an avis' do
      let!(:avis) { create(:avis, dossier: create(:dossier), claimant: old_expert) }

      before do
        subject
      end

      it 'transfers the claim to the new expert' do
        avis_claimed_by_new_expert = Avis
          .where(claimant_id: new_expert.id, claimant_type: Expert.name)

        expect(avis_claimed_by_new_expert).to match_array(avis)
      end
    end
  end
end
