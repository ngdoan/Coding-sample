rm(list = ls())
options(scipen=999)

packages <- c("dplyr","janitor","readxl","stringr","lubridate","openxlsx","tidyr")

#lapply(packages, install.packages, character.only = TRUE)
lapply(packages, library, character.only = TRUE)

folder <- "[insert path]"
input <- paste0(folder, "Data/")
output <- paste0(folder, "Exhibits/Exhibit 1-2/Output/")

input_data <- read_excel(paste0(input, "redacted.xlsx"), skip = 1) %>% clean_names()

revenues <- input_data %>% 
  filter(!is.na(studio_name),
         brand == "redacted",
         pricing_tier %in% c("Tier 3", "Tier 4", "Tier 2")) %>% 
  select(studio_name,brand, pricing_tier, soft_open_date,24:69) %>% 
  gather(key=key,value=value,contains("x4")) %>% 
  mutate(key=as.numeric(str_extract(key,"[:digit:]+")),
         date = make_date(2019,1,31) + key-43496) %>% 
  group_by(studio_name) %>% 
  filter(date >= soft_open_date) %>% 
  mutate(month = row_number()) %>% 
  ungroup() 

pre_post_covid <- revenues %>%
  filter(date >= make_date(2020,1,1) & date <= make_date(2020,9,30)) %>% 
  filter(date <= make_date(2020,4,1) | date >= make_date(2020,7,1)) %>% 
  group_by(studio_name) %>% 
  summarise(pre_post_covid_avg = mean(value, na.rm = T)) %>% 
  ungroup()

covid_adj <- revenues %>% 
  left_join(pre_post_covid, by = "studio_name") %>% 
  mutate(covid_adj = ifelse(date >= make_date(2020,4,1) & date <= make_date(2020,6,30),pre_post_covid_avg,value)) 

index_tier_means <- revenues %>% 
  filter(studio_name != "redacted") %>% 
  group_by(pricing_tier,month) %>% 
  summarise(index_means = mean(value, na.rm = T)) %>% 
  ungroup() %>% 
  spread(key=pricing_tier,value=index_means)

adj_index_tier_means <- covid_adj %>% 
  filter(studio_name != "redacted") %>% 
  group_by(pricing_tier,month) %>% 
  summarise(index_means = mean(covid_adj, na.rm = T)) %>% 
  ungroup() %>% 
  spread(key=pricing_tier,value=index_means)

exhibit_1A <- revenues %>%  
  filter(pricing_tier == "Tier 3") %>% 
  select(studio_name,month,value) %>% 
  spread(key=studio_name,value=value) %>% 
  left_join((index_tier_means %>% select(month,`Tier 3`)), by = "month") %>% 
  mutate(month = paste0("Month ",month)) 

exhibit_1B <- covid_adj %>%  
  filter(pricing_tier == "Tier 3") %>% 
  select(studio_name,month,covid_adj) %>% 
  spread(key=studio_name,value=covid_adj) %>% 
  left_join((adj_index_tier_means %>% select(month,`Tier 3`)), by = "month") %>% 
  mutate(month = paste0("Month ",month))

exhibit_2 <- revenues %>% 
  filter(studio_name == "redacted",
         value != 0) %>% 
  select(month,studio_name,value) %>% 
  spread(key = studio_name, value = value) %>% 
  full_join((index_tier_means %>% select("month","Tier 3"))) %>% 
  full_join((adj_index_tier_means %>% select("month","Tier 3 - Adjusted"="Tier 3"))) %>% 
  filter(month <= 25) %>% 
  mutate(month = paste0("Month ",month))

output_list <- list("Exhibit 1.A Output" = exhibit_1A,"Exhibit 1.B Output" = exhibit_1B,"Exhibit 2 Output" = exhibit_2)
write.xlsx(output_list, paste0(output,"2022.11.23 - Exhibit 1-2 Output.xlsx"), overwrite = T)
