library(shiny)
library(shinyjs)
library(bslib)
library(shinycssloaders)
library(readxl)
library(writexl)
library(rmarkdown)
library(markdown)





# First tab : App
navbarPage(
  title = "TurboTypoTidier", # Title for the navbar
  theme = bs_theme(
    bootswatch = "cerulean",
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    "font-size-base" = "0.95rem",
    "border-radius" = "1rem",
    "btn-border-radius" = "0.75rem",
    "card-border-radius" = "1.25rem",
    "input-border-radius" = "0.75rem",
    "spacer" = "1rem"
  ),
  
  tags$head(
    tags$style(HTML("
    /* Top controls */
    .dt-top {
      display: flex;
      justify-content: space-between;
      margin-bottom: 1rem;
    }

    /* Search alignment */
    .dt-search-top {
      justify-content: flex-end;
      padding-bottom: .5rem;
    }

    /* Reduce scroll/body gap */
    .dataTables_scrollBody {
      margin-bottom: .5rem;
    }

    /* Bottom controls */
    .dt-bottom {
      padding-top: .5rem;
      margin-top: .25rem;
      border-top: 1px solid rgba(0,0,0,.08);
      gap: .75rem;
      flex-wrap: wrap;
    }

    /* Length, info, filter */
    .dataTables_length label,
    .dataTables_filter label,
    .dataTables_info {
      margin: 0;
      font-size: .95rem;
      opacity: .9;
    }

    /* Pagination */
    .dataTables_paginate,
    .dataTables_paginate .pagination {
      margin: 0;
      gap: .25rem;
    }

    .dataTables_paginate .page-link {
      padding: .35rem .6rem;
      border-radius: .5rem;
    }

    /* Compact, single-line rows */
    table.dataTable th,
    table.dataTable td {
      white-space: nowrap;
      padding: .35rem 0.75rem;
      line-height: 1.2;
    }
    
    /* App background */
    body {
      background-color: #F2F6FB;  /* soft blue-gray */
    }

    /* Keep cards readable */
    .card {
      background-color: #ffffff;
    }

    /* Sidebar background (optional) */
    .bslib-sidebar {
      background-color: #ffffff;
    }
    
    /* Round sidebar corners */
    .bslib-sidebar {
      border-radius: 1rem;
      overflow: hidden; /* ensures contents respect rounding */
    }
  "))
  ),
  
  
  
  
  tabPanel(
    "App",
    useShinyjs(),
    
    bslib::page_sidebar(
      title = tags$h3("Typo Checker for Verbal Data"),
      sidebar = bslib::sidebar(
        width = 360,
        
        bslib::accordion(
          open = c("Data", "Autocorrect", "Stopwords", "Typo Distance Data"),
          
          bslib::accordion_panel(
            "Data",
            fileInput("originalfile", "Select a data file",
                      accept = c(".csv", ".txt", ".xlsx", ".xls")
                      ),
            textInput("stimulus_name", "Stimulus column prefix", "Word"),
            div(
              style = "margin-bottom: 25px;",
              helpText("Example: 'Word' matches Word.1, Word.2, ...")
            ),
            textInput("response_name", "Response column prefix", "Response"),
            div(
              style = "margin-bottom: 25px;",
              helpText("Example: 'Response' matches Response.1, Response.2, ...")
            )
          ),
          
          
          bslib::accordion_panel(
            "Autocorrect",
            selectInput(
              "distance_method",
              "Distance method",
              c("lv", "osa", "dl", "hamming", "lcs", "qgram", "cosine", "jaccard", "jw", "soundex")
            ),
            div(
              style = "margin-bottom: 25px;",
              helpText(HTML(
                "For details on each method, consult the <code>method</code> argument for the <a href='https://cran.r-project.org/web/packages/stringdist/refman/stringdist.html#topic+stringdist-metrics' target='_blank'>stringdist</a> R package."
              )
              )
            ),
            selectInput(
              "autocorrect_tolerance",
              "Max character distance",
              choices = c("No correction" = 0, 1:25),
              selected = 1
            ),
            
            div(
              style = "margin-bottom: 25px;",
              helpText("If a response is equally close to two targets, it won't be corrected.")
            ),
            
            # New section to give option to keep in extralist intrusions or responses above criterion
            div(
              class = "aligned-control",
              tags$p(class = "aligned-label", "Keep responses that exceed threshold"),
              checkboxInput("keep_uncorrected", label = NULL, value = TRUE)
            ),
            
          ),
          
          bslib::accordion_panel(
            "Cleaning",
            selectInput("case_conversion", "Case conversion", c("all_to_lower", "all_to_upper", "none")),
            selectInput("whitespace_removal", "Whitespace", c("remove_start_and_end", "none"))
          ),
          
          bslib::accordion_panel(
            "Stopwords",
            selectInput("stopword_replacement", "Stopword handling", c("replace", "remove", "none")),
            textInput("designated_stopword", "Designated stopword", "skip"),
            # Dropdown menu containing default files and the upload trigger
            selectInput("dataSource", "Choose Stopword List:",
                        choices = c("Use Default Stopword List" = "default", 
                                    "Upload Custom Stopword List" = "upload")),
            div(
              style = "margin-bottom: 25px;",
              helpText(HTML("View the <a href='https://docs.google.com/spreadsheets/d/1DDWzDuxHquFkZ5LBbYoIGD9QR_Lpk3fQ/edit?usp=sharing&ouid=108455544057155435811&rtpof=true&sd=true' target='_blank'> default stopword list</a>."
              )
            )
            ),
            # This panel only appears if "Upload Custom File..." is selected
            conditionalPanel(
              condition = "input.dataSource == 'upload'",
              fileInput("stopwordfile", "Upload a custom stopword file",
                        accept = c(".csv", ".txt", ".xlsx", ".xls")),
              helpText("Custom stopword file should be a single column: one stopword per row.")
            )
          ),
          bslib::accordion_panel(
            "Typo Distance Data",
            # New section to give option to keep typo distance data in output file
            div(
              class = "aligned-control",
              tags$p(class = "aligned-label", "Keep Typo Distance Data in Output File"),
              checkboxInput("keep_typocorrectiondata", label = NULL, value = TRUE)
            ),
            div(
              style = "margin-bottom: 25px;",
              helpText("e.g., 'Post.Dist', Trial.Dist', 'Mutiple.Match'.")
            )
          )
          ),
          
        
        div(style = "margin-top: 12px;"),
        actionButton("execute_typo_error_check", "Execute Typo Checker", class = "btn-primary"),
        selectInput(
          "download_format",
          "Download format",
          choices = c("Excel (.xlsx)" = "xlsx",
                      "CSV (.csv)"   = "csv",
                      "Text (.txt)"  = "txt"),
          selected = "xlsx"
        ),
        downloadButton("download_data", "Download results")
      ),
      
      # Main content
      bslib::layout_column_wrap(
        width = 1,
        
        bslib::navset_card_tab(
          
          id = "data_viewer",
          
          bslib::nav_panel(
            "Raw Data",
            shinycssloaders::withSpinner(
              DT::DTOutput("head"),
              type = 4,
              color = "#2C7BE5"
            )
          ),
          
          bslib::nav_panel(
            "Corrected Data",
            shinycssloaders::withSpinner(
              DT::DTOutput("checked"),
              type = 4,
              color = "#2C7BE5"
              )
          )
        )
      )
    )
  ), 


# Second Tab : About
tabPanel(
  "Instructions",
  fluidPage(
    includeMarkdown("Instructions.md")
  )
),


# Third Tab : About
tabPanel(
  "About", 
  fluidPage(
    h2("About TurboTypoTidier"),
    HTML(
      "
      <p>
      TurboTypoTidier is an free and open-source toolkit designed to automate and standardize the correction 
      and analysis of data containing verbal stimuli. It aims to be a one-stop shop for those looking for an efficient 
      and reliable way to correct their data, especially those working with large stimuli sets in experimental psychology. 
      TurboTypoTidier's parameters are adjustable, allowing it to be configured to correct spelling mistakes 
      according to your own level of tolerance.
      </p>
      "
    ),
    
      
    div(
      style = "display: flex;
      flex-direction: column;
      align-items: center;
      text-align: left;
      gap: 1rem;
      justify-content: flex-end;
      margin-top: auto;
      min-height: 500px;",
      
      tags$p(
        tags$strong(
          "The creation of TurboTypoTidier was made possible thanks to funding from the Natural Sciences and Engineering Research Council of Canada (NSERC) and the Japan Society for the Promotion of Science (JSPS)."
        )
      ),
      
      div(
        style = "display: flex; justify-content: center; align-items: center; gap: 2rem;",
        tags$a(
          href= "https://nserc-crsng.canada.ca/en",
          target = "_blank",
          tags$img(src = "NSERC_BLACK.svg", 
                   alt= "NSERC Logo",
                   style = "width: 150px;")
          ),
        tags$a(
          href= "https://www.jsps.go.jp/english/index.html",
          target = "_blank",
          tags$img(src = "jsps_logo.png", 
                   alt= "JSPS Logo",
                   style = "height: 80px;")
        )
      )
    )
  )
),



# Fourth Tab : Contact
tabPanel(
  "Contact",
  fluidPage(
    h2("Contact Info"),
    HTML(
      "<p>
        <strong>For support or inquiries, please reach out to us by email.</strong>
      </p>
      <br>
      <div style='margin-left: 20px;'>
        <p>
        <a href='https://www.iandauphinee.com/' target='_blank'><strong><span style='color: #1E90FF;'>Ian Dauphinee, M.A.:</span></strong></a>
        </p>
        <img src='Ian_Pic.jpeg' alt='Ian Dauphinee' style='width: 100px; height: 100px;'><br>
        <p>
        <br>
        <img src='Mailbox_Pic.png' alt='Mailbox Pic' style='width: 30px; height: auto; margin-right: 10px;'>ian.dauphinee@dal.ca
        <p>
          <img src='Researchgate_Pic.png' alt='Researchgate Pic' style='width: 30px; height: auto; margin-right: 10px;'>
          <a href='https://www.researchgate.net/profile/Ian-Dauphinee' target='_blank'>ResearchGate Profile</a>
        </p>
        <p>
          <img src='LinkedIn_Pic.png' alt='LinkedIn Pic' style='width: 30px; height: auto; margin-right: 10px;'>
          <a href='https://www.linkedin.com/in/ian-dauphinee-4b0987253/' target='_blank'>LinkedIn Profile</a>
        </p>
        <br>
        <p><strong><span style='color: #1E90FF;'>Sho Ishiguro, PhD:</span></strong></p>
        <img src='Sho_Pic.jpeg' alt='Sho Ishiguro' style='width: 100px; height: 100px;'><br>
        <p>
        <br>
        <img src='Mailbox_Pic.png' alt='Mailbox Pic' style='width: 30px; height: auto; margin-right: 10px;'>sho.ishiguro@umoncton.ca
        <p>
          <img src='Researchgate_Pic.png' alt='Researchgate Pic' style='width: 30px; height: auto; margin-right: 10px;'>
          <a href='https://www.researchgate.net/scientific-contributions/Sho-Ishiguro-2145459372' target='_blank'>ResearchGate Profile</a>
        </p>
        <p>
          <img src='LinkedIn_Pic.png' alt='LinkedIn Pic' style='width: 30px; height: auto; margin-right: 10px;'>
          <a href='https://www.linkedin.com/in/sho-ishiguro-a29b06311/' target='_blank'>LinkedIn Profile</a>
        </p>
        <br>
      </div>"
    )
  )
)

)

