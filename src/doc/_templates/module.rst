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

   {% block classes %}
   {% if classes %}
   .. rubric:: {{ _('Classes') }}

   {% if fullname == "exiv2.value" %}
   .. inheritance-diagram:: {{ classes |
                               reject("in", ["Date", "Time"]) |
                               join(" ") }}
       :top-classes: exiv2.value.Value
   {% endif %}
   {% if fullname in ["exiv2.datasets", "exiv2.metadatum", "exiv2.properties", "exiv2.tags"] %}
   .. inheritance-diagram:: exiv2.ExifKey exiv2.IptcKey exiv2.XmpKey
       :top-classes: exiv2.metadatum.Key
   {% endif %}
   {% if fullname in ["exiv2.exif", "exiv2.iptc", "exiv2.metadatum", "exiv2.xmp"] %}
   .. inheritance-diagram:: exiv2.Exifdatum exiv2.Iptcdatum exiv2.Xmpdatum
       :top-classes: exiv2.metadatum.Metadatum
   {% endif %}
   {% if fullname in ["exiv2.exif"] %}
   .. inheritance-diagram:: ExifData_iterator Exifdatum_reference
       :top-classes: exiv2.exif.Exifdatum_pointer
   {% endif %}
   {% if fullname in ["exiv2.iptc"] %}
   .. inheritance-diagram:: IptcData_iterator Iptcdatum_reference
       :top-classes: exiv2.iptc.Iptcdatum_pointer
   {% endif %}
   {% if fullname in ["exiv2.xmp"] %}
   .. inheritance-diagram:: XmpData_iterator Xmpdatum_reference
       :top-classes: exiv2.xmp.Xmpdatum_pointer
   {% endif %}

   .. autosummary::
   {% for item in classes %}
      {{ item }}
   {%- endfor %}
   {% endif %}
   {% endblock %}
