import pandas as pd

data = {"name": ["Anna", "Ivan", "Olga"], "score": [88, 92, 79]}
df = pd.DataFrame(data)
print(df)
print(f"Mean score: {df['score'].mean()}")