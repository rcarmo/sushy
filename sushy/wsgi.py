import hy
from bottle import DEBUG, default_app
from sushy.config import DEBUG_MODE, INSTRUMENTATION_KEY
import sushy.routes

import newrelic.agent
newrelic.agent.initialize()

DEBUG = DEBUG_MODE

if INSTRUMENTATION_KEY:
    from applicationinsights.requests import WSGIApplication
    app = WSGIApplication(INSTRUMENTATION_KEY, default_app())
else:
    app = default_app()