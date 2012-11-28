require 'test_helper'

class PathsControllerTest < ActionController::TestCase
  setup do
    # delete previous test data
    $doozer.walk('/test/**').each do |file|
      $doozer.del(file.path, Path.current_rev)
    end
  end
  
  test 'show nonexistent path returns 404' do
    assert_raises(ActiveRecord::RecordNotFound) do
      get :show, path: '/test/nonexistent', format:'json'
    end
  end
  
  test 'returns a file with json data correctly' do
    rev = $doozer.set('/test/1', '{"flibble":"foo"}', 0).rev
    get :show, path: 'test/1', format:'json'
    assert_response 200
    assert_equal({"path"=>{"name"=>"/test/1", "rev"=>rev, "type"=>"file", "value"=>{"flibble"=>"foo"}}}, json_response)
  end

  test 'directory listing' do
    $doozer.set('/test/2', '', 0)
    $doozer.set('/test/3', '', 0)
    get :show, path: 'test', format:'json'
    assert_response 200
    assert_equal({"path"=>{"name"=>"/test", "rev"=>nil, "type"=>"dir", "value"=>["2", "3"]}} , json_response)
  end

  test 'create valid file' do
    post :create, path: 'test/4', format:'json', value: '{"my":"test"}'
    assert_response 201
    assert_equal({"path"=>{"name"=>"/test/4", "rev"=>nil, "type"=>"file", "value"=>{"my"=>"test"}}}, json_response)
  end

  test 'do not create invalid file' do
    post :create, path: 'test/5', format:'json', value: 'notjson'
    assert_response 422
    
    post :create, path: 'invalidpath!', format:'json', value: '{}'
    assert_response 422
  end

  test 'delete file' do
    $doozer.set('/test/6', '{}', 0) 
    delete :destroy, path: 'test/6', format:'json'
    assert_response 200
  end

  test 'do not overwrite existing file' do
    $doozer.set('/test/7', '', 0)
    post :create, path: 'test/7', format:'json', value: '{}'
    assert_response 422
  end

  test 'deleting a nonexistent file returns 404' do
    assert_raises(ActiveRecord::RecordNotFound) do
      delete :destroy, path: 'test/8', format:'json'
    end
  end

  test 'update existing file' do
    $doozer.set('/test/9', '', 0)
    put :update, path: 'test/9', format:'json', value: '{"my":"test"}'
    puts response.body
    assert_response 204
  end

  test 'update nonexisting file returns 404' do
    assert_raises(ActiveRecord::RecordNotFound) do
      put :update, path: 'test/10', format:'json', value: '{"my":"test"}'
    end
  end

end
