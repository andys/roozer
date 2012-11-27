class TransactionsController < ApplicationController
  respond_to :json
  
  def show
    path = Path.find("/#{params[:path]}")
    respond_with(path)
  end
  
  def create
  end
  
  def destroy
  end
  
end
