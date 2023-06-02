
Generated/Updated on [2023-06-01] by [KTW]

-------------------
# GENERAL INFORMATION
-------------------

#### [analytic_plan]: [set up instructions, long-form documentation, misc ext files needed for analysis]
- [file1 or set of related files]: [Purpose, contents, naming convention, etc.]
- [file2 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [data-raw] 
Raw Data --> To be Processed in Scripts
- [file1] : [Purpose, contents, naming convention, etc, origination information ]
- [file2 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [scripts] 
Functions, Data Transformations Required by Project Brief, etc. 
- [file1 or set of related files]: [Purpose, contents, naming convention, etc.]
- [file2 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [data]
Intermediate data objects such as transformed datasets, tables
- [file1 or set of related files]: [Purpose, contents, naming convention, etc.]
- [file2 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [eda]
EDA from data output or data-raw
- [file1 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [reports]
Final reports, shareable analysis. 
- [file1 or set of related files]: [Purpose, contents, naming convention, etc.]

#### [make]
Add the names of folders where Make should look for files. Typically: 
VPATH = data data-raw eda reports scripts  

-------------------
CONTEXTUAL INFORMATION
-------------------

1. Abstract for the dataset 
[The abstract should describe the dataset, not the research or the results obtained after analyzing the dataset. The dataset abstract should be different than an article or book abstract, even if the dataset is tightly related to the article or book.]

2. Context of the research project that this dataset was collected for.
[Any contextual information that will help to interpret the dataset. You can give details about the research questions that prompted the collection of this dataset. ]

3. Date of data collection:
[single date or range or approximate date in format YYYY-MM-DD]

--------------------------
VERSIONING AND PROVENANCE
-------------------------- 

1. Last modification date
[Date dataset was last modified in format YYYY-MM-DD]


2. Links/relationships to other versions of this dataset:
[If there are previous versions explain where the other version is, when it was updated, and summarize the changes.]
[If a very granular description of the versions of the dataset is needed (e.g. file by file) this section can be moved to Data and File overview.]


3. Was data derived from another source?
[Answer Yes or No. If Yes, list source(s).]
[If there is code in the dataset, and the code is in a repository explain how this snapshot of the code is tagged in the repository]


4. Additional related data collected that was not included in the current data package:


--------------------------
METHODOLOGICAL INFORMATION
--------------------------
[Describe the methodology used to generate the dataset]
[Include links or references to publications or other documentation containing methodological information]

1. Description of methods used for collection/generation of data: 
[experimental design or protocols used in data collection]

2. Methods for processing the data: 
[describe how the submitted data were generated from the raw or collected data]

3. Instrument- or software-specific information needed to interpret the data:
[If software is needed to interpret the data, explain where to get the software. If software is not openly available include it in the dataset (if possible). If including the software is not possible consider changing the format of the dataset. Include version of software. ]

4. Standards and calibration information, if appropriate:

5. Environmental/experimental conditions:
[e.g., cloud cover, atmospheric influences, computational environment, etc.]

6. Describe any quality-assurance procedures performed on the data:


7. People involved with sample collection, processing, analysis and/or submission:
[If they are not include as collaborators, or if you want to describe more carefully who did what.]


---------------------
DATA & FILE OVERVIEW
---------------------
[All files in the dataset should be listed here. If a file naming schema is used, it is fine to explain it instead of listing all the files. Include directory structure if necessary.]
[Filenames should include extension.]



1. File List
   A. Filename:        
      Short description:        


        
   B. Filename:        
      Short description:        


        
   C. Filename:        
      Short description:


2. Relationship between files:


3. Formats
[List all the formats present in this dataset. Include explanations or instructions if necessary (e.g. links to page describing a metadata standard)]        



-----------------------------------------
TABULAR DATA-SPECIFIC INFORMATION FOR: [FILENAME]
-----------------------------------------
[This section should be created for each file or dataset that requires explanation of variables. Typically, this is always needed for tabular data with columns and column headers. All variables should be described. Include the units.]


1. Number of variables:


2. Number of cases/rows: 



3. Missing data codes:
        Code/symbol        Definition
        Code/symbol        Definition


4. Variable List
[Include all information that is important: Value labels if appropriate. Units if appropriate. Min and Max values if appropriate. ]

    Example. 
      Name: Species 
      Description: Species of the Drosophila sampled
            DML = Drosophila melanogaster
            DMJ = Drosophila mojavensis
            O = Other                

    A. Name: [variable name]
       Description: [description of the variable]
                    


    B. Name: [variable name]
       Description: [description of the variable]
                    [Value labels if appropriate. Units if appropriate.]

-----------------------------------------
CODE-SPECIFIC INFORMATION: 
-----------------------------------------

1. Installation 
[Instructions to install the software, if necessary]

2. Requirements
[Describe all programs and libraries that your code relies on. What should a user install to make sure that the code can be run successfully?]

3. Usage
[Describe how to use the code. Include examples]

4. Support
[Will the authors support others that want to use these scripts?]

5. Contributing
[Can other researchers contribute to the code? Is the code in a public repository? Are pull requests welcome? In this case the code submitted in the repository will be a snapshot, which can be useful for preservation.]


-----------------------------------------
OTHER: 
-----------------------------------------
[Include any other important information about the data that you did not have opportunity to discuss anywhere in this template]
