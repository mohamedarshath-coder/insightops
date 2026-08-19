from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("RevenueAggregation").config("spark.sql.autoBroadcastJoinThreshold", -1).getOrCreate()

# Load large tables
df_orders = spark.read.table("hive_metastore.demo.fct_orders")
df_customers = spark.read.table("hive_metastore.demo.dim_customers")

# Use broadcast join to reduce shuffle
df_customers = df_customers.repartition(200)
df_joined = df_orders.join(df_customers, "customer_id", "inner")

# Group by and aggregate without collect
df_result = df_joined.groupBy("sales_region").sum("order_amount")

# Write result to a new table instead of collecting to driver
df_result.write.format("parquet").mode("overwrite").saveAsTable("hive_metastore.demo.revenue_aggregation")