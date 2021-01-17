# Computing for Social Scineces - HW 06
* Author: Boseong Yun

# Overview
I have analyzed the number of words used to describe happy moments from the survey of Amazon Mechnical Turk (MTurk) workers between 2017-03-28 to 2017-06-16. Specifically, I investigated the relationship between gender and the number of words used to describe happy moments at the intersection of age, maritial status, and parenthood experiences. Despite the seeming randomness in how one is ought to experience happiness, I intended to find gendered patterns in them. 

# Packages & Data Requried 
Here are the folling pacakages required: 
* library(tidyverse) 
* library(reprex)
* library(knitr) 
* library(here)
* library(cowplot)
* library(glue)

Detailed descriptions about the data can be found [here](https://github.com/megagonlabs/HappyDB). 

# Data
I have not displayed any code in the report to increase readability of the report. However, you won't have any problem reproducing the same result using the the [rmarkdown](https://github.com/boseongyun/hw06/blob/master/happiness_report.Rmd) file. Additionally, all the codes that I have used have been included by the name of the code chunk in the [create_reprex.r](https://github.com/boseongyun/hw06/blob/master/create_reprex.R) file. You can further check out detaild outputs in the [reprex_outputs](https://github.com/boseongyun/hw06/tree/master/reprex_outputs) folder. 


# Work 

I have created my Rmarkdown file and knitted to the markdown file. The outputs are saved in the happiness_report_files. I have addtionallly created a create_reprex.R where I compiled all the code chunks used in the Rmarkdown file to render the codes using reprex() function. The outputs from the reprex function are saved to the reprex_ouputs folder.

* My Rmarkdown file can be found [happiness_report.Rmd](https://github.com/boseongyun/hw06/blob/master/happiness_report.Rmd)

* The markdown report from RMarkdown can be found at [happiness_report.md](https://github.com/boseongyun/hw06/blob/master/happiness_report.md). 

* The rscript file used to render using reprex can be found at [create_reprex.r](https://github.com/boseongyun/hw06/blob/master/create_reprex.R)

* All the outputs from the reprex function can be found in this [reprex_outputs](https://github.com/boseongyun/hw06/tree/master/reprex_outputs) folder

* The data used in this project can be found in this [data](https://github.com/boseongyun/hw06/tree/master/data) folder.

* The plots used in this project can be found in this [happiness_report_files](https://github.com/boseongyun/hw06/blob/master/happiness_report.Rmd)