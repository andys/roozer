require 'test_helper'

class PathsControllerTest < ActionController::TestCase
  setup do
    cleanup_previous_test_data
  end

  test 'show nonexistent path returns 404' do
#    assert_raises(ActiveRecord::RecordNotFound) do
    get :show, p: '/test/nonexistent', format:'json'
    assert_response 404
#    end
  end
  
  test 'returns a file with json data correctly' do
    rev = $doozer.set('/test/1', '{"flibble":"foo"}', 0).rev
    get :show, p: 'test/1', format:'json'
    assert_response 200
    assert_equal({"path"=>{"name"=>"/test/1", "rev"=>rev, "type"=>"file", "value"=>{"flibble"=>"foo"}}}, json_response)
  end

  test 'directory listing' do
    $doozer.set('/test/2', '', 0)
    $doozer.set('/test/3', '', 0)
    get :show, p: 'test', format:'json'
    assert_response 200
    assert_equal({"path"=>{"name"=>"/test", "rev"=>nil, "type"=>"dir", "value"=>["2", "3"]}} , json_response)
  end

  test 'create valid file' do
    post :create, p: 'test/4', format:'json', value: '{"my":"test"}'
    assert_response 201
    assert_equal({"path"=>{"name"=>"/test/4", "rev"=>nil, "type"=>"file", "value"=>{"my"=>"test"}}}, json_response)
    assert_equal({"my"=>"test"}.to_json, $doozer.get('/test/4').value)
  end

  test 'do not create invalid file' do
    post :create, p: 'test/5', format:'json', value: 'notjson'
    assert_response 422
    
    post :create, p: 'invalidpath!', format:'json', value: '{}'
    assert_response 422
  end

  test 'delete file' do
    $doozer.set('/test/6', '{}', 0) 
    delete :destroy, p: 'test/6', format:'json'
    assert_response 200
  end

  test 'do not overwrite existing file' do
    $doozer.set('/test/7', '', 0)
    post :create, p: 'test/7', format:'json', value: '{}'
    assert_response 422
  end

  test 'deleting a nonexistent file returns 404' do
#    assert_raises(ActiveRecord::RecordNotFound) do
      delete :destroy, p: 'test/8', format:'json'
#    end
    assert_response 404
  end

  test 'update existing file' do
    $doozer.set('/test/9', '', 0)
    put :update, p: 'test/9', format:'json', value: '{"my":"test"}'
    puts response.body
    assert_response 204
    
    assert_equal({"my"=>"test"}.to_json, $doozer.get('/test/9').value)
  end

  test 'update nonexisting file returns 404' do
#    assert_raises(ActiveRecord::RecordNotFound) do
      put :update, p: 'test/10', format:'json', value: '{"my":"test"}'
#    end
    assert_response 404
  end

  test 'create overwrites old file if already exists' do
    post :create, p: 'test/11', format:'json', value: '{"my":"test"}'
    assert_response 201
    
    post :create, p: 'test/11', format:'json', value: '{"my":"test2"}'
    assert_response 201
    
    assert_equal({"my"=>"test2"}.to_json, $doozer.get('/test/11').value)
  end


end

