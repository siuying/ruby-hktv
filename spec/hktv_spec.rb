require_relative "../lib/hktv"
require_relative './spec_helper'
require 'pry'

vcr_options = {:record => :new_episodes, :match_requests_on => [:method, :anonymized_uri]}

describe HKTV do
  describe "Persistence" do
    context "::to_hash" do
      it "should save to Hash" do
        hktv = HKTV.new({uuid: "uuid", access_token: "access_token", expires_date: Time.at(10000000), refresh_token: "refresh_token", user_id: "1", user_level: 1, ott_token: "token", ott_expires_date: Time.at(10000000)})
        hash = hktv.to_hash
        expect(hash).to eql({uuid: "uuid", access_token: "access_token", expires_date: 10000000, refresh_token: "refresh_token", user_id: "1", user_level: 1, ott_token: "token", ott_expires_date: 10000000})
      end
    end

    context "::from_hash" do
      it "should load from Hash" do
        hktv = HKTV.from_hash({uuid: "uuid", access_token: "access_token", expires_date: 10000000, refresh_token: "refresh_token", user_id: "1", user_level: 1, ott_token: "token", ott_expires_date: 10000000})
        hash = hktv.to_hash
        expect(hash).to eql({uuid: "uuid", access_token: "access_token", expires_date: 10000000, refresh_token: "refresh_token", user_id: "1", user_level: 1, ott_token: "token", ott_expires_date: 10000000})
      end
    end
  end

  describe "with no token and auth", :vcr => vcr_options do
    context "#ott_token" do
      it "should retrieve a token" do
        token = subject.ott_token

        expect(token).to be_truthy
        expect(subject.ott_token).to_not be_nil
        expect(subject.user_id).to_not be_nil
        expect(subject.user_level).to_not be_nil
      end
    end

    context "#features" do
      it "should list feature" do
        features = subject.features
        expect(features).to be_a(Array)

        program = features.first
        expect(program["video_id"]).to_not be_nil
        expect(program["video_level"]).to_not be_nil
        expect(program["permission_level"]).to_not be_nil
        expect(program["title"]).to_not be_nil
        expect(program["duration"]).to_not be_nil
      end
    end

    context "#programs" do
      it "should list programs" do
        programs = subject.programs
        expect(programs).to be_a(Array)
        
        program = programs.first
        expect(program["video_id"]).to_not be_nil
        expect(program["video_level"]).to_not be_nil
        expect(program["permission_level"]).to_not be_nil
        expect(program["title"]).to_not be_nil
        expect(program["duration"]).to_not be_nil
      end
    end

    context "#playlist" do
      it "should retrieve a playlist" do
        playlist = subject.playlist("1")
        expect(playlist).to_not be_nil
        expect(playlist).to match(/^http:/)
      end
    end
  end

  describe "with authentication", :vcr => vcr_options  do
    before(:all) do
      @subject = HKTV.new
      VCR.use_cassette 'auth', vcr_options do
        @subject.auth(ENV["HKTV_USER_NAME"], ENV["HKTV_PASSWORD"])
      end
    end

    after(:all) do
      VCR.use_cassette 'auth', vcr_options do
        @subject.logout
      end
    end

    context "#auth" do
      it "should retrieve auth token and token" do
        expect(@subject).to be_authenticated
        expect(@subject.access_token).to_not be_nil
        expect(@subject.expires_date).to_not be_nil
      end
    end

    context "#ott_token" do
      it "should retrieve a token" do
        token = @subject.ott_token
        expect(token).to be_truthy
        expect(@subject.ott_token).to_not be_nil
        expect(@subject.user_id).to_not be_nil
        expect(@subject.user_level).to_not be_nil
      end
    end

    context "#playlist" do
      it "should find playlist for a video" do
        video = @subject.playlist("1670")
        expect(video).to_not be_nil
        expect(video).to match(/^http:/)
      end
    end

    context "#logout" do
      it "should success logout" do
        logout = @subject.logout
        expect(logout).to be_truthy
        expect(@subject.access_token).to be_nil
      end
    end
  end
end