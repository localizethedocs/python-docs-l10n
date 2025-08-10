# Distributed under the OSI-approved BSD 3-Clause License.
# See accompanying file LICENSE-BSD for details.

import json
import os

# Default configuration values.
DEFAULT_CONFIG_VALUES = {
    "html_baseurl"        : "",
    "current_language"    : "",
    "versions_json_path"  : "versions.json",
}

def add_default_config_values(app):
    """
    Add default configuration values to the Sphinx app if not already defined.
    """
    for key, default in DEFAULT_CONFIG_VALUES.items():
        if key not in app.config.values:
            app.add_config_value(key, default, "env")

def load_versions(app, filepath):
    """
    Load the versions.json and generate html_context variables.
    """
    if filepath and os.path.isfile(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)

            formatted_versions = []

            # Get base URL and current language from Sphinx config.
            html_baseurl = app.config.html_context.get("html_baseurl", "")
            current_language = app.config.html_context.get("current_language", "")

            # Process "in_development" versions.
            for dev_version in data.get("in_development", []):
                version_name = dev_version.get("name")
                url = os.path.join(html_baseurl, current_language, version_name, "index.html").replace(os.sep, '/')
                title = f"Python {version_name} (in development)"
                formatted_versions.append({
                    "url": url,
                    "title": title
                })

            # Process "release" versions.
            for release_version in data.get("releases", []):
                version_name = release_version.get("name")
                url = os.path.join(html_baseurl, current_language, version_name, "index.html").replace(os.sep, '/')
                if release_version.get("eol", False):
                    title = f"Python {version_name} (EOL)"
                else:
                    title = f"Python {version_name}"
                formatted_versions.append({
                    "url": url,
                    "title": title
                })

            # Set the 'versions' variable in html_context.
            app.config.html_context["versions"] = formatted_versions

def setup(app):
    """
    Sphinx extension entry point.
    """
    add_default_config_values(app)

    def on_config_inited(app, config):
        app.config.html_context["html_baseurl"] = config.html_baseurl
        app.config.html_context["current_language"] = app.config.current_language
        load_versions(app, config.versions_json_path)

    app.connect("config-inited", on_config_inited)

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
