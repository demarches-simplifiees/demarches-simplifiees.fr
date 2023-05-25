describe 'Using Visa field', js: true do
  include ActiveJob::TestHelper

  let(:password) { TEST_PASSWORD }
  let!(:instructeur1) { create(:instructeur, password: password) }
  let!(:instructeur2) { create(:instructeur, password: password) }
  let!(:instructeur3) { create(:instructeur, password: password) }

  let!(:procedure) { create(:procedure, :published, :with_visa, instructeurs: [instructeur1, instructeur2, instructeur3]) }
  let!(:dossier) { create(:dossier, :en_construction, :with_entreprise, procedure: procedure) }
  let(:etablissement_geo_adresse_lat) { "40.7143528" }
  let(:etablissement_geo_adresse_lon) { "-74.0059731" }
  let(:departements) { [['01 - Ain', '01']] }
  let(:regions) { [['Normandie', '28']] }

  before do
    Geocoder::Lookup::Test.add_stub(
      dossier.etablissement.geo_adresse, [
        {
          'coordinates' => [etablissement_geo_adresse_lat.to_f, etablissement_geo_adresse_lon.to_f]
        }
      ]
    )
    allow_any_instance_of(EditableChamp::DepartementsComponent).to receive(:options).and_return(departements)
    allow_any_instance_of(EditableChamp::RegionsComponent).to receive(:options).and_return(regions)
  end

  scenario 'instructor1 cannot validate visa', :js do
    login_as instructeur1.user, scope: :user
    visit instructeur_dossier_path(procedure, dossier)

    click_on 'Annotations privées'
    expect(page).to have_current_path(annotations_privees_instructeur_dossier_path(dossier.procedure, dossier))

    expect(page).to have_field('visa_to_test', disabled: true)
  end

  scenario 'instructor2 can validate visa', :js do
    login_as instructeur2.user, scope: :user
    visit instructeur_dossier_path(procedure, dossier)

    click_on 'Annotations privées'
    expect(page).to have_current_path(annotations_privees_instructeur_dossier_path(dossier.procedure, dossier))

    expect(page).to have_field('visa_to_test', disabled: false)
    ensure_visa_is_visible
    check('visa_to_test')
    expect(page).to have_current_path(annotations_privees_instructeur_dossier_path(dossier.procedure, dossier))
    expect(page).to have_field('visa_to_test', checked: true)

    check_fields_before_visa_are_disabled
    check_fields_after_visa_are_enabled
  end

  def check_fields_before_visa_are_disabled
    check_fields('preceding', true)
  end

  def check_fields_after_visa_are_enabled
    check_fields('following', false)
  end

  def check_fields(axe, disabled)
    visa_label_path = ".//label[normalize-space(text())='visa_to_test']"
    divs_path = visa_label_path + "/parent::div/#{axe}-sibling::div"
    fields_path = divs_path + "//*[contains(@name, 'dossier')]"
    sleep(2)
    wait_until { has_css?('.editable-champ-address > input') }
    fields = page.all(:xpath, fields_path)
    fields.each do |field|
      expect(field.disabled?).to be disabled
    end
  end

  def ensure_visa_is_visible
    page.execute_script('window.scrollTo(0, document.body.scrollHeight)')
  end
end
