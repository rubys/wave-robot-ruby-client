require 'test/unit'
require 'abstract_robot'

class Robot < AbstractRobot
  set_name "Testy"
  set_profile_url 'http://example.com/profile.xml'
  set_image_url 'http://example.com/image.png'
  
  add_cron :clock, 20
  
  def DOCUMENT_CHANGED(properties, context)
    wavelet = context.GetWavelets()[0]
    blip = context.GetBlipById(wavelet.GetRootBlipId())
    blip.GetDocument().SetText('Only I get to edit the top blip!')
  end
  def clock(event, context)
    wavelet = context.GetWavelets()[0]
    blip = context.GetBlipById(wavelet.GetRootBlipId())
	blip.GetDocument().SetText("It's " + Time.now.to_s)
  end
end

DEBUG_DATA = '{"blips":{"map":{"wdykLROk*13":{"lastModifiedTime":1242079608457,"contributors":{"javaClass":"java.util.ArrayList","list":["davidbyttow@google.com"]},"waveletId":"conv+root","waveId":"wdykLROk*11","parentBlipId":null,"version":3,"creator":"davidbyttow@google.com","content":"\n","blipId":"wdykLROk*13","javaClass":"com.google.wave.api.impl.BlipData","annotations":{"javaClass":"java.util.ArrayList","list":[{"range":{"start":0,"javaClass":"com.google.wave.api.Range","end":1},"name":"user/e/davidbyttow@google.com","value":"David","javaClass":"com.google.wave.api.Annotation"}]},"elements":{"map":{},"javaClass":"java.util.HashMap"},"childBlipIds":{"javaClass":"java.util.ArrayList","list":[]}}},"javaClass":"java.util.HashMap"},"events":{"javaClass":"java.util.ArrayList","list":[{"timestamp":1242079611003,"modifiedBy":"davidbyttow@google.com","javaClass":"com.google.wave.api.impl.EventData","properties":{"map":{"participantsRemoved":{"javaClass":"java.util.ArrayList","list":[]},"participantsAdded":{"javaClass":"java.util.ArrayList","list":["monty@appspot.com"]}},"javaClass":"java.util.HashMap"},"type":"WAVELET_PARTICIPANTS_CHANGED"}]},"wavelet":{"lastModifiedTime":1242079611003,"title":"","waveletId":"conv+root","rootBlipId":"wdykLROk*13","javaClass":"com.google.wave.api.impl.WaveletData","dataDocuments":null,"creationTime":1242079608457,"waveId":"wdykLROk*11","participants":{"javaClass":"java.util.ArrayList","list":["davidbyttow@google.com","monty@appspot.com"]},"creator":"davidbyttow@google.com","version":5}}'

class TestAllows < Test::Unit::TestCase
  def testCrons
    robot = Robot.new
    assert_equal('ContextImpl_', robot.run_command(:clock, JSON(DEBUG_DATA)).class.name)
    assert_not_equal("name is not one of the allowed functions: clock", robot.run_command(:name, JSON(DEBUG_DATA)))  
  end
end

class TestCapabilities < Test::Unit::TestCase
  def setup()
    @robot = Robot.new
  end

  def assertStringsEqual(s1, s2)
    assert_equal(s1, s2, "Strings differ:\n%s--\n%s" % [s1, s2])
  end

  def testCapsAndCrons()
    robot = Robot.new
    expected = (
        "<?xml version=\"1.0\"?>\n" +
        "<w:robot xmlns:w=\"http://wave.google.com/extensions/robots/1.0\">\n" +
        "<w:capabilities>\n" +
        '  <w:capability name="DOCUMENT_CHANGED"/>' + "\n" +
        "</w:capabilities>\n" +
        "<w:crons>\n  <w:cron path=\"/_wave/robot/clock\" timerinseconds=\"20\"/>\n</w:crons>\n" +
        "<w:profile name=\"Testy\"" +
        " imageurl=\"http://example.com/image.png\"" +
        " profileurl=\"http://example.com/profile.xml\"/>\n" +
        "</w:robot>\n")
    xml = robot.capabilities()
    self.assertStringsEqual(expected, xml)
  end
end