import hy
from bottle import DEBUG, default_app
from sushy.config import DEBUG_MODE
import sushy.routes

import newrelic.agent
newrelic.agent.initialize()

DEBUG = DEBUG_MODE
app = default_app()