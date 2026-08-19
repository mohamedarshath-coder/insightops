

from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("RevenueAggregation").getOrCreate()

# Load large tables
df_orders = spark.read.table("hive_metastore.demo.fct_orders")
df_customers = spark.read.table("hive_metastore.demo.dim_customers")

# Heavy shuffle join without broadcast
df_joined = df_orders.join(df_customers, "customer_id", "inner")
df_result = df_joined.groupBy("sales_region").sum("order_amount")

# Dangerous collect to driver causing Java heap space OOM
results = df_result.collect()
