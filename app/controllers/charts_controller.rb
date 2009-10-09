class ChartsController < ApplicationController
  def show
    @scaling = Scaling.for(Chart).find(params[:scaling_id])
    @chart = @scaling.chart
    @date = Date.parse(params[:date])
    respond_to do |format|
      format.js { render :layout => false }
      # format.json { render :json => { "data" => @scaling.data(date), "options" => @scaling.options(date) } }
    end
  end
end
