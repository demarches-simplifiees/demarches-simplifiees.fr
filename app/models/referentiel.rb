# frozen_string_literal: true

class Referentiel < ApplicationRecord
  has_many :items, class_name: 'ReferentielItem', dependent: :destroy
  has_many :types_de_champ, inverse_of: :referentiel, dependent: :nullify

  def headers_with_path
    headers.map { [_1, self.class.header_to_path(_1)] }
  end

  def drop_down_options
    path = self.class.header_to_path(headers.first)
    items.map { _1.value(path) }
  end

  def options_for_select
    path = self.class.header_to_path(headers.first)
    items.map { [_1.value(path), _1.id.to_s] }
  end

  def options_for_path(path)
    items.to_set { _1.value(path) }.compact.sort.map { [_1, _1] }
  end

  def self.header_to_path(header)
    header.parameterize.underscore
  end
end
