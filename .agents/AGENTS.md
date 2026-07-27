# Workspace Rules

## Default Localhost Server & App URL
- When the user asks to "run", "start", or asks for the "localhost link", ALWAYS ensure the mobile web app showcase server is running on port 3000 (`python -m http.server 3000 --directory "android/app/src/main/assets/public"`) and provide **`http://localhost:3000`** as the primary link.
