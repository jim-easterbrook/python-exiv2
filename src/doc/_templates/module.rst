{% if fullname == "exiv2._version" %}
    {% set attributes = ['__version__', '__version_tuple__'] %}
{% endif %}

{% extends "!autosummary/module.rst" %}
