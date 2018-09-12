library(nycflights13)
library(DBI)

con <- dbConnect(odbc::odbc(), "Teradata")

dbWriteTable(con, "flights", flights)
dbWriteTable(con, "airports", airports)
dbWriteTable(con, "airlines", airlines)

dbRemoveTable(con, "flights")
dbRemoveTable(con, "airports")
dbRemoveTable(con, "airlines")
