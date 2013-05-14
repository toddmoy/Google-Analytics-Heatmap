# traffic_heatmap.r
# This script produces a heatmap that shows pageviews (or any metric, really)
# in a days x hours matrix. It pulls data directly from Google Analytics.

library("RGoogleAnalytics")
library("RColorBrewer")


# CONNECT AND QUERY -----------------------------------------------------------

query <- QueryBuilder()

# Open Google's OAuth Playground in the default browser.
# You will need to exchange your Authorization Code for an Access Token.
access_token <- query$authorize()

ga <- RGoogleAnalytics()

# Get list of profiles and echo to the console. You will use the left-most number for the
# profile you want to query in the next step.
( ga.profiles <- ga$GetProfileData(access_token) )

# Edit the query parameters
my_profile    <- 1              # Your profile number (not the GA ID number)
my_start_date <- "2013-01-01"   # Query date range
my_end_date   <- "2013-03-31"

# Build the query string. 
# For more info on dimensions, filters, and other query configuration options, see: 
# http://ga-dev-tools.appspot.com/explorer/
query$Init(start.date = my_start_date,
           end.date = my_end_date,
           dimensions = "ga:dayOfWeek, ga:hour",
           metrics = "ga:pageviews",
           max.results = 10000,
           access_token=access_token,
           table.id = paste("ga:",ga.profiles$id[my_profile],sep="",collapse=",")  
           # If you know the exact table id you want to use (uncommon), replace the line above with:
           # table.id = "ga:99999999" # Replace 999s with your table ID.
           )

# Query the API and store the result in a Data Frame.
ga.data <- ga$GetReportData(query)  


# MUNGE THE DATA --------------------------------------------------------------

# Change values in dayOfWeek from 0 - 6 to Sun - Sat.
ga.data$dayOfWeek <- as.character(ga.data$dayOfWeek)
ga.data$dayOfWeek[ga.data$dayOfWeek == "0"] <- "Sunday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "1"] <- "Monday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "2"] <- "Tuesday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "3"] <- "Wednesday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "4"] <- "Thursday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "5"] <- "Friday"
ga.data$dayOfWeek[ga.data$dayOfWeek == "6"] <- "Saturday"

# Use a sensible order.
ga.data$dayOfWeek <- factor(ga.data$dayOfWeek, levels = c("Sunday", 
                                                          "Monday", 
                                                          "Tuesday", 
                                                          "Wednesday", 
                                                          "Thursday", 
                                                          "Friday", 
                                                          "Saturday"))
ga.data[order(ga.data$dayOfWeek),]

# Convert data frame to xtab. Make pageviews the intersection of day and hour.
heatmap_data <- xtabs(pageviews ~ dayOfWeek + hour, data=ga.data)


# DRAW IT ---------------------------------------------------------------------

heatmap(heatmap_data, 
        col=colorRampPalette(brewer.pal(9,"Reds"))(100),  # Use ColorBrewer's nicer color palettes.
        revC=TRUE,                                        # Start the week at the top of the Y axis.
        scale="none",                                     # Map color density to entire week, not a day or hour slice.
        Rowv=NA, Colv=NA,                                 # Don't use a dendogram.
        main="Pageviews by Day and Hour",                 # Title.
        xlab="Hour")                                      # X-axis label.