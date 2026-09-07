require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Generous wait: suites run in parallel workers sharing CPU with several
  # headless browsers, and CI runners are slower than dev machines.
  Capybara.default_max_wait_time = 5
end
