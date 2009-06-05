require 'abstract_robot'
class Robot < AbstractRobot
  def allowed_commands
    ["name"]
  end
  def name
    @name
  end
end
=begin

class RobotCapabilitiesHandler(webapp.RequestHandler):
  """Handler for serving capabilities.xml given a robot."""

  def __init__(self, robot):
    """Initializes this handler with a specific robot."""
    self._robot = robot

  def get(self):
    """Handles HTTP GET request."""
    xml = self._robot.GetCapabilitiesXml()
    self.response.headers['Content-Type'] = 'text/xml'
    self.response.out.write(xml)


class RobotProfileHandler(webapp.RequestHandler):
  """Handler for serving the robot's profile information."""

  def __init__(self, robot):
    """Initializes this handler with a specific robot."""
    self._robot = robot

  def get(self):
    """Handles HTTP GET request."""
    self.response.headers['Content-Type'] = 'application/json'
    self.response.out.write(self._robot.GetProfileJson())


class RobotEventHandler(webapp.RequestHandler):
  """Handler for the dispatching of events to various handlers to a robot.

  This handler only responds to post events with a JSON post body. Its primary
  task is to separate out the context data from the events in the post body
  and dispatch all events in order. Once all events have been dispatched
  it serializes the context data and its associated operations as a response.
  """

  def __init__(self, robot):
    """Initializes self with a specific robot."""
    self._robot = robot

  def get(self):
    """Handles the get event for debugging. Ops usually too long."""
    ops = self.request.get('ops')
    logging.info('get: ' + ops)
    if ops:
      self.request.body = ops
      self.post()
      self.response.headers['Content-Type'] = 'text/html'

  def post(self):
    """Handles HTTP POST requests."""
    json_body = self.request.body
    if not json_body:
      # TODO(davidbyttow): Log error?
      return
    logging.info('Incoming: ' + json_body)

    context, events = robot_abstract.ParseJSONBody(json_body)
    for event in events:
      try:
        self._robot.HandleEvent(event, context)
      except:
        logging.error(traceback.format_exc())

    json_response = robot_abstract.SerializeContext(context)
    # Build the response.
    logging.info('Outgoing: ' + json_response)
    self.response.headers['Content-Type'] = 'application/json'
    self.response.out.write(json_response)
=end