class ScalingsController < ApplicationController
  def index
    @scalings = Scaling.scoped(:include => :scale)
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def update
    Scaling.find(params[:id]).update_attributes(:position => params[:position]) unless Rails.env.demo?
    render :nothing => true
  end
end
