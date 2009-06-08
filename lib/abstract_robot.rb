#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Defines the generic robot classes.

This module provides the Robot class and RobotListener interface,
as well as some helper functions for web requests and responses.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'

require 'model'
require 'ops'
require 'rubygems'
require 'util'
require 'json'
require 'events'

class AbstractRobot
  """Robot metadata class.

  This class holds on to basic robot information like the name and profile.
  It also maintains the list of event handlers and cron jobs and
  dispatches events to the appropriate handlers.
  """
  @@crons = {}
  @@name = ""
  @@profile_url = ""
  @@image_url = ""
  

  def self.set_name(name)
    @@name = name
  end
  def self.set_image_url(url)
    @@image_url = url
  end
  def self.set_profile_url(url)
    @@profile_url = url
  end  
  
  def execute_json_rpc!(json)
    data = AbstractRobot.parse_json(json)
	context = data[0]
	event = data[1].first
	send(event.type, event.properties, context)
	return context
  end
  
  def run_command(command, json)
    unless @@crons.keys.member? command
	  return command.to_s + " is not one of the allowed commands: " + @@crons.keys.join('  ')
	end
    data = AbstractRobot.parse_json(json)
	context = data[0]
	event = data[1].first
	send(command, event, context)
	return context
  end
  
  def self.add_cron(name, timer)
    @@crons[name] = timer
  end

  def capabilities()
    """Return this robot's capabilities as an XML string."""
    lines = ['<w:capabilities>']
    lines+= events_handled.map{|e| '  <w:capability name="'+e+'"/>'}
    lines.push('</w:capabilities>')

    unless @@crons.empty?
      lines.push('<w:crons>')
      lines += @@crons.map{|job, timer| '  <w:cron path="/_wave/robot/' + job.to_s + '" timerinseconds="' + timer.to_s + '"/>'}
      lines.push('</w:crons>')
    end

    robot_attrs = ' name="' + @@name +'"'
    robot_attrs += ' imageurl="'+ @@image_url +'"' unless @@image_url.empty?
	robot_attrs += ' profileurl="' + @@profile_url + '"' unless @@profile_url.empty?
    lines.push '<w:profile'<< robot_attrs << '/>'
	
	"<?xml version=\"1.0\"?>\n" +
    "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
	  lines.join("\n") +		
    "\n</w:robot>\n"
  end
  
  def events_handled
    ALL_WAVE_EVENTS.select{|e| respond_to?(e)}
  end

  def profile()
    """Returns JSON body for any profile handler.

    Returns:
      String of JSON to be sent as a response.
    """
    data = {}
    data['name'] = @@name
    data['imageUrl'] = @@image_url
    data['profileUrl'] = @@profile_url
    # TODO(davidbyttow): Remove this java nonsense.
    data['javaClass'] = 'com.google.wave.api.ParticipantProfile'
    return data.to_json
  end
  def self.parse_json(json)
    """Parse a JSON string and return a context and an event list."""
    # TODO(davidbyttow): Remove this once no longer needed.
	data = Util.CollapseJavaCollections(json)
    context = CreateContext(data)
    events = data['events'].map {|event_data| Model.CreateEvent(event_data)}
    return context, events
  end


  def self.serialize_context(context)
    """Return a JSON string representing the given context."""
    JSON.dump Util.Serialize(context)
  end  
end
