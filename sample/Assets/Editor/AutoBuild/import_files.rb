#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "pathname"
require "xcodeproj"

system_files = {
  "frameworks" => [
    "-AdSupport",
    "-UIKit",
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

external_files = {
  "root" => [
    "Info.plist",
    "@Default-568h@2x.png",
    "@Default-Landscape.png",
    "@Default-Landscape@2x.png",
    "@Default-Portrait.png",
    "@Default-Portrait@2x.png",
    "@Default.png",
    "@Default@2x.png",
    "@Icon-60@2x.png",
    "@Icon-72.png",
    "@Icon-72@2x.png",
    "@Icon-76.png",
    "@Icon-76@2x.png",
    "@Icon-144.png",
    "@Icon-Small-40.png",
    "@Icon-Small-40@2x.png",
    "@Icon-Small-50.png",
    "@Icon-Small-50@2x.png",
    "@Icon-Small.png",
    "@Icon-Small@2x.png",
    "@Icon.png",
    "@Icon@2x.png",
    "@iTuneArtwork.png",
    "@iTuneArtwork@2x.png"
  ],
  "classes" => [
    "UnityAppController.mm",
    "UnityAppController.h",
    "UI/UnityView.mm"
  ],
  "frameworks" => [
    "@Nakamap.bundle",
    "Nakamap.framework"
  ],
  "libraries" => [
    "libeeafPlugin.a",
    "libSmacTracking.a",
    "NakamapCall.h",
    "Noah_JSON.h",
    "NoahAlert.h",
    "NoahBanner.h",
    "NoahBannerWallViewController.h",
    "NoahConnect.h",
    "NoahConst.h",
    "NoahImage.h",
    "NoahManager.h",
    "NoahOffer.h",
    "NoahOptIn.h",
    "NoahProtocol.h",
    "NoahShared.h",
    "NoahUnityPlugin.h",
    "NoahUtil.h",
    "SmacTracking.h",
    {
      "Libraries/json-framework-3.2.0/" => [
        "SBJson.xcodeproj"
      ]
    },
    {
      "Libraries/SVProgressHUD/" => [
        "SVProgressHUD.h",
        {
          "SVProgressHUD.m" => {
            "reference" => "COMPILE_PHASE",
            "settings"  => { "COMPILER_FLAGS" => "-fobjc-arc" }
          }
        },
        {
          "SVProgressHUD.bundle" => {
            "reference" => "RESOURCES_PHASE"
          }
        }
      ]
    }
  ]
}

@build_path = ARGV[0] ? ARGV[0] : "/Users/yuya/Workspace/quikin-unity/Dist/3.2.6_dev/"
build_env   = ARGV[1] ? ARGV[1] : "Product"
unity_ver   = ARGV[2] ? ARGV[2].to_f : "2.3.2"
proj_path   = "#{@build_path}Unity-iPhone.xcodeproj"

@project         = Xcodeproj::Project.open(proj_path)
@target          = @project.targets.find { |target| target.name == "Unity-iPhone" }
@build_phase     = @target.frameworks_build_phase
@compile_phase   = @target.source_build_phase
@resources_phase = @target.resources_build_phase
@resources_path  = "/Users/yuya/Desktop/ios_dev/"
@groups         = {
  "root"       => @project.root_object.main_group,
  "classes"    => @project.groups.find { |group| group.path == "Classes"   },
  "libraries"  => @project.groups.find { |group| group.path == "Libraries" },
  "frameworks" => @project.groups.find { |group| group.name == "Frameworks" || group.path == "Frameworks" }
}

unless @target then exit end

def set_frameworks_group_path
  FileUtils.mkdir_p("#{@build_path}Frameworks")
  @groups["frameworks"].set_path("#{@build_path}Frameworks")
end

def set_framework_search_paths(paths = "\"$(SRCROOT)\"")
  conf_objects = @target.build_configurations.objects

  conf_objects.each do |obj|
    settings = obj.build_settings

    unless settings["FRAMEWORK_SEARCH_PATHS"]
      settings["FRAMEWORK_SEARCH_PATHS"] = "\"$(SRCROOT)\""
    end
  end
end

def find_file_reference(file_name)
  reference = @build_phase.files_references.find do |ref|
    (ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)) && (ref.name =~ /^#{file_name}/)
  end

  return reference
end

def import_system_files(files, add_type)
  files.each do |file|
    is_attrs_optional = file =~ /^\-/ ? true : false
    is_attrs_required = file =~ /^\+/ ? true : false
    file_name         = is_attrs_optional || is_attrs_required ? file.gsub(/^[\-\+]/, "") : file 

    unless find_file_reference(file_name)
      case add_type
      when "frameworks"
        @target.add_system_framework(file_name)
      when "libraries"
        @target.add_system_library(file_name)
      end
    end

    if is_attrs_optional || is_attrs_required
      file_ref = find_file_reference(file_name)
      settings = { "ATTRIBUTES" => is_attrs_optional ? ["Weak"] : [] }

      file_ref.build_files.each { |itr| itr.settings = settings }
    end
  end
end

def import_external_files(file_paths, group_name)
  file_paths.each do |file_path|
    if file_path.is_a?(Hash)
      import_external_files_with_option(file_path, group_name)
      next
    end

    splited_file_path       = file_path.split(/\//)
    file_name               = splited_file_path.last
    directory_path          = splited_file_path.size > 1 ? splited_file_path[0...splited_file_path.size - 1].join("/") + "/" : ""
    base_directory_path     = group_name == "root" ? "" : group_name.capitalize + "/"
    is_reqire_build_ref     = file_name =~ /\.(a|dylib|framework)$/ ? true : false
    is_reqire_resources_ref = file_name =~ /^\@/                    ? true : false 

    if is_reqire_resources_ref
      file_name = file_name.gsub(/^\@/, "")
    end

    path_base = base_directory_path + directory_path + file_name
    path_from = @resources_path + path_base
    path_to   = @build_path + path_base
    has_file  = @groups[group_name].find_file_by_path(directory_path + file_name)

    FileUtils.rm_rf(path_to)
    FileUtils.cp_r(path_from, path_to)

    unless has_file
      ref      = @groups[group_name].new_file(path_to)
      ref.name = file_name

      if is_reqire_build_ref
        @build_phase.add_file_reference(ref)
      elsif is_reqire_resources_ref
        @resources_phase.add_file_reference(ref)
      end
    end

  end
end

def import_external_files_with_option(hash, group_name)
  folder_name = hash.keys.find { |key| key =~ /\/$/ }
  path_from   = @resources_path + folder_name
  path_to     = @build_path + folder_name
  has_file    = File.exist?(folder_name)
  file_names  = hash.values.first

  FileUtils.rm_rf(path_to)
  FileUtils.cp_r(path_from, path_to)

  file_names.each do |file_name|
    if has_file
      next
    end

    if file_name.is_a?(String)
      @groups[group_name].new_file("#{path_to}#{file_name}")
    elsif file_name.is_a?(Hash)
      file      = file_name.keys.first
      value     = file_name.values.first
      reference = case value["reference"]
        when "COMPILE_PHASE"   then @compile_phase
        when "RESOURCES_PHASE" then @resources_phase
        else nil
      end
      settings = value["settings"]    
      ref      = @groups[group_name].new_file("#{path_to}#{file}")
      file_ref = reference.add_file_reference(ref)

      if settings && settings.is_a?(Hash)
        file_ref.settings = settings
      end
    end
  end
end

set_frameworks_group_path()
set_framework_search_paths("\"$(SRCROOT)\"")

system_files.each_key do |itr|
  import_system_files(system_files[itr], itr)
end

external_files.each_key do |itr|
  import_external_files(external_files[itr], itr)
end

@project.save()
