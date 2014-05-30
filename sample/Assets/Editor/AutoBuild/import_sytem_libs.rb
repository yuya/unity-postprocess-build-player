#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "pathname"
require "xcodeproj"

# proj_path = ARGV[0]
# build_env = ARGV[1]
proj_path = ARGV[0] ? ARGV[0] : "/Users/yuya/Workspace/unity-postprocess-build-player/tmp/iOS/Unity-iPhone.xcodeproj"
build_env = ARGV[1] ? ARGV[1] : "Product"
unity_ver = ARGV[2] ? ARGV[2] : "2.3.2"
# proj_path  = "/Users/yuya/Workspace/unity-postprocess-build-player/tmp/iOS/Unity-iPhone.xcodeproj"
# build_env  = "Product"

File.write("/Users/yuya/Desktop/unity_ver.txt", unity_ver);

libraries = [
  "sqlite3"
]
frameworks = [
  "AdSupport",
  "Security",
  "CoreTelephony"
]
weak_frameworks = [
  "UIKit",
  "AdSupport"
]

@project     = Xcodeproj::Project.open proj_path
@target      = @project.targets.find { |target| target.name == "Unity-iPhone" }
@build_phase = @project.objects.find { |obj| obj.is_a? Xcodeproj::Project::PBXFrameworksBuildPhase }

unless @target then exit end

def import_system_libraries(libraries)
  @target.add_system_libraries libraries
end

def import_system_frameworks(frameworks)
  @target.add_system_frameworks frameworks
end

def set_frameworks_attribute(weak_frameworks, option = :optional)
  settings = { "ATTRIBUTES" => (option == :optional) ? ["Weak"] : ["Strong"] }

  weak_frameworks.each { |framework|
    matched = @build_phase.files_references.find { |file|
      (file.is_a? Xcodeproj::Project::Object::PBXFileReference) && (file.name =~ /^#{framework}/)
    }

    matched.build_files[0].settings = settings
  }
end

import_system_libraries  libraries
import_system_frameworks frameworks
set_frameworks_attribute weak_frameworks, :optional

@project.save
