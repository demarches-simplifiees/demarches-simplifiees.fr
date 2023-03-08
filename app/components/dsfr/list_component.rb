class Dsfr::ListComponent < ApplicationComponent
  renders_many :items
  renders_one :empty
end
