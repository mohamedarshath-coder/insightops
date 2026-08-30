{% macro compute_velocity_score(order_count_column) -%}
    -- PLACEHOLDER implementation: this macro did not exist anywhere in the project
    -- (referenced only by demo_mart_order_velocity_trends.sql) and there is no prior
    -- version to recover the intended business logic from. This casts the order count
    -- to a float so the model compiles and runs; the real scoring formula should be
    -- confirmed with whoever owns this mart and this macro updated accordingly.
    {{ order_count_column }}::float
{%- endmacro %}
