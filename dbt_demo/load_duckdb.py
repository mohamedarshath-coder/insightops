import duckdb, random
from datetime import date, timedelta
from faker import Faker

fake = Faker(); Faker.seed(42); random.seed(42)

N_CUSTOMERS, N_PRODUCTS, N_ORDERS = 300, 60, 2500
TODAY = date(2026, 8, 19)
CUSTOMER_START = TODAY - timedelta(days=540)
ORDER_START = TODAY - timedelta(days=420)

SEGMENTS = ["Consumer", "Corporate", "SMB"]
LOYALTY_TIERS = ["gold", "silver", "bronze"]; LOYALTY_WEIGHTS = [0.15, 0.35, 0.50]
CHANNELS = ["organic", "paid_search", "referral", "social", "email"]
REGIONS = ["NA-EAST", "NA-WEST", "EU-CENTRAL", "EU-WEST", "APAC"]
ORDER_CHANNELS = ["web", "mobile_app", "marketplace"]
PAYMENT_METHODS = ["credit_card", "paypal", "debit_card", "gift_card"]
CURRENCIES = ["USD", "USD", "USD", "USD", "EUR", "GBP"]
CATEGORIES = {"Electronics": ["Audio","Wearables","Accessories","Smart Home"],
              "Apparel": ["Men's","Women's","Kids","Footwear"],
              "Home & Kitchen": ["Cookware","Furniture","Decor","Appliances"],
              "Sports & Outdoors": ["Fitness","Camping","Cycling","Team Sports"],
              "Beauty": ["Skincare","Haircare","Fragrance","Makeup"]}
BRANDS = ["Northline","Verdant","Kestrel","Amberwood","Truvale","Solace","Fenwick","Marrow&Co"]
SUPPLIERS = ["Global Sourcing Co","Pacific Trade Partners","Meridian Wholesale","Atlas Distribution"]
STATUS_WEIGHTS = [("completed",0.72),("pending",0.10),("processing",0.09),("failed",0.05),("cancelled",0.04)]

def weighted_choice(pairs):
    items, weights = zip(*pairs)
    return random.choices(items, weights=weights, k=1)[0]

customers = []
for i in range(1, N_CUSTOMERS+1):
    first, last = fake.first_name(), fake.last_name()
    customers.append((
        f"CUST{i:05d}", first, last,
        f"{first.lower()}.{last.lower()}{random.randint(1,999)}@example.com",
        fake.phone_number()[:20], random.choice(SEGMENTS),
        weighted_choice(list(zip(LOYALTY_TIERS, LOYALTY_WEIGHTS))),
        CUSTOMER_START + timedelta(days=random.randint(0,540)),
        fake.date_of_birth(minimum_age=18, maximum_age=75),
        fake.city(), fake.state_abbr(), "USA" if random.random()<0.85 else fake.country(),
        random.random()<0.92, random.random()<0.55, random.choice(CHANNELS)))

products = []
for i in range(1, N_PRODUCTS+1):
    pid = f"PROD{i:04d}"; category = random.choice(list(CATEGORIES)); sub = random.choice(CATEGORIES[category])
    cost = round(random.uniform(5,220),2); price = round(cost*random.uniform(1.4,2.6),2)
    products.append((pid, f"{fake.word().capitalize()} {sub}", f"SKU-{pid}", category, sub,
                      random.choice(BRANDS), random.choice(SUPPLIERS), cost, price,
                      random.random()<0.94, CUSTOMER_START - timedelta(days=random.randint(0,400))))

orders = []
customer_ids = [c[0] for c in customers]
total_days = (TODAY - ORDER_START).days
for i in range(1, N_ORDERS+1):
    day_offset = int(total_days * (1 - random.random()**1.6))
    order_date = ORDER_START + timedelta(days=day_offset)
    status = weighted_choice(STATUS_WEIGHTS)
    total = round(random.uniform(18,480),2)
    discount = round(total*random.choice([0,0,0,0.05,0.10,0.15]),2)
    shipping = round(random.choice([0,0,4.99,7.99,12.99]),2)
    est = order_date + timedelta(days=random.randint(2,7))
    actual = est + timedelta(days=random.randint(-1,4)) if status=="completed" else None
    orders.append((f"ORD{i:06d}", random.choice(customer_ids), order_date, total, status,
                    random.choice(PAYMENT_METHODS),
                    random.choice([None,None,"WELCOME10","SUMMER25","FREESHIP","VIP15"]),
                    random.choice(REGIONS), random.choice(ORDER_CHANNELS), discount, shipping,
                    random.choice(CURRENCIES), random.random()<0.08, est, actual, random.random()<0.06))

con = duckdb.connect('insightops_demo.duckdb')
con.execute("CREATE SCHEMA IF NOT EXISTS INSIGHTOPS_RAW")

con.execute("""CREATE OR REPLACE TABLE INSIGHTOPS_RAW.raw_customers (
    customer_id VARCHAR, first_name VARCHAR, last_name VARCHAR, email VARCHAR, phone VARCHAR,
    customer_segment VARCHAR, loyalty_tier VARCHAR, registration_date DATE, date_of_birth DATE,
    city VARCHAR, state VARCHAR, country VARCHAR, is_active BOOLEAN, marketing_opt_in BOOLEAN,
    acquisition_channel VARCHAR)""")
con.execute("""CREATE OR REPLACE TABLE INSIGHTOPS_RAW.raw_products (
    product_id VARCHAR, product_name VARCHAR, sku VARCHAR, category VARCHAR, sub_category VARCHAR,
    brand VARCHAR, supplier VARCHAR, unit_cost DECIMAL(10,2), unit_price DECIMAL(10,2),
    is_active BOOLEAN, launch_date DATE)""")
con.execute("""CREATE OR REPLACE TABLE INSIGHTOPS_RAW.raw_orders (
    order_id VARCHAR, customer_id VARCHAR, order_date DATE, total_amount DECIMAL(10,2),
    order_status VARCHAR, payment_method VARCHAR, promo_code VARCHAR, sales_region VARCHAR,
    order_channel VARCHAR, discount_amount DECIMAL(10,2), shipping_amount DECIMAL(10,2),
    currency VARCHAR, is_gift BOOLEAN, estimated_delivery_date DATE, actual_delivery_date DATE,
    return_requested BOOLEAN)""")

con.executemany("INSERT INTO INSIGHTOPS_RAW.raw_customers VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", customers)
con.executemany("INSERT INTO INSIGHTOPS_RAW.raw_products VALUES (?,?,?,?,?,?,?,?,?,?,?)", products)
con.executemany("INSERT INTO INSIGHTOPS_RAW.raw_orders VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", orders)

print("customers:", con.execute("SELECT COUNT(*) FROM INSIGHTOPS_RAW.raw_customers").fetchone())
print("products:", con.execute("SELECT COUNT(*) FROM INSIGHTOPS_RAW.raw_products").fetchone())
print("orders:", con.execute("SELECT COUNT(*) FROM INSIGHTOPS_RAW.raw_orders").fetchone())
con.close()
