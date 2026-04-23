## How to use TurboTypoTidier

**File Formats Accepted:**  
Currently accepted upload formats are `.xlsx`, `.xls`, `.csv`, and `.txt` (CSV files should be comma-delimited, and TXT files should be tab-delimited).

#### Step-by-Step Guide:

1. Determine which columns contain the correct spellings of your stimuli by typing the prefix shared by the columns of the correct words in **Stimulus Columns' First Name** (`Word` if the columns are `Word.1`, `Word.2`, `Word.3`, ...).

2. Determine which columns contain the responses (stimuli to be corrected) by typing the prefix shared by the columns of the uncorrected words in **Response Columns' First Name** (`Response` if the columns are `Response.1`, `Response.2`, `Response.3`, ...).

3. Select your autocorrect distance method. We offer various functions to measure how far two strings are from being a perfect match. For more information, consult the `method` argument for the [stringdist](https://cran.r-project.org/web/packages/stringdist/refman/stringdist.html#topic+stringdist-metrics) R package. Levenshtein distance (`lv`) is set as our default.

4. Select your autocorrect character distance tolerance. This determines the number of single-character edits (insertions, deletions, substitutions) required to change one word into another (e.g., when using method `lv` to correct “chain” → “chant”, tolerance must be 2). Importantly, if a response is equally distant from two correct words for that trial, it will not be corrected (e.g., “dat”, when both “cat” and “bat” are valid targets).

5. Select if you wish to keep all responses that exceed your specified autocorrect threshold.

6. Select whether you wish to change the case of your stimuli and responses when calculating distances (uppercase, lowercase, or none).

7. Select whether you want to remove leading/trailing whitespace in response columns.

8. Choose whether you want to process stopwords in response data (e.g., “notsure”, “blank”, “IDK”).

    - **Replace:** Replaces stopwords with a single designated stopword (see Step 9).
    
    - **Remove:** Replaces stopwords with `NA`.
    
    - **None:** Leaves stopwords as-is.




9. Set the **designated stopword replacement**. Default is "skip".

10. Choose whether you want to use the [default list of stopwords](https://docs.google.com/spreadsheets/d/1DDWzDuxHquFkZ5LBbYoIGD9QR_Lpk3fQ/edit?usp=sharing&ouid=108455544057155435811&rtpof=true&sd=true) or upload your own custom list. Accepted formats are `.xlsx`, `.xls`, `.csv`, and `.txt`. The file must have a **single column**, one stopword per row.

11. Typo Data Details: Select if you wish to keep all typo distance data in the downloadable output file. The information on the types of typos can be found below:

    - **Corrected:** Transformed response data corrected according to the chosen autocorrect character distance tolerance.
    
    - **Pos.Dist:** Distance between the strings in each position of your stimuli and responses columns (between `Word.1` and `Response.1`, between `Word.2` and `Response.2`, etc.)
   
    - **Trial.Dist:** Distance between the the strings for each response and any match in the stimuli columns which does not exceed the autocorrect threshold. (e.g., with a threshold of 2, if `Response.3` is "cloob" and Word.1 is "club", `Trial.Dist.3` will have a value of 2). Importantly, if a response is equally distant from two correct words for that trial, Trial.Dist will not be computed for that position.
    
    - **Multiple.Match:** True or false value indicating whether a response in the corresponding column is within the autocorrect distance threshold of more than word in the list of stimuli.

   


