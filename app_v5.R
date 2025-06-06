# ──────────────────────────────────────────────────────────────────────────────
# app.R
# When no categories are selected, show only faint gray lines for all intersections.
# Otherwise, overlay selected colored lines. Panels beneath with All/None links.
# ──────────────────────────────────────────────────────────────────────────────

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(haven)    # <-- Need haven for zap_labels()

# Load pred2.rds and immediately strip any haven_labelled metadata from Age/pred:
pred2 <- readRDS("pred2.rds") %>%
  mutate(
    # If Age (or pred) is haven_labelled, zap_labels() removes labelled attributes 
    # so that as.numeric() will work correctly.
    Age  = as.numeric( zap_labels(Age)  ),
    pred = as.numeric( zap_labels(pred) )
  )

# Pre‐compute the global Age range so we fix the x‐axis correctly
min_age <- min(pred2$Age, na.rm = TRUE)
max_age <- max(pred2$Age, na.rm = TRUE)

# 1) Hard‐code the desired order for each set of choices:
gen_levels   <- c("Z", "Y", "X", "boomer", "silent")
ethn_levels  <- c(
  "White British", "African", "Bangladeshi", "Caribbean",
  "Indian", "Mixed", "Other", "Other White", "Pakistani", "White Irish"
)
sex_levels   <- sort(unique(as.character(pred2$sex)))
nssec_levels <- c(
  "Management & professional", "Intermediate", "Routine", "Not in labour market"
)

# Ensure pred2$final_nssec is a factor with the correct levels
pred2 <- pred2 %>%
  mutate(final_nssec = factor(final_nssec, levels = nssec_levels))

ui <- fluidPage(
  titlePanel("SF-12 PCS Score by Intersectional Strata"),
  
  # 1) Plot row: full width
  fluidRow(
    column(
      width = 12,
      plotlyOutput("interactivePlot", height = "500px")
    )
  ),
  
  # 2) Inputs row: full width, inputs stacked in columns with All/None links
  fluidRow(
    column(
      width = 12,
      wellPanel(
        style = "padding: 15px; margin-bottom: 20px;",
        fluidRow(
          # Generation panel
          column(
            width = 3,
            tags$div(
              tags$b("Generation"),
              actionLink("toggleGen", "(All/None)")
            ),
            checkboxGroupInput(
              inputId  = "genSelect",
              label    = NULL,
              choices  = gen_levels,
              selected = gen_levels
            )
          ),
          # Ethnicity panel
          column(
            width = 3,
            tags$div(
              tags$b("Ethnicity"),
              actionLink("toggleEthn", "(All/None)")
            ),
            checkboxGroupInput(
              inputId  = "ethnSelect",
              label    = NULL,
              choices  = ethn_levels,
              selected = ethn_levels[1]
            )
          ),
          # Sex panel
          column(
            width = 3,
            tags$div(
              tags$b("Sex"),
              actionLink("toggleSex", "(All/None)")
            ),
            checkboxGroupInput(
              inputId  = "sexSelect",
              label    = NULL,
              choices  = sex_levels,
              selected = sex_levels[1]
            )
          ),
          # NS-SEC panel
          column(
            width = 3,
            tags$div(
              tags$b("NS-SEC"),
              actionLink("toggleNssec", "(All/None)")
            ),
            checkboxGroupInput(
              inputId  = "nssecSelect",
              label    = NULL,
              choices  = nssec_levels,
              selected = nssec_levels[1]
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Toggle observers for each group
  observeEvent(input$toggleGen, {
    current <- input$genSelect
    if (length(current) < length(gen_levels)) {
      updateCheckboxGroupInput(session, "genSelect", selected = gen_levels)
    } else {
      updateCheckboxGroupInput(session, "genSelect", selected = character(0))
    }
  })
  observeEvent(input$toggleEthn, {
    current <- input$ethnSelect
    if (length(current) < length(ethn_levels)) {
      updateCheckboxGroupInput(session, "ethnSelect", selected = ethn_levels)
    } else {
      updateCheckboxGroupInput(session, "ethnSelect", selected = character(0))
    }
  })
  observeEvent(input$toggleSex, {
    current <- input$sexSelect
    if (length(current) < length(sex_levels)) {
      updateCheckboxGroupInput(session, "sexSelect", selected = sex_levels)
    } else {
      updateCheckboxGroupInput(session, "sexSelect", selected = character(0))
    }
  })
  observeEvent(input$toggleNssec, {
    current <- input$nssecSelect
    if (length(current) < length(nssec_levels)) {
      updateCheckboxGroupInput(session, "nssecSelect", selected = nssec_levels)
    } else {
      updateCheckboxGroupInput(session, "nssecSelect", selected = character(0))
    }
  })
  
  # Reactive filtered data based on current selections
  filteredData <- reactive({
    df <- pred2
    if (!is.null(input$genSelect) && length(input$genSelect) > 0) {
      df <- df %>% filter(generation %in% input$genSelect)
    } else {
      return(df[0, ])
    }
    if (!is.null(input$ethnSelect) && length(input$ethnSelect) > 0) {
      df <- df %>% filter(ethn_short_v2 %in% input$ethnSelect)
    } else {
      return(df[0, ])
    }
    if (!is.null(input$sexSelect) && length(input$sexSelect) > 0) {
      df <- df %>% filter(sex %in% input$sexSelect)
    } else {
      return(df[0, ])
    }
    if (!is.null(input$nssecSelect) && length(input$nssecSelect) > 0) {
      df <- df %>% filter(final_nssec %in% input$nssecSelect)
    } else {
      return(df[0, ])
    }
    df
  })
  
  output$interactivePlot <- renderPlotly({
    df_sel <- filteredData()
    
    # 1) Base: faint gray lines for ALL strata
    p_base <- ggplot() +
      geom_line(
        data = pred2,
        aes(x = Age, y = pred, group = Strata),
        color = "gray90",
        linewidth = 0.5,
        alpha = 0.4
      )
    
    # 2) If any panel is empty (nrow(df_sel) == 0), just show base plot
    if (nrow(df_sel) == 0) {
      p <- p_base +
        theme_minimal(base_size = 14) +
        ylab("Predicted SF-12 PCS Score") +
        xlab("Age") +
        scale_x_continuous(
          breaks = seq(floor(min_age / 5) * 5,
                       ceiling(max_age / 5) * 5,
                       by = 5),
          limits = c(min_age, max_age)
        ) +
        ylim(10, 60) +
        theme(
          plot.title       = element_text(face = "bold", size = 18),
          axis.title       = element_text(size = 16),
          axis.text        = element_text(size = 14),
          legend.position  = "none",
          panel.grid.major = element_line(color = "gray90"),
          panel.grid.minor = element_blank()
        )
      return(ggplotly(p))
    }
    
    # 3) Otherwise, overlay: selected strata in color
    p_sel <- geom_line(
      data = df_sel,
      aes(
        x     = Age,
        y     = pred,
        group = Strata,
        color = strata_v5,
        text  = paste0(
          "Generation: ", generation, "<br>",
          "Intersection: ", strata_v5, "<br>",
          "Age: ", Age
        )
      ),
      linewidth = 0.7,
      alpha = 0.9
    )
    
    # 4) Build the full ggplot
    p <- p_base +
      p_sel +
      theme_minimal(base_size = 14) +
      ylab("Predicted SF-12 PCS Score") +
      xlab("Age") +
      scale_x_continuous(
        breaks = seq(floor(min_age / 5) * 5,
                     ceiling(max_age / 5) * 5,
                     by = 5),
        limits = c(min_age, max_age)
      ) +
      ylim(10, 60) +
      theme(
        plot.title       = element_text(face = "bold", size = 18),
        axis.title       = element_text(size = 16),
        axis.text        = element_text(size = 14),
        legend.position  = "none",
        panel.grid.major = element_line(color = "gray90"),
        panel.grid.minor = element_blank()
      )
    
    ggplotly(p, tooltip = "text") %>%
      layout(margin = list(t = 50, b = 50, l = 60, r = 20))
  })
}

shinyApp(ui, server)
