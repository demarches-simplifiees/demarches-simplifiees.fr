require 'spec_helper'

describe 'admin/instructeurs/show.html.haml', type: :view do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  let(:assign_gestionnaires) { procedure.gestionnaires }
  let(:not_assign_gestionnaires) { admin.gestionnaires.where.not(id: assign_gestionnaires.ids) }

  before do
    assign(:procedure, procedure)
    assign(:gestionnaire, Gestionnaire.new)

    assign(:instructeurs_assign, (smart_listing_create :instructeurs_assign,
      assign_gestionnaires,
      partial: "admin/instructeurs/list_assign",
      array: true))

    assign(:instructeurs_not_assign, (smart_listing_create :instructeurs_not_assign,
      not_assign_gestionnaires,
      partial: "admin/instructeurs/list_not_assign",
      array: true))
  end

  context 'when admin have none instructeur ' do
    before do
      render
    end

    it { expect(rendered).to have_content('Aucun de disponible') }

    context 'when administrateur have none instructeur assign' do
      it { expect(rendered).to have_content('Aucun d\'affecté') }
    end
  end

  context 'when administrateur have two instructeur' do
    let!(:instructeur_1) { create :gestionnaire, email: 'plop@plop.com', administrateurs: [admin] }
    let!(:instructeur_2) { create :gestionnaire, email: 'plip@plop.com', administrateurs: [admin] }

    before do
      not_assign_gestionnaires.reload
      assign_gestionnaires.reload

      assign(:instructeurs_assign, (smart_listing_create :instructeurs_assign,
        assign_gestionnaires,
        partial: "admin/instructeurs/list_assign",
        array: true))

      assign(:instructeurs_not_assign, (smart_listing_create :instructeurs_not_assign,
        not_assign_gestionnaires,
        partial: "admin/instructeurs/list_not_assign",
        array: true))

      render
    end

    it { expect(rendered).to have_content(instructeur_1.email) }
    it { expect(rendered).to have_content(instructeur_2.email) }
  end
end
