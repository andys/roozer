class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter do
    $doozer.reconnect
    true
  end
end
