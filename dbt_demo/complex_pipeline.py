from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("RevenueAggregation").config("spark.sql.autoBroadcastJoinThreshold", -1).getOrCreate()

# Load large tables
df_orders = spark.read.table("hive_metastore.demo.fct_orders")
df_customers = spark.read.table("hive_metastore.demo.dim_customers")

# Use broadcast join to reduce shuffle
df_joined = df_orders.join(df_customers, "customer_id", "inner")

# Use aggregateByKey to reduce data before collecting
from pyspark.sql import functions as F
from pyspark.sql import Window
window = Window.partitionBy("sales_region")
df_result = df_joined.groupBy("sales_region").agg(F.sum("order_amount"))

# Write results to a new table instead of collecting to driver
df_result.write.format("parquet").mode("overwrite").saveAsTable("hive_metastore.demo.fct_revenue_aggregation")