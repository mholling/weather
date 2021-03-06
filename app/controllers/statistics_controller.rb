class StatisticsController < ApplicationController
  def show
    @scaling = Scaling.for(Statistic).find(params[:scaling_id])
    @statistic = @scaling.statistic
    @date = Date.parse(params[:date])
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end
