require "slack"
require 'fileutils'
require "active_support/core_ext/numeric/time"
require "active_support/core_ext/date/calculations"
require "json"

class FileScraper
  attr_reader :token, :dl_dir, :time_threshold

  def initialize(token, dl_dir = "/tmp/slack_files", time_threshold = 2.weeks.ago.to_i)
    @token = token
    @dl_dir = dl_dir
    @time_threshold = time_threshold
  end

  def run
    FileUtils.mkdir_p dl_dir
    Slack.configure { |c| c.token = token }
    download_files
  end

  def file_list
    @file_list ||= cached || files
  end

  def cached
    if File.exist?("/tmp/slack_files.json")
      JSON.parse(File.read("/tmp/slack_files.json"))
    end
  end

  def query_options
    {ts_to: time_threshold.to_i}
  end

  def files(page = 0, paging = {"pages" => 1})
    puts "fetching slack files at page #{page}"
    if paging["pages"] && page < paging["pages"]
      r = Slack::API.new.files_list(query_options.merge(page: page + 1))
      r["files"] + files(page + 1, r["paging"])
    else
      []
    end
  end

  def download_files
    chunked.map do |mod, files|
      Thread.new do
        files.each do |f|
          puts "need to download file at #{f["url"]}"
          `curl #{f["url"]} > #{dl_dir}/#{f["id"]}-#{f["name"].split.join}`
        end
      end
    end.map(&:join)
  end

  def chunked
    file_list.group_by.with_index do |_,i|
      i % thread_count
    end
  end

  def thread_count
    10
  end
end
