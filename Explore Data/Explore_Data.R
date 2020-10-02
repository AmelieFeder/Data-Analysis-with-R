#### XRD mineralogical data exploration

library(odbc)           # database connection
library(RSQLite)        # allows SQL commands 
library(dplyr)          # transforms data

# Establish connection to database
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "SQL Server",
                      Server   = "localhost",
                      Database = "Sossusvlei_Sedimentology",
                      UID      = "sa",
                      PWD      = "SuperSecretPassword123!",
                      Port     = 1433)


XRD_Mineralogy <- dbGetQuery(con, 'Select * From(
  Select SampleName, Facies, Amount, Mineral
  from SampleOverview o inner join XrdMineralogy x
  on o.Id = x.SampleId
) t
Pivot(Max(Amount) for Mineral IN ([Almandine], [Ilmenite], 
                             [Quartz], [Ankerite], [Chlorite], 
                             [Gypsum], [Pyroxene], [Microcline], 
                             [Calcite], [Andalusite], [Pyrite], 
                             [Magnetite], [Albite], [Heulandit], 
                             [Hematite], [Illite], [Anhydrite], 
                             [Dolomit], [Hornblende])) 
                             AS pivot_table;')


head(XRD_Mineralogy)                # quick overview over data
str(XRD_Mineralogy)                 # check classses of data
summary(XRD_Mineralogy)             # summary statistic of data 

## Transform data 
# Create new columns with aggregate several other columns
XRD <-mutate(XRD_Mineralogy, 
       Carbonates = Calcite + Dolomit + Ankerite,
       Other = Almandine + Ilmenite + Gypsum + Magnetite 
       + Heulandit + Hematite + Hornblende + Anhydrite 
       + Pyrite + Andalusite,
       Clay = Illite + Chlorite
          )
# Drop the aggregated columns
XRD <- select(XRD, -c(Calcite, Dolomit, Ankerite, 
                      Almandine, Ilmenite, Gypsum, 
                      Magnetite, Heulandit, Hematite, 
                      Hornblende, Anhydrite, Pyrite, 
                      Andalusite, Illite, Chlorite))

# Order the columns after my preference
XRD %>% relocate(any_of(c("Facies", "SampleName", 
                          "Quartz", "Albite", 
                          "Microcline","Clay", 
                          "Carbonates", "Pyroxene", 
                          "Other")))

## Explore Data
# Create a summary of the mean values of the mineral content in each facies
XRD_by_facies <- XRD %>%
  group_by(Facies) %>%
  summarise(
        Quartz = mean(Quartz, ra.rm = TRUE),
        Albite = mean(Albite, ra.rm =TRUE),
        Microcline = mean(Microcline, ra.rm =TRUE),
        Clay = mean(Clay, ra.rm =TRUE),
        Pyroxene = mean(Pyroxene, ra.rm =TRUE),
        Other = mean(Other, ra.rm =TRUE),
      )
print(XRD_by_facies)

# Filter Samples with high clay content
XRD_high_clay <- filter(XRD, Clay > 10)

# Filter facies with high quartz and high pyroxene content
XRD_hQz_hPx <- XRD %>%
  group_by(Facies) %>%
  filter(Quartz >60, Pyroxene >5)


plot(XRD[3:9])             # quick overview plot to check for correlation between minerals

summary(XRD[,"Quartz"])    # summary statistic for one mineral


## univariate plots
# Histogram
hist(XRD$Quartz, xlab = "Quartz content in [%]", main="Quartz" )

# Density Histogram
density(log(XRD$Carbonates), na.rm = TRUE)
plot(Carb_Density)
hist(log(XRD$Carbonates), probability = TRUE,
     xlab = "log(Carbonate Minerales) in [%]",
     main = "Carbonate Minerals")
lines(Carb_Density$x, Carb_Density$y, col="black", lwd = 3)

# Boxplot
boxplot(XRD[,3:9], las =2)


## Exploring relationship between two variables
# fitting linear model and calculating regression line
plot((XRD$Carbonates)~ (XRD$Clay),
     xlab = "Clay minerals in [%]",
     ylab = "Carbonate minerals in [%]",
     main = "Relationship of carbonate and clay minerals",
     pch = 16)
regression_line <- lm(Carbonates~ Clay, data=XRD)        # calculate linear model
abline(regression_line, col=2, lwd = 4, lty=2)           # plot regression line
sm_rl <- summary(regression_line)                        # summary of linear regression
sm_rl$r.squared                                          # extracting R2

##Principal Component Analysis
# Create filter to filter out rows with 0
XRD <- filter(XRD, Pyroxene > 0 
              & Carbonates >0 & Other >0 
              & Clay > 0)

XRD_values = XRD[,4:8]                            # subset data to only contain the columns with mineralogical content
pc = princomp(XRD_values)                         # calculate a principal component analysis
biplot(pc, xlabs=rep("x",                         # create a biplot
                     nrow(XRD_values), 
                     choice= c(3,2)))       
loadings(pc)                                      # view loadings
screeplot(pc, main = "Principal Components")      # variance of each principal component
