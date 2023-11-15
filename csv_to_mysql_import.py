import pandas as pd
from sqlalchemy import create_engine
import glob
import os
from urllib.parse import quote
from dotenv import load_dotenv

load_dotenv()

# Get all environmental variables
username = os.getenv('USERNAME')
password = os.getenv('PASSWORD')
host = os.getenv('HOST')
port = os.getenv('PORT')
database = os.getenv('DATABASE')


# Function to list all CSV file paths in a given directory and its subdirectories
def list_all_csv_file_paths(root_directory):
    file_pattern = os.path.join(root_directory, '**', '*.csv')
    csv_file_paths = glob.glob(file_pattern, recursive=True)
    return csv_file_paths


# Define the root directory where the CSV files are located
directory_path = 'archive'

# Get a list of all CSV file paths in the specified directory and its subdirectories
input_file_paths = list_all_csv_file_paths(directory_path)

# Create an SQLAlchemy engine to connect to the database
engine = create_engine(f'mysql+mysqlconnector://{username}:%s@{host}:{port}/{database}' % quote(f'{password}'))

# Iterate through each CSV file in the list
for file_path in input_file_paths:
    print('----------------')
    print('Processing:', file_path)

    # Read the CSV file into a Pandas DataFrame
    df = pd.read_csv(file_path)

    # Set table name based on the CSV file name (without the file extension)
    table_name = os.path.splitext(os.path.basename(file_path))[0]
    print('Table Name:', table_name)

    # Data Cleaning for Specific Tables
    if table_name == 'employee_counts':
        # Convert the unix timestamp in time_recorded column to datetime format
        df['time_recorded'] = pd.to_datetime(df['time_recorded'], unit='s').round('s')
        print(f'{table_name} shape before removing duplicates:', df.shape)
        # Remove duplicate rows based on specific columns
        df.drop_duplicates(subset=['company_id', 'time_recorded'], keep='last', inplace=True, ignore_index=True)
        print(f'{table_name} shape after removing duplicates:', df.shape)
    elif table_name == 'company_specialities':
        print(f'{table_name} shape before removing duplicates:', df.shape)
        # Remove duplicate rows based on specific columns
        df.drop_duplicates(subset=['company_id', 'speciality'], keep='last', inplace=True, ignore_index=True)
        print(f'{table_name} shape after removing duplicates:', df.shape)
    elif table_name == 'company_industries':
        print(f'{table_name} shape before removing duplicates:', df.shape)
        # Remove duplicate rows based on specific columns
        df.drop_duplicates(subset=['company_id', 'industry'], keep='last', inplace=True, ignore_index=True)
        print(f'{table_name} shape after removing duplicates:', df.shape)
    else:
        print(f'{table_name} shape:', df.shape)

    # Connect to the database and insert the data into the table, replacing it if it already exists
    with engine.connect() as connection:
        df.to_sql(table_name, connection, if_exists='replace', index=False)

    print(f"Table '{table_name}' has been created, and CSV data has been imported into the MySQL database.")
