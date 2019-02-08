import csv
import sqlalchemy as sa
import pandas as pd
import sys


if len(sys.argv) < 7:
	print (sys.argv)
	raise Exception('Need to pass directory, file name, extension, server, database, schema, table!')

directory = sys.argv[1]
file = sys.argv[2]
extension = sys.argv[3]
server = sys.argv[4]
database = sys.argv[5]
schema = sys.argv[6]
table = sys.argv[7]
delimiter = ','
hasHeader = None
skip = 1
indexVar = False
ifExists = 'replace'
try:
	hasHeader = int(sys.argv[8])
	skip = 0
except:
	pass

try:
	ifExists = sys.argv[9]
except:
	pass

fullFileName = directory + file + '.' + extension

print('Start read on ' + fullFileName)
df = pd.read_csv(
	fullFileName, 
	header=hasHeader, 
	skiprows=skip, 
	index_col=False, 
	low_memory=False, 
	keep_default_na=False, 
	sep=delimiter,
	encoding ='latin1'
)

engine = sa.create_engine("mssql+pymssql://"+server+"/"+database)
connection = engine.connect()

print('Start insert into Sql Server')
df.to_sql(name=table, index=False, con=connection, schema=schema, if_exists=ifExists, dtype={col_name: sa.NVARCHAR(length=4000) for col_name in df})

print('Completed successfully')

