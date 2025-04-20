require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  test "should get rss" do
    get feeds_rss_url
    assert_response :success
  end
end
