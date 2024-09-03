# frozen_string_literal: true

class EditableChamp::EpciComponent < EditableChamp::EditableChampBaseComponent
  include ApplicationHelper

  def dsfr_champ_container
    :fieldset
  end

  private

  def departement_options
    APIGeoService.departements.filter(&method(:departement_with_epci?)).map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
  end

  def epci_options
    if @champ.departement?
      APIGeoService.epcis(@champ.code_departement).map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    else
      []
    end
  end

  def departement_select_options
    { selected: @champ.code_departement }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end

  def epci_select_options
    { selected: @champ.code }.merge(@champ.mandatory? ? { prompt: '' } : { include_blank: '' })
  end

  def departement_with_epci?(departement)
    code = departement[:code]
    !code.start_with?('98') && !code.in?(['99', '975', '977', '978'])
  end
end
