# == Schema Information
#
# Table name: champs
#
#  id               :integer          not null, primary key
#  data             :jsonb
#  private          :boolean          default(FALSE), not null
#  row              :integer
#  type             :string
#  value            :string
#  created_at       :datetime
#  updated_at       :datetime
#  dossier_id       :integer
#  etablissement_id :integer
#  external_id      :string
#  parent_id        :bigint
#  type_de_champ_id :integer
#
class Champs::PhoneChamp < Champs::TextChamp
  validates :value,
    phone: {
      possible: true,
      allow_blank: true,
      message: I18n.t(:not_a_phone, scope: 'activerecord.errors.messages')
    }, unless: -> { Phonelib.valid_for_country?(value, :pf) }
end
