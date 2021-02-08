### NOTES ####

# In this Shinyapp.io, I have reproduced my original work in the minimalist way where I reduced the
# numnber of obeservations, dropped columns, and turned off the data table option for ShinyDashboard.
# Since my original work exceeds the RAM limit, I have created this as the minimal representation
# of my work. You may still be disconnected from the server.

# Please feel free to check my original shinnyapp work that I have uploaded as **saved.r**
# (if you would like to check on your local computer). Everything works fine on local 
# computers since there is no 1GB of Ram Limit! I apologize for making things complicated...!
# The shinyapp address is at the bottom of this document. 

# Please do not hesitate to let me know if you have any questions or concern,

# Loading the libraries
library(shinydashboard)
library(shinythemes) # stylizing the shiny webpage
library(leaflet) # pretty & interactive maps
library(tidyverse) # basic toolkit
library(here) # reproducibility
library(sf) # reading spatial data
library(lubridate) # used for Data Conversion
library(leaflet.extras) # cache

### Loading the data ###

stjoined <- readRDS("rds.data/stjoined.rds")
crime <- readRDS("rds.data/crime2.rds")
street <- readRDS("rds.data/street.rds")

# Define UI for application
ui <- dashboardPage(
  skin = "red",
  dashboardHeader(title = "Crime Rates in the City of Chicago in 2020", titleWidth = 500), #header
  dashboardSidebar(
    selectInput(inputId = "month", 
                label = "Choose the Month", 
                choices = sort(unique(crime$month))
                ),
    selectInput(inputId = "type", 
                label = "Choose The Type of Crime", 
                choices = unique(crime$`Primary Type`)
                )
    ),
  dashboardBody(
    # Tag Style Source: https://stackoverflow.com/questions/36469631/how-to-get-leaflet-for-r-use-100-of-shiny-dashboard-height
    tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"), # ideal ratio for shinyDashboard!
    fluidRow(box(width = 12, leafletOutput(outputId = "map"))), # Output1: Map
  )
)


# Define the Server

server <- function(input, output) {
  
  data_input <- reactive({ # using the reactive function to make it interactive
    
    crime %>% 
      filter(month == input$month) %>% 
      filter(`Primary Type` == input$type)
  }) 
  
  output$map <- renderLeaflet({
    
    # Setting the pal for leaflet 
    pal <- colorNumeric("YlOrRd", domain = NULL, n = 4) # creating the color numeric
    pal2 <- colorNumeric("Blues", domain = NULL, n = 4)
    
    # Map1: filled the city of chicago with pop and labeled it by zip
    map1 <- leaflet() %>%
      addTiles(options = tileOptions(useCache = TRUE,
                                     crossOrigin = TRUE)) %>% 
      addPolygons( # Important to take a look at the geometry type for the given data
        data = stjoined,
        weight = 1,
        fillColor = ~pal(population),
        fillOpacity = 0.01,
        smoothFactor = 0.5,
        popup = paste("Zipcode:", stjoined$zip, 
                      "& Population:", stjoined$population), 
        group = "Population"
      ) %>%
      addPolygons(
        data = stjoined,
        weight = 1,
        fillColor = ~pal2(cum),
        fillOpacity = 0.05,
        smoothFactor = 0.5,
        popup = paste("Cum. Covid Cases:", stjoined$cum), 
        group = "Cum. Covid Cases"
      ) %>%
      addLayersControl(
        baseGroups = c("Population", "Cum. Covid Cases"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      hideGroup("Cum. Covid Cases")
      
    
    # Map2: Added some legend to help figure out the color
    map2 <- map1 %>%
      addLegend(pal = pal, 
                values = stjoined$population[!is.na(stjoined$population)],
                title = "Population") %>% # adding Legend to give information about the color of the map
      addLegend(pal = pal2,
                values = stjoined$cum[!is.na(stjoined$cum)],
                title = "Cum. Covid Cases",  # adding Legend to give information about the color of the map
      )
    
    # Map4: Added Major Street File Information
    map3 <- map2 %>%
      addPolylines(data = street, 
                   weight = 1,
                   opacity = 1,
                   color = "white",
                   group = "See Street Info",
                   label = ~ paste("Street Address:", street$STREET_NAM)) %>%
      addLayersControl(
        overlayGroups = "See Street Info", 
        options = layersControlOptions(collapsed = FALSE),
        position = "topleft"
      ) %>%
      hideGroup("See Street Info")
    
    # Map5 Added Chicago Crime Data 2019-2020
    map4 <- map3 %>%
      addMarkers(
        data = data_input(),
        clusterOptions = markerClusterOptions(zoomToBoundsOnClick = TRUE),
        popup = paste(data_input()$Date, ", Crime Description:", data_input()$Description)
      ) %>%
      addLayersControl(
        overlayGroups = "See Street Info", 
        baseGroups = c("Population", "Cum. Covid Cases"),
        options = layersControlOptions(collapsed = FALSE),
        position = "topleft"
      ) %>%
      hideGroup("See Street Info")
    
    # Show Map
    map4
    
  }) 
  
}

# Run the application 
shinyApp(ui = ui, server = server)

# shinny address: https://boseongyun.shinyapps.io/homework-2-boseongyun/
