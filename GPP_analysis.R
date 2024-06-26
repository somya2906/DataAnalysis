#This task involves analysis of a raw data set which we can find on open source data websites. 
#For this task I am analyzing a **GLOBAL POWER PLANT DATABASE**. 
#The data was fetched from this data source - <https://datasets.wri.org/dataset/globalpowerplantdatabase>
#The data specifically getting analysed is - <https://wri-dataportal-prod.s3.amazonaws.com/manual/global_power_plant_database_v_1_3.zip>

#### Description #############

#The Global Power Plant Database is a comprehensive, open source database of power plants around the world. The database covers approximately 35,000 power plants from 167 countries and includes thermal plants (e.g. coal, gas, oil, nuclear, biomass, waste, geothermal) and renewable (e.g. hydro, wind, solar).

#### Citation #############
#Global Energy Observatory, Google, KTH Royal Institute of Technology in Stockholm, Enipedia, World Resources Institute. 2018. Global Power Plant Database.

### Code ############
library(rio)
library(dplyr)
library(forcats)
library(ggplot2)
library(tidyr)
library(stringr)

# importing data
PowerPlant <- import("global_power_plant_database.csv", na.strings=c(""," ","NA"))

# remove some unwanted columns
PowerPlant <- PowerPlant |>
  select(-(other_fuel2:other_fuel3), -owner, -(url:wepp_id),-generation_data_source,
         -(estimated_generation_note_2013:estimated_generation_note_2017))

# Rename columns
PowerPlant <- PowerPlant |>
  mutate_if(is.numeric, round, 2) |>
  mutate(commissioning_year = round(commissioning_year, digits=0)) |>
  rename(secondary_fuel = other_fuel1, estimated_gwh_2013 = estimated_generation_gwh_2013, `Country Name` = country_long,
         estimated_gwh_2014 = estimated_generation_gwh_2014,
         estimated_gwh_2015 = estimated_generation_gwh_2015,
         estimated_gwh_2016 = estimated_generation_gwh_2016,
         estimated_gwh_2017 = estimated_generation_gwh_2017)

# clean data
PowerPlant <- PowerPlant |>
  mutate(secondary_fuel = ifelse(is.na(secondary_fuel),"No","Yes"))|>
  mutate(primary_fuel = factor(primary_fuel), secondary_fuel = factor(secondary_fuel),
         `Country Name` = factor(`Country Name`)) |>
  filter(commissioning_year >= 2000)

# See for how many countries data is present in the data set
fct_count(PowerPlant$`Country Name`,sort = TRUE)

# See how many power plants are using secondary fuel
PowerPlant_secfuel <- PowerPlant |>
  count(secondary_fuel)
PowerPlant_secfuel

# See how much power is generated by each fuel
capacity_by_fuel <- tapply(PowerPlant$capacity_mw, PowerPlant$primary_fuel, 
                           sum, na.rm = TRUE, sort = TRUE)

sort(capacity_by_fuel,decreasing = TRUE)

# Visualize which top 10 countries countribute to the majority of power generation
capacity_by_country <- PowerPlant |>
  group_by(`Country Name`)|>
  summarise('Total_Capacity' = sum(capacity_mw)) |>
  arrange(desc(Total_Capacity))

capacity_by_country_10 <- head(capacity_by_country,10)


ggplot(capacity_by_country_10, aes(x=reorder(`Country Name`,-Total_Capacity),
                                   y=Total_Capacity,fill=`Country Name`)) +
  geom_bar(stat="identity", position="dodge") +
  labs(x= "Country" , y="Capacity(mw)") +
  scale_x_discrete(guide = guide_axis(angle = 90))

# Analyze how over the years from 2000-2020, the setup of new power plants has happened
PowerPlant_year <- PowerPlant |>
  group_by(commissioning_year) |>
  tally()

ggplot(PowerPlant_year, aes(x=commissioning_year,y=n)) +
  geom_bar(stat="identity", position="dodge",color="blue") +
  labs(x= "Year" , y="Count")

# We will compare current and estimated generation for year 2013-2017
PowerPlant_na <- PowerPlant |>
  select(`Country Name`,name,(generation_gwh_2013:estimated_gwh_2017)) 

PowerPlant_na <- PowerPlant_na[complete.cases(PowerPlant_na),]

PowerPlant_long <- pivot_longer(PowerPlant_na,cols = generation_gwh_2013:estimated_gwh_2017,
                                   names_to = "generation_type", values_to = "generation_value")


PowerPlant_long[c("generation_type","col2","generation_year")] <- 
           str_split_fixed(PowerPlant_long$generation_type,"_",3)

PowerPlant_long <- PowerPlant_long |>
  select(-col2) |>
  filter(generation_year != "2018" & generation_year != "2019") |>
  filter(generation_value > 1000 & generation_value < 2000 ) |>
  relocate(generation_year)

head(PowerPlant_long)

# visualize the comparison between actual power generation and estimated power generation for years 2013-2017. 
# And more specifically for generation value between 1000-2000 GWH

ggplot(PowerPlant_long, aes(x=name, y=generation_value, color = generation_type)) +
  geom_point() +
  geom_line() +
  labs(x= "Power plant name", y="Generation(gwh)") +
  scale_x_discrete(guide = guide_axis(angle = 90)) +
  facet_wrap(~generation_year) 
