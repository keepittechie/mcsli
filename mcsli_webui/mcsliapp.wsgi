import sys

# Adjust the path to include your Flask app's directory
sys.path.insert(0, '/var/www/mcsli_webui')

from website import create_app

# Create an application instance
application = create_app()

# Note: No need to call application.run() since Apache will handle running the app
