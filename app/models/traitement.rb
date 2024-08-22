# frozen_string_literal: true

class Traitement < ApplicationRecord
  belongs_to :dossier, optional: false

  scope :en_construction, -> { where(state: Dossier.states.fetch(:en_construction)) }
  scope :en_instruction, -> { where(state: Dossier.states.fetch(:en_instruction)) }
  scope :termine, -> { where(state: Dossier::TERMINE) }

  scope :for_traitement_time_stats, -> (procedure) do
    includes(:dossier)
      .termine
      .where(dossier: procedure.dossiers.visible_by_administration)
      .where.not('dossiers.depose_at' => nil)
      .where.not(processed_at: nil)
      .order(:processed_at)
  end

  def browser=(browser)
    if browser == 'api'
      self.browser_name = browser
      self.browser_version = 2
      self.browser_supported = true
    elsif browser.present?
      self.browser_name = browser.name
      self.browser_version = browser.version
      self.browser_supported = BrowserSupport.supported?(browser)
    end
  end
end
