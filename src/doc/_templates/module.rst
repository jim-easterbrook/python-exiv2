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

   {% if fullname == "exiv2._basicio" %}
   .. inheritance-diagram:: {{ classes | join(" ") }}
       :top-classes: exiv2.basicio.BasicIo
   {% endif %}

   .. autosummary::
   {% for item in classes %}
      {{ item }}
   {%- endfor %}
   {% endif %}
   {% endblock %}
