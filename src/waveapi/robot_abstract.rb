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
require 'json'
require 'util'

module RobotAbstract
  def self.ParseJSONBody(json_body)
    """Parse a JSON string and return a context and an event list."""
    json = JSON.parse(json_body)
    # TODO(davidbyttow): Remove this once no longer needed.
    data = Util.CollapseJavaCollections(json)
    context = CreateContext(data)
    events = data['events'].map {|event_data| Model.CreateEvent(event_data)}
    return context, events
  end


  def self.SerializeContext(context)
    """Return a JSON string representing the given context."""
    context_dict = Util.Serialize(context)
    return JSON.dump(context_dict)
  end
end

class RobotListener
  """Listener interface for robot events.

  The RobotListener is a high-level construct that hides away the details
  of events. Instead, a client will derive from this class and register
  it with the robot. All event handlers are automatically registered. When
  a relevant event comes in, logic is applied based on the incoming data and
  the appropriate function is invoked.

  For example:
    If the user implements the 'OnRobotAdded' method, the OnParticipantChanged
    method of their subclass, this will automatically register the
    events.WAVELET_PARTICIPANTS_CHANGED handler and respond to any events
    that add the robot.

    class MyRobotListener < robot.RobotListener
      def OnRobotAdded()
        wavelet = self.context.GetRootWavelet()
        blip = wavelet.CreateBlip()
        blip.GetDocument.SetText('Thanks for adding me!')
      end
    end

    robot = robots.Robot()
    robot.RegisterListener(MyRobotListener)
    robot.Run()

  TODO(davidbyttow): Implement this functionality.
  """

  def initialize
    pass
  end

  def OnRobotAdded()
    # TODO(davidbyttow): Implement.
    pass
  end

  def OnRobotRemoved()
    # TODO(davidbyttow): Implement.
    pass
  end
end

class Robot
  """Robot metadata class.

  This class holds on to basic robot information like the name and profile.
  It also maintains the list of event handlers and cron jobs and
  dispatches events to the appropriate handlers.
  """

  def initialize(name, image_url='', profile_url='')
    """Initializes self with robot information."""
    @_handlers = {}
    @name = name
    @image_url = image_url
    @profile_url = profile_url
    @cron_jobs = []
  end

  def RegisterHandler(event_type, handler)
    """Registers a handler on a specific event type.

    Multiple handlers may be registered on a single event type and are
    guaranteed to be called in order.

    The handler takes two arguments, the event properties and the Context of
    this session. For example:

    def OnParticipantsChanged(properties, context)
      pass

    Args:
      event_type: An event type to listen for.
      handler: A function handler which takes two arguments, event properties
          and the Context of this session.
    """
    (@_handlers[event_type] ||= []).push(handler)
  end

  def RegisterCronJob(path, seconds)
    """Registers a cron job to surface in capabilities.xml."""
    @cron_jobs.push([path, seconds])
  end

  def HandleEvent(event, context)
    """Calls all of the handlers associated with an event."""
    for handler in @_handlers.get(event.type, [])
      # TODO(jacobly): pass the event in to the handlers directly
      # instead of passing the properties dictionary.
      handler(event.properties, context)
    end
  end

  def GetCapabilitiesXml()
    """Return this robot's capabilities as an XML string."""
    lines = ['<w:capabilities>']
    for capability in @_handlers:
      lines.push('  <w:capability name="%s"/>' % capability)
    end
    lines.push('</w:capabilities>')

    if @cron_jobs and !@cron_jobs.empty?:
      lines.push('<w:crons>')
      for job in @cron_jobs:
        lines.push('  <w:cron path="%s" timerinseconds="%s"/>' % job)
      end
      lines.push('</w:crons>')
    end

    robot_attrs = ' name="%s"' % @name
    if @image_url and !@image_url.empty?:
      robot_attrs += ' imageurl="%s"' % @image_url
    end
    if @profile_url and !@profile_url.empty?:
      robot_attrs += ' profileurl="%s"' % @profile_url
    end
    lines.push('<w:profile%s/>' % robot_attrs)
    return ("<?xml version=\"1.0\"?>\n" +
            "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
            "%s\n</w:robot>\n") % (lines.join("\n"))
  end

  def GetProfileJson()
    """Returns JSON body for any profile handler.

    Returns:
      String of JSON to be sent as a response.
    """
    data = {}
    data['name'] = @name
    data['imageUrl'] = @image_url
    data['profileUrl'] = @profile_url
    # TODO(davidbyttow): Remove this java nonsense.
    data['javaClass'] = 'com.google.wave.api.ParticipantProfile'
    return simplejson.dumps(data)
  end
end
