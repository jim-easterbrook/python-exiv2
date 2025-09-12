{% if fullname == "exiv2.error" %}
   {% set classes = classes + ['ErrorCode'] %}
   {% set attributes = attributes + ['pythonHandler'] %}
{% endif %}

{% if fullname == "exiv2.image" %}
   {% set classes = classes + ['ImageType'] %}
{% endif %}

{% if fullname == "exiv2.properties" %}
   {% set classes = classes + ['XmpCategory'] %}
{% endif %}

{% if fullname == "exiv2.tags" %}
   {% set classes = classes + ['IfdId', 'SectionId'] %}
{% endif %}

{% if fullname == "exiv2.types" %}
   {% set classes = classes + ['AccessMode', 'ByteOrder', 'MetadataId',
                               'TypeId'] %}
{% endif %}

{% extends "!autosummary/module.rst" %}
