---
layout: page
title: Categories
description: "An archive of posts sorted by category."
---

{%- assign categories_list = site.categories | sort -%}
{%- assign categories_size = site.categories | size -%}

{% for category in categories_list -%}
**[[{{ category[0] }}](#{{ category[0] }})]{.smallcaps}**&nbsp;&nbsp;
{% endfor %}

{% for category in categories_list %}
# [{{ category[0] }}]{.smallcaps}

{% assign pages_list = category[1] -%}
{% for post in pages_list -%}
- [{{ post.title }}]({{ site.baseurl }}{{ post.url }}), {{ post.date | date: '%B %-d' }}
{% endfor %}

{% endfor -%}
{%- assign categories_list = nil -%}
{%- assign categories_size = nil -%}
