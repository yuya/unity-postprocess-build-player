#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "pathname"
require "xcodeproj"

# proj_path = ARGV[0]
# build_env = ARGV[1]

path = ARGV[0]

File.open("#{path}/hoge.txt", "w") {|f|
  f.write "HOGE"
}


