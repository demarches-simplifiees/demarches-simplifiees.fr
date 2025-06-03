# frozen_string_literal: true

# Rails ViewComponent for the dsfr modal componenent
# see : https://www.systeme-de-design.gouv.fr/composants-et-modeles/composants/modale/
class Dsfr::ModalComponent < ApplicationComponent
  # Modal's content
  renders_one :body

  attr_reader :modal_id, :trigger_using_link, :trigger_object_title, :modal_title, :trigger_object_extra_classes

  # Component constructor
  # @param id [String] The id of the modal, used to link the trigger object and the modal
  # @param trigger_object_title [String] The title of the object that triggers the modal
  # @param modal_title [String] The title of the modal
  # @param trigger_using_link [Boolean] Whether to trigger the modal using a link or a button (default: true)
  # @param trigger_object_extra_classes [String] Additional classes to add to the trigger object (button or link)
  def initialize(id, modal_title, trigger_object_title, trigger_using_link: false, trigger_object_extra_classes: "")
    @modal_id = "modal-#{id}"
    @trigger_object_title = trigger_object_title
    @modal_title = modal_title
    @trigger_using_link = trigger_using_link
    @trigger_object_extra_classes = trigger_object_extra_classes
  end

  private

  # Returns the value of the on-click attribute for the trigger object (button or link)
  # @return [String] the value of the on-click attribute for the trigger object (button or link) could be nil if the trigger object is a button
  def on_click_value
    return (@trigger_using_link) ? "window.history.back()" : nil
  end
end
