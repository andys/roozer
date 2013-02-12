require 'test_helper'

class PathsControllerTest < ActionController::TestCase
  setup do
    cleanup_previous_test_data
  end

  test 'show nonexistent path returns 404' do
    get :show, p: '/test/nonexistent', format:'json'
    assert_response 404
  end
  
  test 'returns a file with json data correctly' do
    rev = Roozer::Application.doozer.set('/test/1', '{"flibble":"foo"}', 0).rev
    get :show, p: 'test/1', format:'json'
    assert_response 200
    assert_equal({"name"=>"/test/1", "rev"=>rev, "type"=>"file", "value"=>{"flibble"=>"foo"}}, json_response)
  end

  test 'directory listing' do
    Roozer::Application.doozer.set('/test/2', '', 0)
    Roozer::Application.doozer.set('/test/3', '', 0)
    Roozer::Application.doozer.set('/test/fancy.2E.chars-encoding.5F.test', '', 0)
    get :show, p: 'test', format:'json'
    assert_response 200
    assert_equal({"name"=>"/test", "rev"=>nil, "type"=>"dir", "value"=>["2", "3", 'fancy.chars-encoding_test']} , json_response)
  end

  test 'create valid file' do
    post :create, p: 'test/4', format:'json', value: {"my" =>"test"}
    assert_response 201
    assert_equal(
      {"name"=>"/test/4", "rev"=>nil, "type"=>"file", "value"=>{"my"=>"test"}},
      json_response
    )
    assert_equal(
      {"my"=>"test"}.to_json,
      Roozer::Application.doozer.get('/test/4').value
    )
  end

  test 'create a funkily-named file' do
    post :create, p: 'test/fancy.chars-encoding_test', format:'json', value: {"funky" =>"test"}
    assert_response 201
    assert_equal(
      {"name"=>"/test/fancy.chars-encoding_test", "rev"=>nil, "type"=>"file", "value"=>{"funky"=>"test"}},
      json_response
    )
    assert_equal(
      {"funky"=>"test"}.to_json,
      Roozer::Application.doozer.get('/test/fancy.2E.chars-encoding.5F.test').value
    )
  end


  test 'do not create invalid file' do
    post :create, p: "invalidpath\a", format:'json', value: '{}'
    assert_response 422
  end

  test 'delete file' do
    Roozer::Application.doozer.set('/test/6', '{}', 0) 
    delete :destroy, p: 'test/6', format:'json'
    assert_response 200
  end

  test 'do not overwrite existing file' do
    Roozer::Application.doozer.set('/test/7', '', 0)
    post :create, p: 'test/7', format:'json', value: 'lol'
    assert_response 422
  end

  test 'deleting a nonexistent file returns 404' do
    delete :destroy, p: 'test/8', format:'json'
    assert_response 404
  end

  test 'update existing file' do
    Roozer::Application.doozer.set('/test/9', '', 0)
    put :update, p: 'test/9', format:'json', value: {"my" =>"test"}
    assert_response 204

    assert_equal({"my"=>"test"}.to_json, Roozer::Application.doozer.get('/test/9').value)
  end

  test 'update creates file if none exists' do
    put :update, p: 'test/11', format:'json', value: {"my" =>"test"}
    assert_response 204
    
    assert_equal({"my"=>"test"}.to_json, Roozer::Application.doozer.get('/test/11').value)
  end

end
