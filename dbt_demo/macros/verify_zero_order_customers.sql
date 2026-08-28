{% macro verify_zero_order_customers() %}
  {% if execute %}
    {% set zero_query %}
      select count(*) as zero_count from {{ ref('demo_fct_customers') }} where total_orders = 0
    {% endset %}
    {% set zero_results = run_query(zero_query) %}
    {% set zero_count = zero_results.columns[0].values()[0] %}

    {% set total_query %}
      select count(*) as total_count from {{ ref('demo_fct_customers') }}
    {% endset %}
    {% set total_results = run_query(total_query) %}
    {% set total_count = total_results.columns[0].values()[0] %}

    {% do log("VERIFICATION: customers_with_zero_orders=" ~ zero_count ~ " total_customers_in_mart=" ~ total_count, info=True) %}
  {% endif %}
  select 1
{% endmacro %}
