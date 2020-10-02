# Explore mineralogical data

This file shows part of my data exploration process of my mineralogical data. The data was derived by XRD analysis and is stored in a SQL database. Prior to storing it, the data was already cleaned. However, it contains zero’s as it is possible for some minerals to not occur in some samples.

The data has the following structure:
|SampleId|Facies|Mineral1   |Mineral2
|---|---|---|---|---|
|Sample1|Facies1|#Value|#Value|


### Workflow
First, I establish a connection with the database and load the XRD data formatted as a data frame into R. The data frame contains a lot of columns with zero or very low values (mineral contents). These accessory minerals are not the focus of my analysis, so they are aggregated to mineral groups. 

A quick overview plot was used to get a general sense of the data.
