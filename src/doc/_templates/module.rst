{% if fullname == "exiv2._version" %}
    {% set attributes = ['__version__', '__version_tuple__'] %}
{% endif %}

{% extends "!autosummary/module.rst" %}

   {% block classes %}
   {% if classes %}
   .. rubric:: {{ _('Classes') }}

   {% if fullname == "exiv2._value" %}
   .. inheritance-diagram:: {{ classes |
                               reject("in", ["Date", "Time"]) |
                               join(" ") }}
       :top-classes: exiv2.value.Value
   {% endif %}

   {% if fullname in ["exiv2._datasets", "exiv2._metadatum", "exiv2._properties", "exiv2._tags"] %}
   .. inheritance-diagram:: exiv2.ExifKey exiv2.IptcKey exiv2.XmpKey
       :top-classes: exiv2.metadatum.Key
   {% endif %}

   {% if fullname in ["exiv2._exif", "exiv2._iptc", "exiv2._metadatum", "exiv2._xmp"] %}
   .. inheritance-diagram:: exiv2.Exifdatum exiv2.Iptcdatum exiv2.Xmpdatum
       :top-classes: exiv2.metadatum.Metadatum
   {% endif %}

   .. autosummary::
   {% for item in classes %}
      {{ item }}
   {%- endfor %}
   {% endif %}
   {% endblock %}
