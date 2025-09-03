#!/usr/bin/env python3
# -*- encoding: utf-8 -*-
# vim: tabstop=2 shiftwidth=2 softtabstop=2 expandtab

import argparse
from datetime import datetime, timezone
import sys
import string

from faker import Faker

Faker.seed(47)

CREATE_DATABASE_SQL_FMT = '''CREATE DATABASE IF NOT EXISTS `{database}`;'''

USE_DATABASE_SQL_FMT = '''USE `{database}`;'''

CREATE_TABLE_SQL_FMT = '''
CREATE TABLE IF NOT EXISTS `{database}`.`{table}` (
  trans_id BIGINT(20) AUTO_INCREMENT PRIMARY KEY,
  customer_id VARCHAR(12) NOT NULL,
  event VARCHAR(10) DEFAULT NULL,
  sku VARCHAR(10) NOT NULL,
  amount INT DEFAULT 0,
  device VARCHAR(10) DEFAULT NULL,
  trans_datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
  KEY(trans_datetime)
) ENGINE=InnoDB AUTO_INCREMENT=0;
'''

INSERT_SQL_FMT = '''INSERT INTO {database}.{table} (trans_id, customer_id, event, sku, amount, device, trans_datetime) VALUES({trans_id}, "{customer_id}", "{event}", "{sku}", {amount}, "{device}", "{trans_datetime}");'''

def main():
  parser = argparse.ArgumentParser(description="Generate fake retail transaction data as SQL statements.")

  parser.add_argument('--database', action='store', default='testdb',
    help='Database name to use in the SQL statement (default: testdb)')
  parser.add_argument('--table', action='store', default='retail_trans',
    help='Table name to use in the SQL statement (default: retail_trans)')
  parser.add_argument('--max-count', type=int, default=None,
    help='Number of INSERT statements. Defaults to 0 if --generate-ddl is used, otherwise 100.')
  parser.add_argument('--generate-ddl', action='store_true', help='Generate CREATE DATABASE and CREATE TABLE statements.')
  parser.add_argument('--start-pkid', type=int, default=1,
    help='The starting AUTO_INCREMENT value for the primary key (default: 1).')

  options = parser.parse_args()
  fake = Faker()

  # Set default for max_count based on whether --generate-ddl is present
  if options.max_count is None:
    options.max_count = 0 if options.generate_ddl else 100

  if options.generate_ddl:
    print(CREATE_DATABASE_SQL_FMT.format(database=options.database))
    print(CREATE_TABLE_SQL_FMT.format(database=options.database, table=options.table, start_pkid=options.start_pkid))
    print('-- DDL statements generated.\n')

  if options.max_count <= 0:
    if not options.generate_ddl:
        print('-- [INFO] No statements generated. Use --generate-ddl or set --max-count > 0.', file=sys.stderr)
    return

  START_DATETIME = datetime.now(timezone.utc).replace(minute=0, second=0, microsecond=0)

  pk_counter = options.start_pkid
  for _ in range(options.max_count):
    event = fake.random_element(elements=['visit', 'view', 'cart', 'list', 'like', 'purchase'])
    amount = fake.pyint(max_value=100) if event in ['cart', 'purchase'] else 1
    json_record = {
      'trans_id': pk_counter,
      'device': fake.random_element(elements=['pc', 'mobile', 'tablet']),
      'event': event,
      'sku': fake.pystr_format(string_format='??%###????', letters=string.ascii_uppercase),
      'amount': amount,
      'customer_id': fake.pystr_format(string_format='%###########'),
      'trans_datetime': fake.date_time_ad(start_datetime=START_DATETIME).strftime('%Y-%m-%d %H:%M:%S')
    }
    
    sql_stmt = INSERT_SQL_FMT.format(database=options.database, table=options.table, **json_record)
    print(sql_stmt)
    pk_counter += 1

  print(f'-- [INFO] Total {options.max_count} INSERT statements generated.', file=sys.stderr)


if __name__ == '__main__':
  main()
