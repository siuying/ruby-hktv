require 'commander'
require 'fileutils'
require 'csv'
require 'open3'
require_relative './version'
require_relative '../hktv'

class HKTV
  class Command
    include Commander::Methods

    CONFIG_DIR = "#{Dir.home}/.hktv"
    CONFIG_FILE = "#{Dir.home}/.hktv/hktv.json"

    def load
      hktv = nil

      if !File.exists?(CONFIG_DIR)
        FileUtils.mkdir_p(CONFIG_DIR)
      end

      if File.exists?(CONFIG_FILE)
        hktv = HKTV.from_hash(JSON(File.open(CONFIG_FILE).read, symbolize_names: true))
      else
        hktv = HKTV.new
      end

      return hktv
    end

    def save(hktv)
      if !File.exists?(CONFIG_DIR)
        FileUtils.mkdir_p(CONFIG_DIR)
      end

      File.open(CONFIG_FILE, 'w') do |f|
        f.write(JSON.generate(hktv.to_hash))
      end
    end

    def run
      program :name, 'hktv'
      program :version, HKTV::VERSION
      program :description, 'Lookup HKTV videos'
      program :help_formatter, :compact

      command :login do |c|
        c.syntax = 'hktv login'
        c.description = 'Login to HKTV'
        c.action do |args, options|
          username = ask("username: ")
          password = ask("password: ") { |q| q.echo = "*" }

          hktv = self.load
          hktv.logout if hktv.authenticated?

          if hktv.auth(username, password)
            puts "Logged in"
            self.save(hktv)
          end
        end
      end

      command :list do |c|
        c.syntax = 'hktv list'
        c.description = 'Print a comma sepeated list of programs of HKTV'
        c.option '--title title', String, 'Only return programs matching given title regexp'
        c.option '--keys keys', String, 'Output data keys, by default "title,video_id", available: [title, video_id, category, thumbnail, url, duration]'
        c.option '--playlist', 'Fetch the playlist URL. By default the URL is not fetched.'

        c.action do |args, options|
          options.default category: "DRAMA", playlist: false, keys: "title,video_id"
          hktv = self.load
          programs = extract_root_videos(hktv.programs)
          keys = options.keys.split(",")

          if options.category
            programs = programs.select {|program| program["category"] == options.category }
          end

          if options.title
            regexp = Regexp.new(options.title)
            programs = programs.select {|program| program["title"] =~ regexp }
          end

          if options.playlist
            programs = programs.select {|program| program["url"] = hktv.playlist(program["video_id"]) }
          end

          if options.playlist && !keys.include?("url") && options.keys == "title,video_id"
            keys << "url"
          end

          rows = programs.map do |program|
            keys.collect do |key|
              program[key]
            end.to_csv
          end

          puts rows.join("")
        end
      end

      command :download do |c|
        c.syntax = 'hktv download [episode-title] (output-filename)'
        c.description = 'Download an episode of HKTV program.'

        c.action do |args, options|
          hktv = self.load

          unless hktv.authenticated?
            puts "You have not login! Try \"hktv login\"" 
            raise "Not logged in."
          end

          title = args[0]
          filename = args[1]
          raise "Missing episode title" if title.nil?

          filename = filename_with_title(title, ".mp4") if filename.nil?
          programs = extract_root_videos(hktv.programs)
          regexp = Regexp.new(title)
          programs = programs.select {|program| program["title"] =~ regexp }

          if programs.size == 0
            puts "No video matching \"#{title}\""
            raise "Video not found"
          end

          # fetch playlist url
          programs.each {|program| program["url"] = hktv.playlist(program["video_id"]) }

          # download playlist and merge them
          download_and_merge_programs(programs, filename)      
        end
      end

      run!
    end

    private
    def extract_root_videos(videos)
      videos.collect do |video|
        if video["child_nodes"]
          extract_root_videos(video["child_nodes"])
        else
          video
        end
      end.flatten
    end

    def filename_with_title(title, ext=".ts")
      title.gsub(/\s/, "_") + ext
    end

    def download_and_merge_programs(videos, output)
      temp_files = videos.map {|video| filename_with_title(video["title"]) }
      failed = false

      begin
        # download the video and convert them into ts file
        # https://trac.ffmpeg.org/wiki/Concatenate
        videos.each do |video|
          url = video["url"]
          title = video["title"]
          puts "Downloading: #{title}"
          `ffmpeg -i \"#{url}\" -c copy -bsf:v h264_mp4toannexb -f mpegts \"#{filename_with_title(title)}\" 2> /dev/null`
          if $?.to_i != 0
            puts "Failed download file."
          end
        end

        # losslessly merge these ts
        puts "Merge videos into #{output}"
        `ffmpeg -f mpegts -i \"concat:#{temp_files.join("|")}\" -c copy -bsf:a aac_adtstoasc \"#{output}\" 2> /dev/null`
        if $?.to_i != 0
          puts "Failed merging file."
        end
      ensure 
        puts "Remove temp file: #{temp_files.join(" ")}"
        `rm #{temp_files.join(" ")}`
      end
    end
  end
end