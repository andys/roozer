ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  def json_response
    ActiveSupport::JSON.decode(response.body)
  end
  
  def cleanup_previous_test_data
    # delete previous test data
    $doozer.walk('/test/**').each do |file|
      $doozer.del(file.path, Path.current_rev)
    end
  end
end
