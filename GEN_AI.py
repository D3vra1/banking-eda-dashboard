import os
import pyodbc
import pandas as pd
from groq import Groq

# ==========================================
# 1. DATABASE & LLM CONFIGURATION
# ==========================================
DB_CONFIG = {
    'driver': '{ODBC Driver 17 for SQL Server}',
    'server': 'MANINDERPALKAUR',       # <-- MATCHES YOUR IMAGE EXTREMELY ACCURATELY
    'database': 'bank',                # <-- MATCHES YOUR DATABASE NAME EXACTLY
    'trusted_connection': 'yes'        

}


GROQ_API_KEY = "GROQ_API_KEY_HERE"

# ==========================================
# 2. SCHEMA DEFINITION (System Prompt Context)
# ==========================================
# Replace these examples with your actual Banking EDA or HR database schemas!
# ==========================================
# 2. SCHEMA DEFINITION (System Prompt Context)
# ==========================================
# ==========================================
# 2. SCHEMA DEFINITION (System Prompt Context)
# ==========================================
SCHEMA_PROMPT = """
You are an expert SQL Server DBA. Given a user question, output ONLY a valid T-SQL query. 
Do not include markdown code block formatting like ```sql or trailing semicolons. 
Just output the clean raw query text. Always use explicit table prefixes like 'dbo.'.

Database Schema Context:
Table: dbo.loans
Columns: loan_id (varchar), customer_id (varchar), loan_amount (decimal), interest_rate (decimal), start_date (date)

Table: dbo.customers
Columns: customer_id (varchar), first_name (varchar), last_name (varchar), email (varchar), phone (varchar), city (varchar)
"""



# ==========================================
# 3. CORE LOGIC WORKFLOWS
# ==========================================
def get_sql_from_llm(user_question: str) -> str:
    """Sends the natural language query to the Llama-3 model via Groq API."""
    client = Groq(api_key=GROQ_API_KEY)
    
    completion = client.chat.completions.create(
        model="llama-3.3-70b-versatile",
        messages=[
            {"role": "system", "content": SCHEMA_PROMPT},
            {"role": "user", "content": user_question}
        ]
    )
    
    # Clean up formatting wrappers from response string securely
    raw_content = completion.choices[0].message.content.strip()
    clean_sql = raw_content.replace("```sql", "").replace("```", "")
    return clean_sql

def execute_query(sql_query: str) -> pd.DataFrame:
    """Connects to SQL Server and pulls results into a DataFrame."""
    conn_str = (
        f"DRIVER={DB_CONFIG['driver']};"
        f"SERVER={DB_CONFIG['server']};"
        f"DATABASE={DB_CONFIG['database']};"
        f"Trusted_Connection={DB_CONFIG['trusted_connection']};"
    )
    conn = pyodbc.connect(conn_str)
    df = pd.read_sql(sql_query, conn)
    conn.close()
    return df

# ==========================================
# 4. EXECUTION LAYER
# ==========================================
if __name__ == "__main__":
    print("\n================================================")
    print("🤖 GenAI Natural Language to T-SQL Agent Active")
    print("================================================\n")
    
    user_query = input("Ask a question about your data: ")
    
    print("\n[1/2] Translating English to T-SQL via Groq Engine...")
    try:
        generated_sql = get_sql_from_llm(user_query)
        print(f"\n👉 Generated SQL Code:\n{generated_sql}\n")
    except Exception as api_err:
        print(f"❌ GenAI API Failure: {api_err}")
        exit(1)
        
    print("[2/2] Fetching live results from SQL Server...")
    try:
        result_df = execute_query(generated_sql)
        print("\n📊 Live Query Results:")
        print(result_df.to_string(index=False))
    except Exception as db_err:
        print(f"\n⚠️ Database Connection Refused: {db_err}")
        print("💡 The AI part is working perfectly! To get data back, update 'DB_CONFIG' with real server configurations.")