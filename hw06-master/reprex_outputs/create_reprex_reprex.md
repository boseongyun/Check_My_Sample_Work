``` r
# This file contains all the code chunks used in happiness_report.Rmd. Every header indicates the name of the code chunk used in the R markdown file. This file has been created to reproduce the results using reprex() pacakge in the entire R script file. 

# R setup
library(tidyverse)
library(reprex)
library(stringi)
library(knitr)
library(here)
#> here() starts at /home/boseongyun/homeworks/hw06
library(cowplot)
#> 
#> ********************************************************
#> Note: As of version 1.0.0, cowplot does not change the
#>   default ggplot2 theme anymore. To recover the previous
#>   behavior, execute:
#>   theme_set(theme_cowplot())
#> ********************************************************
library(glue)
#> 
#> Attaching package: 'glue'
#> The following object is masked from 'package:dplyr':
#> 
#>     collapse

# r import_data

## Importing happiness File
happiness <- read_csv(here("data", "original_hm.csv")) # using here package to increase reproducibility related to filepaths on other computers 
#> Parsed with column specification:
#> cols(
#>   hmid = col_double(),
#>   hm = col_character(),
#>   reflection = col_character(),
#>   wid = col_double()
#> )

## Importing demographics file
demographics <- read_csv(here("data", "demographic.csv"))
#> Parsed with column specification:
#> cols(
#>   wid = col_double(),
#>   age = col_character(),
#>   country = col_character(),
#>   gender = col_character(),
#>   marital = col_character(),
#>   parenthood = col_character()
#> )


# r data_cleaning
glimpse(happiness)
#> Rows: 101,094
#> Columns: 4
#> $ hmid       <dbl> 27673, 27674, 27675, 27676, 27677, 27678, 27679, 27680, 27…
#> $ hm         <chr> "I went on a successful date with someone I felt sympathy …
#> $ reflection <chr> "24h", "24h", "24h", "24h", "24h", "24h", "24h", "24h", "2…
#> $ wid        <dbl> 2053, 2, 1936, 206, 6227, 45, 195, 740, 3, 4833, 7334, 78,…
glimpse(demographics)
#> Rows: 10,844
#> Columns: 6
#> $ wid        <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,…
#> $ age        <chr> "37.0", "29.0", "25", "32", "29", "35", "34", "29", "61", …
#> $ country    <chr> "USA", "IND", "IND", "USA", "USA", "IND", "USA", "VNM", "U…
#> $ gender     <chr> "m", "m", "m", "m", "m", "m", "m", "m", "f", "m", "m", "f"…
#> $ marital    <chr> "married", "married", "single", "married", "married", "mar…
#> $ parenthood <chr> "y", "y", "n", "y", "y", "y", "y", "n", "y", "n", "n", "n"…

# Thanks to tidy-savvy techinican, the original data is in a tidy format! However, some of the datasets have to be merged together and there are strings in columns that are not best suited for the intent of my analysis. They have been cleaned and modified. 

happiness_joined <- happiness %>%
  inner_join(demographics, by = "wid") %>%  # Joining the demographics dataframe
  mutate(gender = str_replace_all(gender, c("m" = "Male", "f" = "Female", "o" = "Others")), # changing it to more informative names. For instance, "o" may not make immediate sense.
         parenthood = str_replace_all(parenthood, c("y" = "TRUE", "n" = "FALSE", "na" = "NA"))) %>% 
  mutate(
    age = substr(age, start = 1, stop = 2), # Using unique funnction shows that some of the ages are 233 and 237. Limiting the age variable 2-digits at max
    age = as.numeric(age), # There are unidentifible characters in the age column that prevetns analysis. as.numeric() function makes the numbers numeric and coerces characters to NA value
    age_group = cut(age,  # Creating age groups for easy comparison of age categories.
                    breaks = seq(0, 100, by = 10),
                    labels = c("0-10", "10-20", "20-30", "30-40", "40-50",
                               "50-60", "60-70", "70-80", "80-90", "90-100"),
                    ordered_result = TRUE), 
    word_count = stri_count(hm, regex = "\\S+")
  ) %>%
  filter(!is.na(age))
#> Warning: NAs introduced by coercion

## I have not filtered out NA value in the gender category because there was no documentatio on the NA value and, considering gender fluidity, NA can be in and of itself can store valuable information. 
## I have changed the number to numeric. There were NA values and other character value "I don't want to say". I have filtered them out because I would like to use age as one of my primary dependent variables. 
## I have referred the folloing website to learn how to replace multiple strings: https://stackoverflow.com/questions/50842140/replace-multiple-words-in-r-easily-str-replace-all-gives-error-that-two-objects
## I have referred the following website to learn about cut function to assign a value based on the range of another variable: https://stackoverflow.com/questions/21050021/create-category-based-on-range-in-r


# r by_gender

## Creating a dataframe that calculates the number of words used to describe happy moments by gender
hap_gender <- happiness_joined %>%
  group_by(gender) %>%
  summarize(
    num_people = n(), 
    word_count_total = sum(word_count, na.rm = TRUE),
    word_count_per_person = word_count_total / num_people
  )

## Visualization of the hap_gender dataframe.
hap_gender %>%
  ggplot(aes(x = gender, y = word_count_per_person, label = num_people)) +
  geom_col() +
  geom_label() +
  labs(
    title = "The Number of Words Used to Describe Happy Moments by Gender per Person",
    subtitle = "(from the survey of Amazon Mechanical Turk workers from 2017-03-28 to 2017-06-26)",
    x = "", 
    y = "Number of Words",
    caption = "Source: HappyDB"
  )
```

![](https://i.imgur.com/XBB1HRB.png)

``` r

## Data Frame that shows the numeric difference
hap_gender %>%
  mutate(
    avg_word_count = mean(word_count_per_person),
    diff_in_percent = (word_count_per_person - avg_word_count) / word_count_per_person
  ) %>%
  kable(col.names = c("Gender", "Number of People", "Word Count", "Word Count per Person",
                      "Average Word Count", "Difference in Percents"), format = "markdown")
```

<table>
<colgroup>
<col style="width: 7%" />
<col style="width: 17%" />
<col style="width: 11%" />
<col style="width: 22%" />
<col style="width: 19%" />
<col style="width: 23%" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: left;">Gender</th>
<th style="text-align: right;">Number of People</th>
<th style="text-align: right;">Word Count</th>
<th style="text-align: right;">Word Count per Person</th>
<th style="text-align: right;">Average Word Count</th>
<th style="text-align: right;">Difference in Percents</th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td style="text-align: left;">Female</td>
<td style="text-align: right;">42249</td>
<td style="text-align: right;">787912</td>
<td style="text-align: right;">18.64925</td>
<td style="text-align: right;">18.1457</td>
<td style="text-align: right;">0.0270008</td>
</tr>
<tr class="even">
<td style="text-align: left;">Male</td>
<td style="text-align: right;">57918</td>
<td style="text-align: right;">1009665</td>
<td style="text-align: right;">17.43266</td>
<td style="text-align: right;">18.1457</td>
<td style="text-align: right;">-0.0409024</td>
</tr>
<tr class="odd">
<td style="text-align: left;">Others</td>
<td style="text-align: right;">720</td>
<td style="text-align: right;">10243</td>
<td style="text-align: right;">14.22639</td>
<td style="text-align: right;">18.1457</td>
<td style="text-align: right;">-0.2754960</td>
</tr>
<tr class="even">
<td style="text-align: left;">NA</td>
<td style="text-align: right;">51</td>
<td style="text-align: right;">1136</td>
<td style="text-align: right;">22.27451</td>
<td style="text-align: right;">18.1457</td>
<td style="text-align: right;">0.1853602</td>
</tr>
</tbody>
</table>

``` r


# r by_gender_marriage_parenthood

## Creating a dataframe that calculates the number of words used to describe happy moments by gender and martial status
hap_gender_marriage <- happiness_joined %>%
  group_by(gender, marital) %>%
  summarize(
    num_people = n(), 
    word_count_total = sum(word_count, na.rm = TRUE),
    word_count_per_person = word_count_total / num_people
  )

vis_marriage <- hap_gender_marriage %>%
  ggplot(aes(x = gender, y = word_count_per_person, fill = marital)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = num_people), position = position_dodge(width = 0.9), size = 2.5, vjust = 2) +
  labs(
    title = "The Number of Words Used to Describe Happy Moments by Gender and Martial Status per Person",
    subtitle = "(from the survey of Amazon Mechanical Turk workers from 2017-03-28 to 2017-06-26)",
    x = "Gender", 
    y = "", 
    fill = "Martial Status"
  )


## Creating a dataframe that calculates the number of words used to describe happy moments by gender and parenthood
hap_gender_parent <- happiness_joined %>%
  group_by(gender, parenthood) %>%
  summarize(
    num_people = n(), 
    word_count_total = sum(word_count, na.rm = TRUE),
    word_count_per_person = word_count_total / num_people
  )

vis_parent <- hap_gender_parent %>%
  ggplot(aes(x = gender, y = word_count_per_person, fill = parenthood)) +
  geom_col(position = "dodge") + 
  geom_text(aes(label = num_people), position = position_dodge(width = 0.9), vjust = 2) +
  labs(
    x = "Gender",
    y = "", 
    fill = "Parenthood",
    title = "The Number of Words Used to Describe Happy Moments by Gender and Parenthood per Person",
    subtitle = "(from the survey of Amazon Mechanical Turk workers from 2017-03-28 to 2017-06-26)",
    fill = "Martial Status"
  )

## Using plot_grid from cowplot package to compare the two graphs. This show cases the fine difference between marriage and parenthood. 
cowplot::plot_grid(vis_marriage, vis_parent, nrow = 2)
```

![](https://i.imgur.com/sTGsqYb.png)

``` r


# r gender_age_group

## Creating a dataframe that calculate the number of words used by gender and age group
hap_gender_age <- happiness_joined %>%
  mutate(word_count = str_count(hm)) %>%
  group_by(gender, age_group) %>%
  summarize(
    num_people = n(), 
    word_count_total = sum(word_count, na.rm = TRUE),
    word_count_per_person = word_count_total / num_people
  )

## Visualization
hap_gender_age %>%
  ggplot(aes(x = age_group, y = word_count_per_person, color = gender)) +
  geom_point() +
  geom_line(aes(group = gender)) +
  labs(
    title = "The Number of Words Used to Describe Happy Moments by Gender and Age",
    subtitle = "(from the survey of Amazon Mechanical Turk workers from 2017-03-28 to 2017-06-26)",
    x = "Age Group", 
    y = "Number of Words",
    color = "Gender",
    caption = "Source: HappyDB"
  )
```

![](https://i.imgur.com/zvcj7zR.png)

``` r


# r by_gender_intersections

# Creating a function that creates visuals for age-specific groups at every 10 age. For instance, using a 

cohort_find <- function(anyage) {
  
  # Defensive programming that prevents creating outputs for inappropriate ages
  if (anyage > 100) {
    warning("Age too big. The maximum age is in two-digits and has been forced to 99. Try age less than 100!")
    anyage <- 99
  } else if (!is.numeric(anyage)) {
    warning("Age has to be numeric. Please provide the age in numeric from")
  }
  
  if (length(c(anyage)) > 1) {
    warning("You can put only one age at a time. Try using for loop and map function if needed.")
  }
  
  # Skipping require(package) because the libraries are pre-loaded in the Data Preparation section
  
  ## Creating a data frame that holds age_block information
  happiness_age_block <- happiness_joined %>%
    mutate(age_block = cut(age, breaks = seq(0, 100, by = 10)),
           age_block = (as.numeric(age_group) * 10)) # Cut function creates a factor variable and it needs to be multplied by 10 to change it to numeric forms.
  
  happiness_aged <- happiness_age_block %>%
    filter(anyage >= age_block - 10 & anyage < age_block) %>% # filtering to the specific age block of interests. 
    group_by(gender, age_group, marital, parenthood) %>% 
    summarize(
      num_people = n(), 
      word_count_total = sum(word_count, na.rm = TRUE),
      word_count_per_person = word_count_total / num_people
    )
  
  age_group <- unique(happiness_aged$age_group) # Creating the variable for glue function used in the graph title
  
  happiness_aged %>%
    ggplot(aes(x = gender, y = word_count_per_person, fill = marital)) +
    geom_col(position = position_dodge(preserve = "single")) +
    labs(
      title = "The Number of Words Used to Describe Happy Moments by Gender per Person",
      subtitle = glue("in the Age Group of: {age_group}"), # using glue function to change the title depending on the variable
      x = "",
      y = "Number of Words",
      caption = "Source: HappyDB",
      fill = "Martial Status"
    ) +
    theme(legend.position = "bottom") +
    facet_wrap(~parenthood)
}

## Using map function to visualize the trend
map(seq(5, 105, by = 10), cohort_find)
#> Warning in .f(.x[[i]], ...): Age too big. The maximum age is in two-digits and
#> has been forced to 99. Try age less than 100!
#> [[1]]
```

![](https://i.imgur.com/OtZJTLY.png)

    #> 
    #> [[2]]

![](https://i.imgur.com/rJJLYnu.png)

    #> 
    #> [[3]]

![](https://i.imgur.com/RmywAYL.png)

    #> 
    #> [[4]]

![](https://i.imgur.com/ROnh0Pw.png)

    #> 
    #> [[5]]

![](https://i.imgur.com/wcJseDx.png)

    #> 
    #> [[6]]

![](https://i.imgur.com/veMOKc5.png)

    #> 
    #> [[7]]

![](https://i.imgur.com/wkGqJMM.png)

    #> 
    #> [[8]]

![](https://i.imgur.com/eHnQXvK.png)

    #> 
    #> [[9]]

![](https://i.imgur.com/8Uk9eZk.png)

    #> 
    #> [[10]]

![](https://i.imgur.com/uKRFrDf.png)

    #> 
    #> [[11]]

![](https://i.imgur.com/PTIJiWe.png)

``` r

## Using reprex function
reprex(input = "create_reprex.R", outfile = NA)
```

<sup>Created on 2020-05-18 by the [reprex package](https://reprex.tidyverse.org) (v0.3.0)</sup>

