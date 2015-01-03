require_relative "./hktv/version"

require "httparty"
require 'retriable'

require "digest/md5"
require "json"
require 'securerandom'

class HKTV
  include HTTParty

  # set by auth
  attr_accessor :access_token, :expires_date, :refresh_token

  # set by token
  attr_accessor :user_id, :user_level, :ott_token, :ott_expires_date

  base_uri 'webservices.hktv.com.hk'
  headers "Content_type" => "application/x-www-form-urlencoded", "Accept" => "*/*"

  API_BASE = "/"
  API_TOKEN = "account/token"
  API_FEATURE = "lists/getFeature"
  API_PLAYLIST = "playlist/request"  

  API_SECRET = "43e814b31f8764756672c1cd1217d775"
  API_KI = "12"
  API_VID = "1"

  API_MUID = "0"
  API_DEVICE = "USB Android TV"
  API_MANUF = "hktv-ruby"
  API_MODEL = "Ruby"
  API_OS = "0.1.0"
  API_MX_RES = "1920"
  API_NETWORK = "fixed"

  # hardcoded user in HKTV app
  API_USERNAME = "hktv_ios"
  API_PASSWORD = "H*aK#)HM248"

  def initialize(uuid: SecureRandom.uuid, access_token: nil, expires_date: nil, refresh_token: nil, user_id: "1", user_level: nil, ott_token: nil, ott_expires_date: nil)
    @uuid = uuid
    @access_token = access_token
    @expires_date = expires_date
    @refresh_token = refresh_token
    @ott_token = ott_token    
    @ott_expires_date = ott_expires_date
    @user_id = user_id
    @user_level = user_level
  end

  # return true if client has authenticated, false otherwise
  def authenticated?
    if @expires_date && Time.now > @expires_date
      @access_token = nil
      @expires_date = nil
      @refresh_token = nil
    end

    !@access_token.nil?
  end

  # return true if client needs ott token
  def needs_ott_token?
    return @ott_token.nil? || (@ott_expires_date && Time.now > @ott_expires_date)
  end

  # Authenticate user with given username/password
  # return true if success
  def auth(username, password)
    options = {
      "grant_type" => "password", 
      "username" => username,
      "password" => password
    }

    auth = self.class.post("https://www.hktvmall.com:443/hktvwebservices/oauth/token?rand=#{Time.now.to_i}", body: options, basic_auth: {username: API_USERNAME, password: API_PASSWORD})
    @access_token = auth["access_token"]
    @expires_date = Time.now + auth["expires_in"]
    @refresh_token = auth["refresh_token"]
    !@access_token.nil?
  end

  # get the OTT token
  def ott_token
    result = nil

    # hktv api just fail for unknown reason, retry to workaround it
    Retriable.retriable(tries: 20, base_interval: 1.0) do
      if authenticated?
        result = self.class.get("https://www.hktvmall.com:443/hktvwebservices/v1/hktv/ott/token?rand=#{Time.now.to_i}", headers: headers)
      else
        ts = Time.now.to_i
        options = {
          "ki" => API_KI, 
          "ts" => ts.to_s,
          "s" => sign_request(API_TOKEN, ts, [API_KI, API_MUID]),
          "muid" => API_MUID
        }
        result = self.class.post(API_BASE + API_TOKEN, body: options, headers: headers)
      end

      if result["errors"]
        raise result["errors"].first["message"]
      end

      result
    end

    @user_id = result["user_id"]
    @user_level = result["user_level"]
    @ott_token = result["token"]

    !@user_id.nil?
  end

  def logout
    @user_id = nil
    @user_level = nil
    @ott_token = nil

    @access_token = nil
    @expires_in = nil
    @refresh_token = nil

    if authenticated?
      self.class.post("https://www.hktvmall.com:443/hktvwebservices/v1/customers/current/logout", headers: headers)["success"]
    else
      true
    end
  end

  # get a playlist of given video
  # @param video_id the video ID
  # @return URL to the playlist
  def playlist(video_id="1")
    self.ott_token if needs_ott_token?

    ts = Time.now.to_i
    signature = sign_request(API_PLAYLIST, ts, [API_DEVICE, API_KI, API_MODEL, API_MANUF, API_MX_RES, API_NETWORK, API_OS, @ott_token, @uuid, @user_id, video_id])
    options = {
      "d" => API_DEVICE,
      "ki" => API_KI,
      "mdl" => API_MODEL,
      "mf" => API_MANUF,
      "mxres" => API_MX_RES,
      "net" => API_NETWORK,
      "os" => API_OS,
      "t" => @ott_token,
      "udid" => @uuid,
      "uid" => @user_id,
      "vid" => video_id,
      "ts" => ts.to_s,
      "s" => signature
    }
    self.class.post(API_BASE + API_PLAYLIST, body: options)["m3u8"]
  end

  # list featured video on HKTV
  # @return nested array of video
  def features(lang="zh-Hant", count=999)
    self.ott_token if needs_ott_token?

    ts = Time.now.to_i
    options = {
      "lang" => lang,
      "lim" => count.to_s,
      "lut" => "0",
      "_" => ts.to_s,
      "ofs" => "0"
    }
    self.class.get("http://ott-www.hktvmall.com/api/lists/getFeature", query: options)["videos"]
  end

  # list programs on HKTV
  # @return nested array of video
  def programs(lang="zh-Hant", count=999)
    ts = Time.now.to_i
    options = {
      "lang" => lang,
      "lim" => count.to_s,
      "lut" => "0",
      "_" => ts.to_s,
      "ofs" => "0"
    }
    self.class.get("http://ott-www.hktvmall.com/api/lists/getProgram", query: options)["videos"]
  end

  def to_hash
    json = {
      uuid: @uuid,
      access_token: @access_token,
      refresh_token: @refresh_token,
      user_id: @user_id,
      user_level: @user_level,
      ott_token: @ott_token
    }
    json[:expires_date] = @expires_date.to_i if @expires_date
    json[:ott_expires_date] = @ott_expires_date.to_i if @ott_expires_date
    return json
  end

  def self.from_hash(json)
    if json[:"expires_date"]
      json[:expires_date] = Time.at(json[:expires_date])
    end
    if json[:ott_expires_date]
      json[:ott_expires_date] = Time.at(json[:ott_expires_date])
    end
    return HKTV.new(json)
  end

  private
  def headers
    if authenticated?
      return {
        "Authorization" => "Bearer #{@access_token}"
      }
    else
      return {}
    end
  end

  def sign_request(path, timestamp, params=[])
    return Digest::MD5.hexdigest(path + params.join("") + API_SECRET + timestamp.to_s)
  end
end
