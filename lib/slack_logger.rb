require "logger"
require 'slack-rtmapi'

class SlackLogger
  attr_reader :token

  def initialize(token)
    @token = token
  end

  def rtm_client(token)
    url = SlackRTM.get_url token: token
    client = SlackRTM::Client.new websocket_url: url
    client.on(:message) do |data|
      if data["type"] == "message"
        logger.info(data.to_json)
      end
    end
    client
  end

  def run
    rtm_client(token).main_loop
  end

  def logger
    Logger.new(log_file)
  end

  def log_file
    File.join(__dir__, "..", "logs", "slack_logs_#{Time.now.strftime("%Y%m%d")}.log")
  end
end
