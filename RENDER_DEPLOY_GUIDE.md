# Idrok Academy / Kodla — Render deployment notes

This package is a deployment-preparation version of the uploaded project. It keeps the original lesson/game files and adds a Render start script. Review and test before making it public.

## Render settings
- Runtime: Python
- Build command: `pip install -r requirements.txt`
- Start command: `python deploy.py`
- Environment variable: `TEACHER_PASSWORD` = a unique strong password of at least 12 characters
- Persistent disk: create one mounted at `/var/data` (at least 1 GB is ample for this SQLite database)
- `KODLA_DB_PATH` = `/var/data/kodla.db`

The service starts the API on internal port 8765 and the Flet web app on Render's `PORT`. The frontend's default API address remains `http://127.0.0.1:8765`, because both processes run in the same service/container.

## Important
- Do not deploy publicly until you have tested sign-up, login, progress saving, and teacher access.
- Do not commit real student data or a `kodla.db` file.
- This app's API uses plain HTTP internally; do not expose port 8765 as a separate public service. Only expose the Render web service port.
- This is a first deployment configuration, not a security audit. Have the API reviewed before use with real student data.
- If Render's health check fails on `/`, remove the `healthCheckPath` setting or change it to a route served by the Flet app.
