# == Schema Information
#
# Table name: individuals
#
#  id                                        :integer          not null, primary key
#  api_particulier_caf_code_postal           :string
#  api_particulier_caf_numero_d_allocataire  :string
#  api_particulier_dgfip_numero_fiscal       :string
#  api_particulier_dgfip_reference_de_l_avis :string
#  api_particulier_donnees                   :jsonb
#  api_particulier_mesri_ine                 :string
#  api_particulier_pole_emploi_identifiant   :string
#  birthdate                                 :date
#  gender                                    :string
#  nom                                       :string
#  prenom                                    :string
#  created_at                                :datetime
#  updated_at                                :datetime
#  dossier_id                                :integer
#
class Individual < ApplicationRecord
  include AutoStripConcern

  belongs_to :dossier, optional: false

  auto_strip_attributes :api_particulier_caf_code_postal, :api_particulier_caf_numero_d_allocataire,
    :api_particulier_dgfip_numero_fiscal, :api_particulier_dgfip_reference_de_l_avis,
    :api_particulier_mesri_ine,
    delete_whitespaces: true

  validates :dossier_id, uniqueness: true
  validates :gender, presence: true, allow_nil: false, on: :update
  validates :nom, presence: true, allow_blank: false, allow_nil: false, on: :update
  validates :prenom, presence: true, allow_blank: false, allow_nil: false, on: :update

  validates :api_particulier_dgfip_numero_fiscal, presence: true, length: { minimum: 13, maximum: 14 },
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.dgfip_mandatory? }
  validates :api_particulier_dgfip_reference_de_l_avis, presence: true, length: { minimum: 13, maximum: 14 },
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.dgfip_mandatory? }
  validates :api_particulier_caf_numero_d_allocataire, presence: true, length: { is: 7 },
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.caf_mandatory? }
  validates :api_particulier_caf_code_postal, presence: true, length: { is: 5 },
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.caf_mandatory? }
  validates :api_particulier_pole_emploi_identifiant, presence: true,
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.pole_emploi_mandatory? }
  validates :api_particulier_mesri_ine, presence: true,
    on: :update, if: -> { Flipper.enabled?(:api_particulier) && check_scope_sources_service.etudiant_mandatory? }

  GENDER_MALE = "M."
  GENDER_FEMALE = 'Mme'

  def self.from_france_connect(fc_information)
    new(
      nom: fc_information.family_name,
      prenom: fc_information.given_name,
      gender: fc_information.gender == 'female' ? GENDER_FEMALE : GENDER_MALE
    )
  end

  def api_particulier_donnees?(&block)
    Hash(api_particulier_donnees).transform_values(&:presence).compact.any?(&block)
  end

  private

  def check_scope_sources_service
    @check_scope_sources_service ||= APIParticulier::Services::CheckScopeSources.new(
      dossier&.procedure&.api_particulier_scopes,
      dossier&.procedure&.api_particulier_sources
    )
  end
end
