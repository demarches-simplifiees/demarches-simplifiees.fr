# frozen_string_literal: true

describe FollowCommentaireGroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:gestionnaire) }
    it { is_expected.to belong_to(:groupe_gestionnaire) }
    it { is_expected.to belong_to(:sender).optional }
  end
end
