# Loading the libraries
library(shiny)
library(shinydashboard)
library(shinythemes) # stylizing the shiny webpage
library(leaflet) # pretty & interactive maps
library(plyr) # mapvalues
library(tidyverse) # basic toolkit
library(here) # reproducibility
library(sf) # reading spatial data
library(RColorBrewer) # adding color brewer to R
library(lubridate) # used for Data Conversion
library(DT) # used for DataTable


### Loading the data ###

# Shape File1 : Loading the City of Chicago's ZIP shapefile
zip <- st_read(here("data/zipshape/geo_export_76ba1696-a790-46f2-8b95-e9b7a5ec3ce6.shp")) %>%
  st_transform(4326) # making the type uniform to 4326

## Data of Interest 1: Population & Covid Data

# (add-on): Cumulative Population & Covid Data
# Source: https://data.cityofchicago.org/Health-Human-Services/COVID-19-Progression-by-ZIP-Code/vrgd-sgft
cum <- read_csv("data/cum.csv")

## Date of Interest1: Population & Covid Data
# Mutating the cum (cases) & population to make sure that the date range of crime data is the same
# I am adding these values based on the zip code since these are primary interets
# The Source for the following geojson: https://data.cityofchicago.org/Health-Human-Services/COVID-19-Cases-Tests-and-Deaths-by-ZIP-Code/yhhz-zm2v
pop <- st_read("https://data.cityofchicago.org/resource/yhhz-zm2v.geojson") %>% # using the web address to increase reproducibility & to stay updated
  st_transform(4326) %>%
  mutate(cum = mapvalues(zip_code, cum$zip, cum$cum))

# Joining the population data
stjoined <- zip %>%
  st_join(pop, suffix = c("", ".y")) %>% # st_join to join the two shape file
  select(-ends_with(".y")) %>%
  mutate_at(vars(cases_cumulative, zip, population, cum), as.numeric)

# Data of Interest 2: Looading the crime data for the city of Chicago in 2020
# Source: https://data.cityofchicago.org/Public-Safety/Crimes-2020/qzdf-xmn8
crime2020 <- read_csv("data/Crimes_-_2020.csv")  %>%
  mutate(Date = mdy_hms(Date)) # changing it into a time object

# Transforming the crime data into geometry objects for interactive map design
crime <- st_as_sf(crime2020, 
                  coords = c("Longitude", "Latitude"), 
                  na.fail = FALSE) %>%
  st_set_crs(4326) 

# Data of Interest 2 (add-on): Saving the police station location data
# Source: https://data.cityofchicago.org/Public-Safety/Police-Stations/z8bn-74gv
polstat <- st_read("https://data.cityofchicago.org/resource/z8bn-74gv.geojson") %>% # using the webaddress to increase reproducibility & to stay updated
  st_transform(4326) # making the type uniform to 4326

# Loading Chicago Major Street Shapefile
# Source: https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-ZIP-Codes/gdcf-axmw
street <- st_read("data/majorshape/Major_Streets.shp") %>%
  st_transform(4326) # making the type uniform to 4326

# Define UI for application
ui <- dashboardPage(
  skin = "red",
  dashboardHeader(title = "Crime Rates in the City of Chicago 2019-2020", titleWidth = 500), #header
  dashboardSidebar(
    sliderInput(inputId = "date", 
                label = "The Range of Date", 
                min = min(crime$Date), 
                max = max(crime$Date),
                value = c(min(crime$Date), max(crime$Date)),
                timeFormat = "%b %Y" # Setting the time format
    ),
    selectInput(inputId = "type", 
                label = "The Type of Crime", 
                choices = unique(crime$`Primary Type`)
    )
    
  ),
  dashboardBody(
    # Tag Style Source: https://stackoverflow.com/questions/36469631/how-to-get-leaflet-for-r-use-100-of-shiny-dashboard-height
    tags$style(type = "text/css", "#map {height: calc(100vh - 80px) !important;}"), # ideal ratio for shinyDashboard!
    fluidRow(box(width = 12, leafletOutput(outputId = "map"))), # Output1: Map
    fluidRow(box(width = 12, dataTableOutput(outputId = "data"))) # Output2: Table
  )
  
)


# Define the Server

server <- function(input, output) {
  
  data_input <- reactive({ # using the reactive function to make it interactive
    
    crime %>% 
      filter(between(Date, input$date[1], input$date[2])) %>% # here [1] refers to the lower value & [2] refers to the upper value
      filter(`Primary Type` == input$type)
  }) 
  
  output$map <- renderLeaflet({
    
    # Setting the pal for leaflet 
    pal <- colorNumeric("YlOrRd", domain = NULL, n = 4) # creating the color numeric
    pal2 <- colorNumeric("Blues", domain = NULL, n = 4)
    
    # Map1: filled the city of chicago with pop and labeled it by zip
    map1 <- leaflet() %>%
      addTiles() %>% 
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
    
    # Map3: Added Police Data
    # Source: Source: https://stackoverflow.com/questions/51564365/addmarkers-in-leaflet-in-r
    
    map3 <- map2 %>%
      addMarkers(
        data = polstat,
        lng = as.numeric(polstat$longitude), 
        lat = as.numeric(polstat$latitude),
        popup = paste("Police Stataion:", polstat$address), 
        icon = list(
          # I have serached for the relevant icon for police station through iconarchive.com
          iconUrl = "https://icons.iconarchive.com/icons/google/noto-emoji-people-profession/128/10425-man-police-officer-medium-dark-skin-tone-icon.png",
          iconSize = c(15, 15)
        )
      )
    
    # Map4: Added Major Street File Information
    map4 <- map3 %>%
      addPolylines(data = street, 
                   weight = 2,
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
    map5 <- map4 %>%
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
    
    
  }) 
  
  output$data <- renderDataTable({
    
    DT::datatable(
      data_input(), 
      extensions = c("Scroller"), # adds the scroller to make it eaiser to find the relevant data
      options = list("scrollY" = TRUE, # scroller on the Y-axis
                     "scrollX" = TRUE) # scorller on the X-axis
    )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
