# Fake Data Generation Script

This directory contains a Python script to generate fake retail transaction data as SQL `INSERT` statements. This is useful for populating a test database to verify the Datastream CDC pipeline.

This script is designed to be run using `uv`, a fast, next-generation Python package manager.

## Prerequisites

- Python 3.8+
- `uv` (or `curl` / `PowerShell` to install it)

## Setup

The setup process uses `uv` to create an isolated virtual environment and install dependencies.

1.  **Install `uv` (if you don't have it)**:
    *   **macOS / Linux**:
        ```bash
        curl -LsSf https://astral.sh/uv/install.sh | sh
        ```
    *   **Windows (PowerShell)**:
        ```bash
        powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
        ```

2.  **Create a Virtual Environment**:
    From within the `scripts` directory, run the following command. This will create a `.venv` directory to store the environment.
    ```bash
    uv venv
    ```

3.  **Install Dependencies**:
    Install the required packages into the virtual environment.
    ```bash
    uv pip install -r requirements.txt
    ```

## Usage

Once the setup is complete, use `uv run` to execute the script. This command automatically detects and uses the `.venv` virtual environment in the current directory, so you do **not** need to manually activate it with a command like `source .venv/bin/activate`.

### Generating DDL Statements Only

To generate only the `CREATE DATABASE` and `CREATE TABLE` statements, use the `--generate-ddl` flag. The script will automatically default to generating zero `INSERT` statements.

```bash
# Generate DDL for the default database and table
uv run python generate_fake_sql.py --generate-ddl
```

### Generating DML (INSERT) Statements Only

This will generate 100 `INSERT` statements for the `testdb.retail_trans` table by default.

```bash
# Generate 100 INSERT statements
uv run python generate_fake_sql.py
```

### Combining DDL and DML

To generate both DDL and DML, use the `--generate-ddl` flag and explicitly specify the number of `INSERT` statements with `--max-count`.

```bash
# Generate DDL and 50 INSERT statements
uv run python generate_fake_sql.py --generate-ddl --max-count 50
```

### Customizing Output

Use command-line arguments to change the output.

-   `--database`: Specify the database name.
-   `--table`: Specify the table name.
-   `--max-count`: Specify the number of `INSERT` statements to generate.

```bash
# Generate DDL and 500 INSERT statements for the 'prod.transactions' table
uv run python generate_fake_sql.py --generate-ddl --database prod --table transactions --max-count 500
```

### Saving to a File

You can redirect the output to a `.sql` file to execute it on your database later.

```bash
# Generate DDL and 1000 INSERT statements and save to a file
uv run python generate_fake_sql.py --generate-ddl --max-count 1000 > initial_data.sql
```