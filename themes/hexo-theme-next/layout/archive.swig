{% extends '_layout.swig' %}
{% import '_macro/post-collapse.swig' as post_template %}
{% import '_macro/sidebar.swig' as sidebar_template %}

{% block title %} {{ __('title.archive') }} | {{ config.title }} {% endblock %}

{% block page_class %} page-archive {% endblock %}

{% block content %}

  <section id="posts" class="posts-collapse">
    <span class="archive-move-on"></span>

    <span class="archive-page-counter">
      {% set cheers %}
      {% set posts_length = site.posts.length %}
      {% if posts_length > 210 %} {% set cheers = 'excellent' %}
        {% elif posts_length > 130 %} {% set cheers = 'great' %}
        {% elif posts_length > 80 %} {% set cheers = 'good' %}
        {% elif posts_length > 50 %} {% set cheers = 'nice' %}
        {% elif posts_length > 30 %} {% set cheers = 'ok' %}
      {% else %}
        {% set cheers = 'um' %}
      {% endif %}
      {{ __('cheers.' + cheers) }}! {{ _p("counter.archive_posts", site.posts.length) }} {{ __('keep_on') }}
    </span>

    {% for post in page.posts %}

      {# Show year #}
      {% set year %}
      {% set post.year = date(post.date, 'YYYY') %}

      {% if post.year !== year %}
        {% set year = post.year %}
        <div class="collection-title">
          <h2 class="archive-year motion-element" id="archive-year-{{ year }}">{{ year }}</h2>
        </div>
      {% endif %}
      {# endshow #}

      {{ post_template.render(post) }}

    {% endfor %}

  </section>

  {% include '_partials/pagination.swig' %}
	<!--高速版-->
<div id="SOHUCS"></div>
<script charset="utf-8" type="text/javascript" src="http://changyan.sohu.com/upload/changyan.js" ></script>
<script type="text/javascript">
    window.changyan.api.config({
        appid: 'cys0iXAGa',
        conf: 'prod_31256952d71e3e29f6c0efe4734eba6f'
    });
</script>        
{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(false) }}
{% endblock %}

{% block script_extra_before %}
  {% if theme.use_motion %}
    <script type="text/javascript">
      postMotionOptions = {stagger: 100, drag: true};
    </script>
  {% endif %}
{% endblock %}

{% block script_extra %}
  {% if theme.use_motion %}
    <script type="text/javascript" id="motion.page.archive">
      $('.archive-year').velocity('transition.slideLeftIn');
    </script>
  {% endif %}
{% endblock %}
