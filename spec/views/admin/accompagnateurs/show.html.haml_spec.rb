require 'spec_helper'

describe 'admin/accompagnateurs/show.html.haml', type: :view do
  let(:admin) { create(:administrateur) }
  let(:procedure) { create :procedure, administrateur: admin }

  let(:assign_gestionnaires) { procedure.gestionnaires }
  let(:not_assign_gestionnaires) { admin.gestionnaires.where.not(id: assign_gestionnaires.ids) }

  before do
    assign(:procedure, procedure)

    assign(:accompagnateurs_assign, (smart_listing_create :accompagnateurs_assign,
                                                          assign_gestionnaires,
                                                          partial: "admin/accompagnateurs/list_assign",
                                                          array: true))

    assign(:accompagnateurs_not_assign, (smart_listing_create :accompagnateurs_not_assign,
                                                              not_assign_gestionnaires,
                                                              partial: "admin/accompagnateurs/list_not_assign",
                                                              array: true))
  end

  context 'when admin have none accompagnateur ' do
    before do
      render
    end

    it { expect(rendered).to have_content('Aucun de disponible') }

    context 'when administrateur have none accompagnateur assign' do
      it { expect(rendered).to have_content('Aucun d\'affecté') }
    end
  end

  context 'when administrateur have two accompagnateur' do
    let!(:accompagnateur_1) { create :gestionnaire, email: 'plop@plop.com', administrateurs: [admin] }
    let!(:accompagnateur_2) { create :gestionnaire, email: 'plip@plop.com', administrateurs: [admin] }

    before do
      not_assign_gestionnaires.reload
      assign_gestionnaires.reload

      assign(:accompagnateurs_assign, (smart_listing_create :accompagnateurs_assign,
                                                            assign_gestionnaires,
                                                            partial: "admin/accompagnateurs/list_assign",
                                                            array: true))

      assign(:accompagnateurs_not_assign, (smart_listing_create :accompagnateurs_not_assign,
                                                                not_assign_gestionnaires,
                                                                partial: "admin/accompagnateurs/list_not_assign",
                                                                array: true))

      render
    end

    it { expect(rendered).to have_content(accompagnateur_1.email) }
    it { expect(rendered).to have_content(accompagnateur_2.email) }
  end
end