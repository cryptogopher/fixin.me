require "test_helper"

class Default::UnitsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get units_defaults_index_url
    assert_response :success
  end
end
