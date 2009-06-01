"""Dummy robot only."""

__author__ = 'davidbyttow@google.com (David Byttow)'

from waveapi import events
from waveapi import model
from waveapi import robot


def OnParticipantsChanged(properties, context):
  """Invoked when any participants have been added/removed."""
  added = properties['participantsAdded']
  for p in added:
    if p == 'dummy-tutorial@appspot.com':
      Setup(context)
      break


def Setup(context):
  """Called when this robot is first added to the wave."""
  root_wavelet = context.GetRootWavelet()
  root_wavelet.CreateBlip().GetDocument().SetText("I'm alive!")


if __name__ == '__main__':
  dummy = robot.Robot('Dummy',
                      image_url='http://dummy.appspot.com/icon.png',
                      profile_url='http://dummy.appspot.com/')
  dummy.RegisterHandler(events.WAVELET_PARTICIPANTS_CHANGED,
                        OnParticipantsChanged)
  dummy.Run()
