# HKTV

Command line utilities to find and download HKTV videos.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hktv'
```

And then execute:

    $ bundle

Or install it via:
    
    $ gem install hktv


## Prerequisite

- Ruby 2.x
- Only tested on OS X Yosemite, it may work on Linux.
- Requries ``ffmpeg`` for combine video.

## Usage

### Login to HKTV

Login to HKTV. This is required for download video.

    $ hktv login

### List all video of HKTV

Print a comma sepeated list of programs.

    $ hktv list "選戰"
    選戰 第1集 第1節
    選戰 第1集 第2節
    ...
    選戰 第7集 第3節
    選戰 第7集 第4節

### Download an Episode

Download all video files of an episode, and merge them into single file.

    $ hktv download "選戰 第7集"
    Downloading: 選戰 第7集 第1節
    Downloading: 選戰 第7集 第2節
    Downloading: 選戰 第7集 第3節
    Downloading: 選戰 第7集 第4節
    Merge videos into 選戰_第7集.mp4

## Contributing

1. Fork it ( https://github.com/siuying/ruby-hktv/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
