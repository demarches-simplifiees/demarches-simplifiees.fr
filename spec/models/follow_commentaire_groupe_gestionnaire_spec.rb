# frozen_string_literal: true

describe FollowCommentaireGroupeGestionnaire, type: :model do
  describe 'associations' do
    it do
      is_expected.to belong_to(:gestionnaire)
      is_expected.to belong_to(:groupe_gestionnaire)
      is_expected.to belong_to(:sender).optional
    end
  end
end
