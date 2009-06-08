require 'lib/waveapi/init'

class Robot < AbstractRobot
  set_name "Sinatra Bot"
  add_cron :clock, 20
  
  def DOCUMENT_CHANGED(properties, context)
    wavelet = context.GetWavelets[0]
    blip = context.GetBlipById(wavelet.GetRootBlipId())
    blip.GetDocument.SetText('Only I get to edit the top blip!')
  end
  def clock(event, context)
    wavelet = context.GetWavelets[0]
    blip = context.GetBlipById(wavelet.GetRootBlipId())
	blip.GetDocument.SetText("It's " + Time.now.to_s)
  end
end