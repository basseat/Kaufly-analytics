import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import uuid
import os

np.random.seed(42)

OUTPUT_DIR = "data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

START_DATE = datetime(2024, 1, 1)
END_DATE = datetime(2025, 6, 30)
TOTAL_DAYS = (END_DATE - START_DATE).days

COUNTRIES = {"DE": 0.70, "AT": 0.18, "CH": 0.12}
CITIES = {
    "DE": ["Berlin", "Hamburg", "Munich", "Cologne", "Frankfurt", "Stuttgart", "Dusseldorf", "Leipzig", "Dresden", "Nuremberg"],
    "AT": ["Vienna", "Graz", "Linz", "Salzburg", "Innsbruck"],
    "CH": ["Zurich", "Geneva", "Basel", "Bern", "Lausanne"],
}
CHANNELS = {"organic_search": 0.30, "paid_search": 0.20, "social_media": 0.18, "referral": 0.12, "direct": 0.10, "email": 0.10}
CARRIERS = {"DHL": 0.40, "DPD": 0.25, "Hermes": 0.20, "Austrian_Post": 0.15}
WAREHOUSES = ["Berlin", "Munich", "Hamburg", "Vienna", "Zurich"]
PAYMENT_METHODS = {"credit_card": 0.35, "paypal": 0.30, "klarna": 0.20, "bank_transfer": 0.10, "apple_pay": 0.05}
RETURN_REASONS = ["wrong_size", "not_as_described", "changed_mind", "defective", "arrived_late", "wrong_item"]

NUM_CUSTOMERS = 50000
NUM_PRODUCTS = 500
MEMBER_RATE = 0.15


def generate_id():
    return uuid.uuid4().hex[:12]


def weighted_choice(options_dict, size=1):
    keys = list(options_dict.keys())
    probs = list(options_dict.values())
    return np.random.choice(keys, size=size, p=probs)


def seasonal_weight(date):
    month, day = date.month, date.day
    if month == 11 and day >= 25:
        return 3.5
    if month == 12 and day <= 23:
        return 2.8
    if month == 1 and day <= 10:
        return 1.8
    if month in (6, 7):
        return 1.3
    if month == 3:
        return 0.8
    return 1.0


def generate_products():
    categories = {
        "fashion": {
            "subcategories": ["mens_clothing", "womens_clothing", "shoes", "accessories", "sportswear", "outerwear"],
            "price_range": (15, 250),
            "share": 0.45,
        },
        "electronics": {
            "subcategories": ["smartphones", "laptops", "audio", "gaming", "smart_home", "accessories"],
            "price_range": (20, 1200),
            "share": 0.30,
        },
        "home_living": {
            "subcategories": ["furniture", "kitchen", "lighting", "decor", "bedding", "storage"],
            "price_range": (10, 800),
            "share": 0.25,
        },
    }
    brands_pool = [
        "NordStil", "AlpenWear", "TechVolt", "UrbanEdge", "HausKraft",
        "VeloMode", "PeakForm", "LuxNova", "EcoLine", "DigitalPulse",
        "StadtHaus", "KernDesign", "FrostByte", "SolaCasa", "BlitzTech",
        "WaldGruen", "CloudNine", "SteelCraft", "PureForm", "PixelWerk",
    ]
    rows = []
    for category, config in categories.items():
        n = int(NUM_PRODUCTS * config["share"])
        for _ in range(n):
            subcategory = np.random.choice(config["subcategories"])
            low, high = config["price_range"]
            price = round(np.random.lognormal(np.log((low + high) / 4), 0.6), 2)
            price = np.clip(price, low, high)
            listed_at = START_DATE + timedelta(days=np.random.randint(0, TOTAL_DAYS // 2))
            rows.append({
                "product_id": generate_id(),
                "category": category,
                "subcategory": subcategory,
                "brand": np.random.choice(brands_pool),
                "price": price,
                "listed_at": listed_at.strftime("%Y-%m-%d"),
            })
    df = pd.DataFrame(rows)
    df.to_csv(f"{OUTPUT_DIR}/products.csv", index=False)
    print(f"products: {len(df)} rows")
    return df


def generate_customers():
    rows = []
    for _ in range(NUM_CUSTOMERS):
        country = weighted_choice(COUNTRIES)[0]
        city = np.random.choice(CITIES[country])
        days_offset = np.random.beta(2, 3) * TOTAL_DAYS
        registered_at = START_DATE + timedelta(days=int(days_offset))
        rows.append({
            "customer_id": generate_id(),
            "registered_at": registered_at.strftime("%Y-%m-%d %H:%M:%S"),
            "country": country,
            "city": city,
            "acquisition_channel": weighted_choice(CHANNELS)[0],
        })
    df = pd.DataFrame(rows)
    df.to_csv(f"{OUTPUT_DIR}/customers.csv", index=False)
    print(f"customers: {len(df)} rows")
    return df


def generate_memberships(customers_df):
    eligible = customers_df.sample(frac=MEMBER_RATE, random_state=42).copy()
    rows = []
    for _, c in eligible.iterrows():
        reg_date = datetime.strptime(c["registered_at"], "%Y-%m-%d %H:%M:%S")
        days_to_join = np.random.exponential(60)
        started_at = reg_date + timedelta(days=int(days_to_join))
        if started_at > END_DATE:
            continue
        churned = np.random.random() < 0.25
        if churned:
            duration_days = int(np.random.exponential(120)) + 30
            ended_at = started_at + timedelta(days=duration_days)
            if ended_at > END_DATE:
                ended_at = None
                status = "active"
            else:
                status = "cancelled"
        else:
            ended_at = None
            status = "active"
        rows.append({
            "membership_id": generate_id(),
            "customer_id": c["customer_id"],
            "plan_name": "kaufly_plus",
            "started_at": started_at.strftime("%Y-%m-%d"),
            "ended_at": ended_at.strftime("%Y-%m-%d") if ended_at else None,
            "monthly_fee": 7.99,
            "status": status,
        })
    df = pd.DataFrame(rows)
    df.to_csv(f"{OUTPUT_DIR}/memberships.csv", index=False)
    print(f"memberships: {len(df)} rows")
    return df


def is_member_at(customer_id, date, memberships_df):
    m = memberships_df[memberships_df["customer_id"] == customer_id]
    if m.empty:
        return False
    for _, row in m.iterrows():
        start = datetime.strptime(row["started_at"], "%Y-%m-%d")
        if pd.isna(row["ended_at"]):
            if date >= start:
                return True
        else:
            end = datetime.strptime(row["ended_at"], "%Y-%m-%d")
            if start <= date <= end:
                return True
    return False


def generate_orders_and_items(customers_df, products_df, memberships_df):
    member_ids = set(memberships_df["customer_id"].unique())
    membership_lookup = {}
    for _, row in memberships_df.iterrows():
        cid = row["customer_id"]
        start = datetime.strptime(row["started_at"], "%Y-%m-%d")
        end = datetime.strptime(row["ended_at"], "%Y-%m-%d") if pd.notna(row["ended_at"]) else END_DATE
        if cid not in membership_lookup:
            membership_lookup[cid] = []
        membership_lookup[cid].append((start, end))

    def check_member(cid, date):
        if cid not in membership_lookup:
            return False
        for s, e in membership_lookup[cid]:
            if s <= date <= e:
                return True
        return False

    product_ids = products_df["product_id"].values
    product_prices = products_df.set_index("product_id")["price"].to_dict()
    product_categories = products_df.set_index("product_id")["category"].to_dict()

    order_rows = []
    item_rows = []

    for _, c in customers_df.iterrows():
        cid = c["customer_id"]
        reg_date = datetime.strptime(c["registered_at"], "%Y-%m-%d %H:%M:%S")
        is_member_customer = cid in member_ids
        if is_member_customer:
            n_orders = max(1, int(np.random.poisson(8)))
        else:
            if np.random.random() < 0.25:
                continue
            n_orders = max(1, int(np.random.poisson(2.5)))

        available_days = (END_DATE - reg_date).days
        if available_days <= 0:
            continue

        for _ in range(n_orders):
            order_day_offset = np.random.randint(1, max(2, available_days))
            order_date = reg_date + timedelta(days=order_day_offset)
            if order_date > END_DATE:
                continue
            order_date += timedelta(
                hours=np.random.randint(7, 23),
                minutes=np.random.randint(0, 59),
            )
            season_w = seasonal_weight(order_date)
            if np.random.random() > season_w / 3.5:
                if season_w < 1.0:
                    continue

            is_member_now = check_member(cid, order_date)
            n_items = np.random.choice([1, 2, 3, 4, 5], p=[0.35, 0.30, 0.20, 0.10, 0.05])
            selected_products = np.random.choice(product_ids, size=n_items, replace=False)

            total = 0
            order_id = generate_id()
            for pid in selected_products:
                qty = np.random.choice([1, 2, 3], p=[0.75, 0.20, 0.05])
                unit_price = product_prices[pid]
                total += unit_price * qty
                item_rows.append({
                    "order_item_id": generate_id(),
                    "order_id": order_id,
                    "product_id": pid,
                    "quantity": qty,
                    "unit_price": unit_price,
                })

            discount = 0
            if is_member_now:
                discount = round(total * 0.10, 2)

            shipping = np.random.choice(["standard", "express"], p=[0.75, 0.25])
            if is_member_now and shipping == "standard":
                shipping_label = "standard_free"
            else:
                shipping_label = shipping

            status = np.random.choice(
                ["delivered", "shipped", "cancelled", "returned"],
                p=[0.82, 0.05, 0.08, 0.05],
            )

            order_rows.append({
                "order_id": order_id,
                "customer_id": cid,
                "ordered_at": order_date.strftime("%Y-%m-%d %H:%M:%S"),
                "status": status,
                "total_amount": round(total, 2),
                "discount_amount": discount,
                "payment_method": weighted_choice(PAYMENT_METHODS)[0],
                "shipping_method": shipping_label,
            })

    orders_df = pd.DataFrame(order_rows)
    items_df = pd.DataFrame(item_rows)
    orders_df.to_csv(f"{OUTPUT_DIR}/orders.csv", index=False)
    items_df.to_csv(f"{OUTPUT_DIR}/order_items.csv", index=False)
    print(f"orders: {len(orders_df)} rows")
    print(f"order_items: {len(items_df)} rows")
    return orders_df, items_df


def generate_deliveries(orders_df):
    deliverable = orders_df[orders_df["status"].isin(["delivered", "shipped", "returned"])].copy()
    rows = []
    for _, o in deliverable.iterrows():
        order_date = datetime.strptime(o["ordered_at"], "%Y-%m-%d %H:%M:%S")
        carrier = weighted_choice(CARRIERS)[0]
        warehouse = np.random.choice(WAREHOUSES)
        processing_days = np.random.randint(0, 2)
        shipped_at = order_date + timedelta(days=processing_days)

        if "express" in o["shipping_method"]:
            transit_days = np.random.choice([1, 2], p=[0.6, 0.4])
        else:
            transit_days = np.random.choice([2, 3, 4, 5, 6], p=[0.15, 0.35, 0.30, 0.15, 0.05])

        estimated_delivery = shipped_at + timedelta(days=int(transit_days))
        delay = np.random.choice([0, 0, 0, 0, 1, 1, 2, 3], p=[0.55, 0.10, 0.05, 0.05, 0.10, 0.05, 0.05, 0.05])
        actual_delivery = estimated_delivery + timedelta(days=int(delay))

        if o["status"] == "shipped":
            delivery_status = "in_transit"
            actual_delivery = None
        else:
            delivery_status = "delivered"

        rows.append({
            "delivery_id": generate_id(),
            "order_id": o["order_id"],
            "carrier": carrier,
            "warehouse_city": warehouse,
            "shipped_at": shipped_at.strftime("%Y-%m-%d"),
            "estimated_delivery_at": estimated_delivery.strftime("%Y-%m-%d"),
            "delivered_at": actual_delivery.strftime("%Y-%m-%d") if actual_delivery else None,
            "delivery_status": delivery_status,
        })
    df = pd.DataFrame(rows)
    df.to_csv(f"{OUTPUT_DIR}/deliveries.csv", index=False)
    print(f"deliveries: {len(df)} rows")
    return df


def generate_returns(orders_df, items_df):
    returned_orders = orders_df[orders_df["status"] == "returned"]
    returnable_orders = orders_df[orders_df["status"] == "delivered"].sample(frac=0.12, random_state=42)
    all_return_orders = pd.concat([returned_orders, returnable_orders])

    return_items = items_df[items_df["order_id"].isin(all_return_orders["order_id"])].copy()
    return_items = return_items.merge(
        all_return_orders[["order_id", "ordered_at"]], on="order_id", how="left"
    )
    return_items["keep"] = np.random.random(len(return_items)) < 0.6
    return_items = return_items[return_items["keep"]].copy()

    order_dates = pd.to_datetime(return_items["ordered_at"])
    init_days = np.random.randint(3, 30, size=len(return_items))
    recv_days = np.random.randint(3, 14, size=len(return_items))

    return_items["initiated_at"] = order_dates + pd.to_timedelta(init_days, unit="D")
    return_items = return_items[return_items["initiated_at"] <= END_DATE].copy()
    return_items["received_at"] = return_items["initiated_at"] + pd.to_timedelta(
        np.random.randint(3, 14, size=len(return_items)), unit="D"
    )
    return_items.loc[return_items["received_at"] > END_DATE, "received_at"] = pd.NaT

    return_items["return_id"] = [generate_id() for _ in range(len(return_items))]
    return_items["reason"] = np.random.choice(RETURN_REASONS, size=len(return_items))
    return_items["refund_amount"] = (return_items["unit_price"] * return_items["quantity"]).round(2)
    return_items["initiated_at"] = return_items["initiated_at"].dt.strftime("%Y-%m-%d")
    return_items["received_at"] = return_items["received_at"].dt.strftime("%Y-%m-%d")

    df = return_items[["return_id", "order_id", "order_item_id", "initiated_at", "received_at", "reason", "refund_amount"]]
    df.to_csv(f"{OUTPUT_DIR}/returns.csv", index=False)
    print(f"returns: {len(df)} rows")
    return df


def generate_events(customers_df, orders_df):
    print("  events: generating registration events...")
    reg_events = customers_df[["customer_id", "registered_at"]].copy()
    reg_events["event_name"] = "account_registered"
    reg_events.rename(columns={"registered_at": "event_timestamp"}, inplace=True)

    print("  events: generating order funnel events...")
    order_timestamps = pd.to_datetime(orders_df["ordered_at"])
    n_orders = len(orders_df)

    funnel_records = []
    offsets_page = np.random.randint(10, 60, size=n_orders)
    offsets_view1 = np.random.randint(1, 10, size=n_orders)
    offsets_view2 = np.random.randint(1, 5, size=n_orders)
    offsets_cart = np.random.randint(1, 5, size=n_orders)
    offsets_checkout = np.random.randint(1, 10, size=n_orders)
    offsets_payment = np.random.randint(1, 5, size=n_orders)
    offsets_confirm = np.random.randint(5, 30, size=n_orders)
    has_view2 = np.random.random(n_orders) < 0.8
    is_cancelled = orders_df["status"].values == "cancelled"
    cancelled_proceeds = np.random.random(n_orders) < 0.5
    proceeds_to_checkout = ~is_cancelled | cancelled_proceeds

    cids = orders_df["customer_id"].values
    for i in range(n_orders):
        ot = order_timestamps.iloc[i]
        cid = cids[i]
        t = ot - pd.Timedelta(minutes=int(offsets_page[i]))
        funnel_records.append((cid, "page_view", t))
        t += pd.Timedelta(minutes=int(offsets_view1[i]))
        funnel_records.append((cid, "product_viewed", t))
        if has_view2[i]:
            t += pd.Timedelta(minutes=int(offsets_view2[i]))
            funnel_records.append((cid, "product_viewed", t))
        t += pd.Timedelta(minutes=int(offsets_cart[i]))
        funnel_records.append((cid, "added_to_cart", t))
        if proceeds_to_checkout[i]:
            t += pd.Timedelta(minutes=int(offsets_checkout[i]))
            funnel_records.append((cid, "checkout_started", t))
            t += pd.Timedelta(minutes=int(offsets_payment[i]))
            funnel_records.append((cid, "payment_submitted", t))
            t += pd.Timedelta(seconds=int(offsets_confirm[i]))
            funnel_records.append((cid, "order_confirmed", t))

    funnel_df = pd.DataFrame(funnel_records, columns=["customer_id", "event_name", "event_timestamp"])
    funnel_df["event_timestamp"] = funnel_df["event_timestamp"].dt.strftime("%Y-%m-%d %H:%M:%S")

    print("  events: generating abandoned sessions...")
    customers_with_orders = set(orders_df["customer_id"].unique())
    no_order_customers = customers_df[~customers_df["customer_id"].isin(customers_with_orders)]
    reg_dates_pd = pd.to_datetime(customers_df.set_index("customer_id")["registered_at"])

    abandoned_records = []
    sample_customers = customers_df.sample(frac=0.3, random_state=99)
    for _, c in sample_customers.iterrows():
        cid = c["customer_id"]
        reg = datetime.strptime(c["registered_at"], "%Y-%m-%d %H:%M:%S")
        avail = max(1, (END_DATE - reg).days)
        browse_date = reg + timedelta(days=np.random.randint(0, avail), hours=np.random.randint(7, 23))
        if browse_date > END_DATE:
            continue
        t = browse_date
        abandoned_records.append((cid, "page_view", t.strftime("%Y-%m-%d %H:%M:%S")))
        t += timedelta(minutes=np.random.randint(1, 10))
        abandoned_records.append((cid, "product_viewed", t.strftime("%Y-%m-%d %H:%M:%S")))
        drop = np.random.random()
        if drop > 0.50:
            t += timedelta(minutes=np.random.randint(1, 5))
            abandoned_records.append((cid, "added_to_cart", t.strftime("%Y-%m-%d %H:%M:%S")))
        if drop > 0.80:
            t += timedelta(minutes=np.random.randint(1, 10))
            abandoned_records.append((cid, "checkout_started", t.strftime("%Y-%m-%d %H:%M:%S")))

    abandoned_df = pd.DataFrame(abandoned_records, columns=["customer_id", "event_name", "event_timestamp"])

    reg_events["event_timestamp"] = reg_events["event_timestamp"].astype(str)
    all_events = pd.concat([reg_events[["customer_id", "event_name", "event_timestamp"]], funnel_df, abandoned_df], ignore_index=True)
    all_events["event_id"] = [generate_id() for _ in range(len(all_events))]
    all_events["properties"] = "{}"
    all_events = all_events[["event_id", "customer_id", "event_name", "event_timestamp", "properties"]]
    all_events.to_csv(f"{OUTPUT_DIR}/events.csv", index=False)
    print(f"events: {len(all_events)} rows")
    return all_events


def generate_membership_benefits(memberships_df, orders_df):
    member_orders = orders_df.merge(
        memberships_df[["membership_id", "customer_id", "started_at", "ended_at"]],
        on="customer_id",
        how="inner",
    )
    order_dates = pd.to_datetime(member_orders["ordered_at"])
    m_starts = pd.to_datetime(member_orders["started_at"])
    m_ends = pd.to_datetime(member_orders["ended_at"].fillna(END_DATE.strftime("%Y-%m-%d")))
    active_mask = (order_dates >= m_starts) & (order_dates <= m_ends)
    member_orders = member_orders[active_mask].copy()
    member_orders["_order_dt_str"] = order_dates[active_mask].dt.strftime("%Y-%m-%d %H:%M:%S")

    benefits = []
    free_del = member_orders[member_orders["shipping_method"].str.contains("free", na=False)].copy()
    if len(free_del) > 0:
        free_del["benefit_id"] = [generate_id() for _ in range(len(free_del))]
        free_del["benefit_type"] = "free_delivery"
        benefits.append(free_del[["benefit_id", "membership_id", "benefit_type", "_order_dt_str", "order_id"]])

    disc = member_orders[member_orders["discount_amount"] > 0].copy()
    if len(disc) > 0:
        disc["benefit_id"] = [generate_id() for _ in range(len(disc))]
        disc["benefit_type"] = "discount_10pct"
        benefits.append(disc[["benefit_id", "membership_id", "benefit_type", "_order_dt_str", "order_id"]])

    if benefits:
        df = pd.concat(benefits, ignore_index=True)
        df.rename(columns={"_order_dt_str": "used_at"}, inplace=True)
    else:
        df = pd.DataFrame(columns=["benefit_id", "membership_id", "benefit_type", "used_at", "order_id"])
    df.to_csv(f"{OUTPUT_DIR}/membership_benefits.csv", index=False)
    print(f"membership_benefits: {len(df)} rows")
    return df


if __name__ == "__main__":
    print("generating kaufly synthetic data...\n")
    products = generate_products()
    customers = generate_customers()
    memberships = generate_memberships(customers)
    orders, order_items = generate_orders_and_items(customers, products, memberships)
    deliveries = generate_deliveries(orders)
    returns = generate_returns(orders, order_items)
    events = generate_events(customers, orders)
    benefits = generate_membership_benefits(memberships, orders)
    print("\ndone. files saved to data/")
