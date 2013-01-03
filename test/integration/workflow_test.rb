require 'test_helper'

class WorkflowTest < ActionDispatch::IntegrationTest
  setup do
    cleanup_previous_test_data
  end
  
  test 'workflow' do
    json_get('/')
    assert_equal 200, response.status
    assert_equal 'dir', json_response['type']
    
    json_post('/test/integration/1', value: {'my' => 'test'})
    assert_equal 201, response.status
    puts json_response.inspect
  end
  
protected

  [:get, :post, :put, :delete, :patch].each do |meth|
    define_method("json_#{meth}") do |path,params={}|
      #puts "\n\nRequest: #{meth} #{params.inspect} to #{path.inspect} (#{caller.first})"
      send(meth, "#{path}", params,
        "HTTP_ACCEPT" => "application/json"
       #"HTTP_AUTHORIZATION" => ("Basic " + Base64::encode64("#{@user.username}:#{@user.api_key}"))
      )
      #puts "json_#{meth} did not receive a 200 response:  #{response.status}:\n#{response.body.inspect}" unless response.status.to_s =~ /^2\d+/

      begin
        x = ActiveSupport::JSON.decode(response.body)
        #puts "Response: #{x.inspect} (#{caller.first})"
        x
      rescue => e
        response.body
      end
    end
  end

  def assert_response(r)
    assert_match /^#{r.to_s[0]}\d\d/, response.status.to_s
  end

end
