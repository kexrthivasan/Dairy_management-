
import random
from datetime import datetime, timedelta

def gen_csv(filename, header, rows_gen):
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(header + '\n')
        for row in rows_gen:
            f.write(row + '\n')

start_date = datetime(2026, 1, 1)
end_date = datetime(2026, 3, 14)

# Milk Data: Jan to March, skipping ~15% of days to test "Missing Entry" detection
milk_rows = []
curr = start_date
while curr <= end_date:
    if random.random() > 0.15:
        m = round(random.uniform(10.0, 15.0), 1)
        e = round(random.uniform(8.0, 12.0), 1)
        date_str = curr.strftime("%Y-%m-%d")
        milk_rows.append(f"{date_str},{m},{e},Sample entry")
    curr += timedelta(days=1)

gen_csv(r"d:\Dairy project\sample_milk_data.csv", "Date,Morning (L),Evening (L),Notes", milk_rows)

# Expense Data: Sparse entries across Jan-March
expense_rows = []
cats = ["Feed", "Medical", "Rice", "Others"]
curr = start_date
while curr <= end_date:
    if random.random() < 0.08: # ~2.5 entries per month
        cat = random.choice(cats)
        amt = random.randint(500, 6000)
        date_str = curr.strftime("%Y-%m-%d")
        expense_rows.append(f"{date_str},{cat},{amt},Bulk purchase")
    curr += timedelta(days=1)

gen_csv(r"d:\Dairy project\sample_expense_data.csv", "Date,Category,Amount (Rs),Notes", expense_rows)
print("CSV Generation Successful")
