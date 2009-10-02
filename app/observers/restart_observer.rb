class RestartObserver < ActiveRecord::Observer
  observe :device, :instrument, :chart
  
  def after_save(object)
    if APP_CONFIG.has_key?("restart_observations")
      `#{APP_CONFIG["restart_observations"]}`
      $?.success? ?
        Rails.logger.info("#{Time.zone.now} Restarting weather observation daemon after system configuration change.") :
        Rails.logger.error("#{Time.zone.now} Failed to restart weather observation daemon after system configuration change.")
    end
    true
  end
end
