import hy
from .config import DEBUG_MODE
from .routes import *
from bottle import DEBUG, default_app

DEBUG = DEBUG_MODE

app = default_app()
