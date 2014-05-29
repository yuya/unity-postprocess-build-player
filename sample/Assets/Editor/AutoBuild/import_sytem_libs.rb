#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "pathname"
require "xcodeproj"

# project_path = ARGV[0]
# build_env    = ARGV[1]
proj_path  = "/Users/yuya/Workspace/unity-postprocess-build-player/tmp/iOS/Unity-iPhone.xcodeproj"
build_env  = "Product"
libraries  = [
  "sqlite3"
]
framework_list = [
  "AdSupport",
  "Security",
  "CoreTelephony",
  "StoreKit",
  "Security",
  "CoreText",
  "MessageUI",
  "Twitter"
]

@project     = Xcodeproj::Project.open proj_path
@build_phase = @project.objects.find { |obj| obj.is_a? Xcodeproj::Project::PBXFrameworksBuildPhase }

def import_system_frameworks(framework_list)
  @project.targets.each do |target|
    if target.name == "Unity-iPhone-simulator" then
      next
    end

    frameworks = target.add_system_framework framework_list
  end
end

def set_framework_attributes(framework_list, option = :optional)
  @project.targets.each do |target|
    if target.name == "Unity-iPhone-simulator" then
      next
    end

    settings = { "ATTRIBUTES" => (option == :optional) ? ["Weak"] : ["Strong"] }

    framework_list.each { |framework|
      matched = @build_phase.files_references.find { |phase|
        (phase.is_a? Xcodeproj::Project::Object::PBXFileReference) && (phase.name =~ /^#{framework}/)
      }

      matched.build_files[0].settings = settings
    }
  end
end

import_system_frameworks framework_list
set_framework_attributes framework_list, :optional
# set_atttributes fram

@project.save
