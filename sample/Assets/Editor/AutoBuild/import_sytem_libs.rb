#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "pathname"
require "xcodeproj"

# proj_path = ARGV[0]
# build_env = ARGV[1]
build_path = ARGV[0] ? ARGV[0] : "/Users/yuya/Workspace/unity-postprocess-build-player/tmp/iOS/"
build_env  = ARGV[1] ? ARGV[1] : "Product"
unity_ver  = ARGV[2] ? ARGV[2].to_f : "2.3.2"
proj_path  = "#{build_path}Unity-iPhone.xcodeproj"

system = {
  "frameworks" => [
    "AdSupport",
    "AssetsLibrary",
    "CFNetwork",
    "CoreData",
    "CoreGraphics",
    "CoreTelephony",
    "Security",
    "MessageUI"
  ],
  "libraries" => [
    "sqlite3"
  ]
}

external = {
  "root" => [
    "Default-568h@2x.png",
    "Default-Landscape.png",
    "Default-Landscape@2x.png",
    "Default-Portrait.png",
    "Default-Portrait@2x.png",
    "Default.png",
    "Default@2x.png",
    "Icon-60@2x.png",
    "Icon-72.png",
    "Icon-72@2x.png",
    "Icon-76.png",
    "Icon-76@2x.png",
    "Icon-144.png",
    "Icon-Small-40.png",
    "Icon-Small-40@2x.png",
    "Icon-Small-50.png",
    "Icon-Small-50@2x.png",
    "Icon-Small.png",
    "Icon-Small@2x.png",
    "Icon.png",
    "Icon@2x.png",
    "Info.plist",
    "iTuneArtwork.png",
    "iTuneArtwork@2x.png"
  ],
  "classes" => [
    "Classes/UnityAppController.mm",
    "Classes/UnityAppController.h",
    "Classes/UI/UnityView.mm"
  ],
  "frameworks" => [
    "Frameworks/Nakamap.bundle",
    "Frameworks/Nakamap.framework"
  ],
  "libraries" => [
    # "Libraries/json-framework-3.2.0/",
    # "Libraries/SVProgressHUD/",
    "Libraries/libeeafPlugin.a",
    "Libraries/libSmacTracking.a",
    "Libraries/NakamapCall.h",
    "Libraries/Noah_JSON.h",
    "Libraries/NoahAlert.h",
    "Libraries/NoahBanner.h",
    "Libraries/NoahBannerWallViewController.h",
    "Libraries/NoahConnect.h",
    "Libraries/NoahConst.h",
    "Libraries/NoahImage.h",
    "Libraries/NoahManager.h",
    "Libraries/NoahOffer.h",
    "Libraries/NoahOptIn.h",
    "Libraries/NoahProtocol.h",
    "Libraries/NoahShared.h",
    "Libraries/NoahUnityPlugin.h",
    "Libraries/NoahUtil.h",
    "Libraries/SmacTracking.h"
  ]
}

libraries = [
  "sqlite3"
]
frameworks = [
  "AdSupport",
  "AssetsLibrary",
  "CFNetwork",
  "CoreData",
  "CoreGraphics",
  "CoreTelephony",
  "Security",
  "MessageUI"
]
weak_frameworks = [
  "AdSupport",
  "UIKit"
]

@project     = Xcodeproj::Project.open proj_path
@target      = @project.targets.find { |target| target.name == "Unity-iPhone" }
@build_phase = @project.objects.find { |obj| obj.is_a? Xcodeproj::Project::PBXFrameworksBuildPhase }
@groups      = {
  "classes"    => @project.groups.find { |group| group.path == "Classes"    },
  "libraries"  => @project.groups.find { |group| group.path == "Libraries"  },
  "frameworks" => @project.groups.find { |group| group.name == "Frameworks" }
}

@base_resource_path = "/Users/yuya/Desktop/ios_tmp_files/"
@build_path = ARGV[0] ? ARGV[0] : "/Users/yuya/Workspace/unity-postprocess-build-player/tmp/iOS/"

# puts external["classes"]
# ss puts @project.groups.find { |group| group.name ? group.name == "Classes" : group.path == "Classes" }
# puts @project.groups.find { |group| group.path == "Classes" }

unless @target then exit end

def set_framework_search_paths(paths = "\"$(SRCROOT)\"")
  conf_objects = @target.build_configurations.objects

  conf_objects.each do |obj|
    settings = obj.build_settings

    unless settings["FRAMEWORK_SEARCH_PATHS"]
      settings["FRAMEWORK_SEARCH_PATHS"] = "\"$(SRCROOT)\""
    end
  end
end

def import_system_libraries(libraries)
  @target.add_system_libraries(libraries)
end

def import_system_frameworks(frameworks)
  @target.add_system_frameworks(frameworks)
end


def import_external_classes(classes)
  classes.each { |klass|
    FileUtils.cp_r @base_resource_path + klass, @build_path + klass
  }
end

def import_external_frameworks(frameworks)
  frameworks.each { |framework|
    unless @build_phase.files_references.find { |file| file.name =~ /#{framework}$/ }
      ref = @groups["frameworks"].new_file @base_resource_path + framework
      
      @build_phase.add_file_reference ref
    end
  }
end

def import_external_libraries(libraries)
  libraries.each { |library|
    unless @build_phase.files_references.find { |file| file.name =~ /#{library}$/ }
      ref = @groups["libraries"].new_file @base_resource_path + library

      @build_phase.add_file_reference ref
    end
  }
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

# set_framework_search_paths "\"$(SRCROOT)\""
# import_system_libraries libraries
# import_system_frameworks frameworks
# set_frameworks_attribute weak_frameworks, :optional

# import_external_classes external["classes"]
import_external_frameworks external["frameworks"]
import_external_libraries external["libraries"]

@project.save
