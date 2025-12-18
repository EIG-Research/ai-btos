# How Many Businesses Are Using AI? 

This repository creates the figures for the substack post ["How Many Businesses Are Using AI?"](https://agglomerations.substack.com/p/how-many-businesses-are-using-ai) by Nathan Goldschlag, posted December 19, 2025. 

## Programs 

There are two stata programs and a configuration file. 

- 0_config.do - contains global parameters and macros.
- 1_clean_btos.do - preprocesses the raw btos xlsx files in ./data/raw/ and creates "long" datasets organized by [by variables (e.g., state), question id, year, biweek] with answers for each question as columns.
- 2_btos_ai.do - computes the data for figures 1, 2, and 3, which are stored in ./results/ 

## Data

- ./raw/ - contains two vintages of data, one downloaded on ./20251208/ and one downloaded on ./20251215/. The former had the historical AI question data stored as separate rows and the later removed the historical AI data altogether. This causes some issues in the cleaning code (1_clean_btos.do) where we need to splice the vintages together. 
- ./clean/ - contains the processed, long data.
- ./crosswalks/ - contains MSA and NAICS information that can be matched into the BTOS data.

