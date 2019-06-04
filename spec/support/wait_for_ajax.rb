module WaitForAjax
  def wait_for_ajax
    expect(page).to have_selector('body[data-active-requests-count="0"]')
  end
end

RSpec.configure do |config|
  config.include WaitForAjax, type: :feature
end
