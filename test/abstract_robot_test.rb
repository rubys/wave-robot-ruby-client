#! ruby
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Unit tests for the robot_abstract module."""

__author__ = 'jacobly@google.com (Jacob Lee)'

require 'test/unit'

require 'abstract_robot'

DEBUG_DATA = '{"blips":{"map":{"wdykLROk*13":{"lastModifiedTime":1242079608457,"contributors":{"javaClass":"java.util.ArrayList","list":["davidbyttow@google.com"]},"waveletId":"conv+root","waveId":"wdykLROk*11","parentBlipId":null,"version":3,"creator":"davidbyttow@google.com","content":"\n","blipId":"wdykLROk*13","javaClass":"com.google.wave.api.impl.BlipData","annotations":{"javaClass":"java.util.ArrayList","list":[{"range":{"start":0,"javaClass":"com.google.wave.api.Range","end":1},"name":"user/e/davidbyttow@google.com","value":"David","javaClass":"com.google.wave.api.Annotation"}]},"elements":{"map":{},"javaClass":"java.util.HashMap"},"childBlipIds":{"javaClass":"java.util.ArrayList","list":[]}}},"javaClass":"java.util.HashMap"},"events":{"javaClass":"java.util.ArrayList","list":[{"timestamp":1242079611003,"modifiedBy":"davidbyttow@google.com","javaClass":"com.google.wave.api.impl.EventData","properties":{"map":{"participantsRemoved":{"javaClass":"java.util.ArrayList","list":[]},"participantsAdded":{"javaClass":"java.util.ArrayList","list":["monty@appspot.com"]}},"javaClass":"java.util.HashMap"},"type":"WAVELET_PARTICIPANTS_CHANGED"}]},"wavelet":{"lastModifiedTime":1242079611003,"title":"","waveletId":"conv+root","rootBlipId":"wdykLROk*13","javaClass":"com.google.wave.api.impl.WaveletData","dataDocuments":null,"creationTime":1242079608457,"waveId":"wdykLROk*11","participants":{"javaClass":"java.util.ArrayList","list":["davidbyttow@google.com","monty@appspot.com"]},"creator":"davidbyttow@google.com","version":5}}'


class TestHelpers < Test::Unit::TestCase
  """Tests for the web helper functions in abstract_robot."""

  def testparse_json()
    context, events = AbstractRobot.parse_json(JSON(DEBUG_DATA))

    # Test some basic properties; the rest should be covered by
    # ops.CreateContext.
    blips = context.GetBlips()
    assert_equal(1, blips.length)
    assert_equal('wdykLROk*13', blips[0].GetId())
    assert_equal('wdykLROk*11', blips[0].GetWaveId())
    assert_equal('conv+root', blips[0].GetWaveletId())

    assert_equal(1, events.length)
    event = events[0]
    assert_equal('WAVELET_PARTICIPANTS_CHANGED', event.type)
    assert_equal({'participantsRemoved' => [],
                      'participantsAdded' => ['monty@appspot.com']},
                     event.properties)
  end

  def testSerializeContextSansOps()
    context, _ = AbstractRobot.parse_json(JSON(DEBUG_DATA))
    serialized = AbstractRobot.serialize_context(context)
    assert_equal(
        '{"operations":{"list":[],"javaClass":"java.util.ArrayList"},' +
        '"javaClass":"com.google.wave.api.impl.OperationMessageBundle"}',
        serialized)
  end

  def testSerializeContextWithOps()
    context, _ = AbstractRobot.parse_json(JSON(DEBUG_DATA))
    wavelet = context.GetWavelets()[0]
    blip = context.GetBlipById(wavelet.GetRootBlipId())
    blip.GetDocument().SetText('Hello, wave!')
    serialized = AbstractRobot.serialize_context(context)
        # '"javaClass": "java.util.ArrayList"
    expected = '{"operations": {"javaClass": "java.util.ArrayList", "list": [{"blipId": "wdykLROk*13", "index": -1, "waveletId": "conv+root", "javaClass": "com.google.wave.api.impl.OperationImpl", "waveId": "wdykLROk*11", "property": {"javaClass": "com.google.wave.api.Range", "end": 1, "start": 0}, "type": "DOCUMENT_DELETE"},{"blipId": "wdykLROk*13", "index": 0, "waveletId": "conv+root", "javaClass": "com.google.wave.api.impl.OperationImpl", "waveId": "wdykLROk*11", "property": "Hello, wave!", "type": "DOCUMENT_INSERT"}]}, "javaClass": "com.google.wave.api.impl.OperationMessageBundle"}'
    assert_equal(JSON(expected), JSON(serialized))
  end
end


class TestGetCapabilitiesXml < Test::Unit::TestCase

  def setup()
    AbstractRobot.set_name 'Testy'
    @robot = AbstractRobot.new
  end

  def assertStringsEqual(s1, s2)
    assert_equal(s1, s2, "Strings differ:\n%s--\n%s" % [s1, s2])
  end

  def testDefault()
    AbstractRobot.send('class_variable_set','@@crons',{})
    expected = (
        "<?xml version=\"1.0\"?>\n" +
        "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
        "<w:capabilities>\n</w:capabilities>\n" +
        "<w:profile name=\"Testy\"/>\n" +
        "</w:robot>\n")
    xml = @robot.capabilities()
    self.assertStringsEqual(expected, xml)
  end

  def testUrls()
    AbstractRobot.set_name 'Testy'
	AbstractRobot.set_image_url 'http://example.com/image.png'
    AbstractRobot.set_profile_url 'http://example.com/profile.xml'
	AbstractRobot.send('class_variable_set','@@crons',{})
    @robot = AbstractRobot.new
    expected = (
        "<?xml version=\"1.0\"?>\n" +
        "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
        "<w:capabilities>\n</w:capabilities>\n" +
        "<w:profile name=\"Testy\"" +
        " imageurl=\"http://example.com/image.png\"" +
        " profileurl=\"http://example.com/profile.xml\"/>\n" +
        "</w:robot>\n")
    xml = @robot.capabilities()
    self.assertStringsEqual(expected, xml)
  end

  def testCapsAndEvents()
    #@robot.RegisterHandler('myevent', nil)
    AbstractRobot.send('class_variable_set','@@crons',{})
	AbstractRobot.add_cron :ping, 20
	AbstractRobot.set_image_url ''
    AbstractRobot.set_profile_url ''	
    expected = (
        "<?xml version=\"1.0\"?>\n" +
        "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
        "<w:capabilities>\n" +
     #   "  <w:capability name=\"myevent\"/>\n" +
        "</w:capabilities>\n" +
        "<w:crons>\n  <w:cron path=\"/_wave/robot/ping\" timerinseconds=\"20\"/>\n</w:crons>\n" +
        "<w:profile name=\"Testy\"/>\n" +
        "</w:robot>\n")
    xml = @robot.capabilities()
    self.assertStringsEqual(expected, xml)
  end
end
