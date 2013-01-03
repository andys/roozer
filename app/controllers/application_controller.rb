class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter do
    Roozer::Application.clear_doozer
    true
  end
end
