### Simple Plots

#Open libraries
library(odbc)           # database connection
library(RSQLite)        # allows SQL commands
library(plyr)           # used to rename factor values
library(ggplot2)        # plot package
library('ggtern')       # allows ternary plots

# Establish connection to database
con <- DBI::dbConnect(odbc::odbc(),
                      Driver   = "SQL Server",
                      Server   = "localhost",
                      Database = "Sossusvlei_Sedimentology",
                      UID      = "sa",
                      PWD      = "SuperSecretPassword123!",
                      Port     = 1433)

# load data into a data.frame
XRF <- dbGetQuery(con, 'Select * from(                      
	Select SampleName, Facies, Amount, MajorElement
		from SampleOverview o inner join XrfMainElement m
			on o.Id = m.SampleId)t Pivot(Max(Amount) for 
			MajorElement IN([Al2O3], [CaO],[Fe2O3], [K2O], 
			[LOI], [MgO], [MnO], [Na2O], [P2O5],
      [SiO2], [TiO2])) As pivot_table;')

# start working with the data
head(XRF)                   # quick overview over data
str(XRF)                    # details of data.frame
summary(XRF)                # summary statistics

XRF$Facies <- factor(XRF$Facies)     # facies as factor to use as group

# The facies column contains several different River_XX facies. To summarize these, they are all revalued as River
mapvalues(XRF$Facies, 
          from = c("River_ intermediate _17", "River_distal_17", 
          "River_intermediate_07", "River_proximal_07", "River_proximal_17"), 
          to = c("River", "River","River","River","River"))

# Create a overview plots to see possible correlations
plot(XRF[3:13], col=XRF$Facies)


#Major elements sandstone classification after Herron (1988)
plot(log(XRF$Fe2O3/XRF$K2O) ~ log(XRF$SiO2/XRF$Al2O3),
     xlab = "SiO2/Al2O3",
     ylab = "Fe2O3/K2O",
     pch = c(16, 17, 18, 19, 20, 0,1,2)[as.numeric(Facies)],  
     main = "Geochemical Sandstone Classification",
     col = c("red", "green","blue", "yellow", "pink", "hotpink", "grey", "black")[as.numeric(Facies)],
     data = XRF)
legend("topleft",
       legend = c(XRF$Facies),
       col = c("red", "green","blue", "yellow", "pink", "hotpink", "grey", "black")[as.numeric(Facies)],
       pch = c(16, 17, 18, 19, 20, 0,1,2)[as.numeric(Facies)],
       cex = 1.2)


## Harker Diagrams
par(mfrow=c(4,2))
#TiO2
plot(XRF$SiO2,XRF$TiO2,
     xlim=c(40,90), ylim=c(0.2,1.2), 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="TiO2 [wt%]")

#Al2O3
plot(XRF$SiO2,XRF$Al2O3, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="Al2O3 [wt%]")

#FeO
plot(XRF$SiO2,XRF$Fe2O3, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="Fe2O3 [wt%]")

#MnO
plot(XRF$SiO2,XRF$MnO, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="MnO [wt%]")

#CaO
plot(XRF$SiO2,XRF$CaO, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="CaO [wt%]")

#MgO
plot(XRF$SiO2,XRF$MgO, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="MgO [wt%]")

#Na2O
plot(XRF$SiO2,XRF$Na2O, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="Na2O [wt%]")

#K2O
plot(XRF$SiO2,XRF$K2O, 
     col=XRF$Facies, pch=21, bg=XRF$Facies, 
     xlab="SiO2 [wt%]", ylab="K2O [wt%]")

dev.off() 


## Chemical Weathering Index
# CIA Boxplot
ggplot(data=XRF, aes(x=Facies, y=((Al2O3/(Al2O3+CaO+Na2O+K2O))*100)))+
  geom_boxplot(aes_(), size=1)+ ylab('CIA')+
  theme_classic()

#A-CN-K Weathering Plot
ggtern(data=XRF,aes(x=(CaO+Na2O),y=Al2O3,z=K2O, group=Facies))+
  geom_point(aes(colour=factor(Facies)), size=3)+
  theme_classic()+
  xlab('CN')+ylab('A')+zlab('K')+
  theme(legend.title=element_blank())


##Regression line
#LOI
plot(15,  xlim = c(0,40), ylim = c(0,14), xlab='LOI [wt%]', ylab='[wt%]')
abline(lm(XRF$MgO ~ XRF$LOI), col='violet')
abline(lm(XRF$CaO~XRF$LOI), col='blue')
points( XRF$LOI,XRF$MgO, col='violet', pch=21, bg=XRF$Facies)
points( XRF$LOI,XRF$CaO, col='blue', pch=21, bg=XRF$Facies)
legend(-1.6, 14.55, legend=c("CaO", "MgO" ),
       col=c("blue", "violet"), lty = 1,cex=0.8 )

#SiO2
plot(15, xlim=c(10,50), ylim=c(2,50), xlab='LOI [wt%]', ylab='[wt%]')
abline(lm(XRF$CaO~XRF$LOI), col='blue')
abline(lm(XRF$MgO~XRF$LOI), col='violet')
legend(38, 10.4, legend=c("CaO", "MgO" ),
       col=c("blue", "violet"), lty = 1,cex=0.8 )