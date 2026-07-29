# MicheliR

**An R Toolkit for the Micheli Guide to Fungal Conservation Policy Gap Assessment**

[![R-CMD-check](https://github.com/DATAVERSE01/MicheliR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/DATAVERSE01/MicheliR/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/DATAVERSE01/MicheliR.svg?style=social)](https://github.com/DATAVERSE01/MicheliR/stargazers)

---

## Overview

`MicheliR` is a Shiny‑based R package that automates the keyword‑search and evaluation workflow of the **Micheli Guide to Fungal Conservation (CBD Evaluation Form)**.

It performs deterministic keyword counting (Fungi, Animals, Plants) with full audit logs, and optionally uses the DeepSeek API to:

- Filter out false positives (e.g., "fung" in "fungicide", industrial "plant")
- Answer the 5 key questions of the Micheli Guide with justifications
- Compute a score (0–5) and rating (Adequate → Totally Deficient)

The tool is designed to assist researchers, policy makers, and conservation practitioners in assessing National Biodiversity Strategy and Action Plans (NBSAPs) and CBD National Reports for fungal conservation policy gaps.

---

## Features

- **Language support** – English or French keyword lists (root‑based matching, singular+plural).
- **Flexible document input** – upload `.txt`, `.pdf`, `.docx`, or paste plain text.
- **On‑demand keyword searches** – buttons for Fungi, Animals, Plants, or Run All.
- **Live summary statistics** – total counts and percentages for each kingdom.
- **Detailed audit logs** – each match includes: keyword group, matched text, location (page/line/paragraph), and 80‑character context with **yellow highlighting**.
- **Industrial‑plant exclusion** – automatically excludes "plant" when used in a factory/sewage/industrial context.
- **AI evaluation (DeepSeek)** – filters false positives and applies the full Micheli Guide assessment.
- **Export results** – download a ZIP archive with CSV files for frequency tables and audit logs.
- **No AI hallucination in counting** – keyword search is 100% deterministic and reproducible.

---

## Installation

You can install the development version from GitHub:

```r
# Install remotes if you don't have it
install.packages("remotes")

# Install MicheliR
remotes::install_github("DATAVERSE01/MicheliR")
```

---

## Required Dependencies

All required packages will be installed automatically when you install `MicheliR`. For reference:


| Package | Use |
|---------|-----|
| `shiny` | Interactive web application framework |
| `shinythemes` | Professional theming for the app |
| `stringr` | String manipulation and pattern matching |
| `pdftools` | PDF text extraction |
| `readtext` | DOCX and other text file reading |
| `dplyr`, `tidyr` | Data wrangling and manipulation |
| `DT` | Interactive, searchable data tables |
| `plotly` | Pie chart visualisation |
| `httr`, `jsonlite` | DeepSeek API calls (JSON handling) |
| `magrittr` | Pipe operator `%>%` |


---

## Usage
Launch the Shiny app with a single command:

```r
library(MicheliR)
run_app()
```


---

## Workflow

### 1. Load a Document
- Upload a `.txt`, `.pdf`, or `.docx` file using the **"Choose a file"** button, **or**
- Paste the document content directly into the text area.

### 2. Enter Metadata
- **Document Title** – e.g., *National Biodiversity Strategy and Action Plan*
- **Country** – e.g., *Benin*
- **Document Date** – the publication or submission date
- **Language** – select **English** or **French** (this determines which keyword patterns are used)

### 3. Run Keyword Searches
- Click **🔍 Fungi**, **🔍 Animals**, or **🔍 Plants** to search individually.
- Click **▶ Run All** to search all three kingdoms at once.

After each search, you'll see:
- **Pie chart** – visual breakdown of word frequencies by kingdom.
- **Frequency table** – counts per keyword group (e.g., `fung`, `lichen`, `mushroom`, etc.).
- **Audit log** – each match with:
  - Group (keyword category)
  - Matched word (exact text found)
  - Location (page, line, or paragraph number)
  - **Highlighted context** – the matched word is shown in yellow for easy scanning.

### 4. AI Evaluation (Optional)
- Enter your **DeepSeek API key** in the sidebar (or set the `DEEPSEEK_API_KEY` environment variable).
- Click **🧠 Run AI Evaluation**.
- The AI will:
  1. Filter out false positives from the audit logs.
  2. Answer the 5 key questions of the Micheli Guide with justifications.
  3. Compute a score (0–5) and rating (Adequate → Totally Deficient).
- Results appear in the **"AI Evaluation"** tab, along with **filtered audit logs** (only the relevant, non‑false‑positive matches).

### 5. Save Results
- Click **💾 Save Results** to download a ZIP file containing:
  - `Fungus_freq.csv`, `Animal_freq.csv`, `Plant_freq.csv` – frequency tables
  - `Fungus_audit.csv`, `Animal_audit.csv`, `Plant_audit.csv` – audit logs (raw context)
  - `Summary.csv` – overall counts and percentages
  - `Metadata.csv` – document title, country, date, language, evaluation date

---

## API Key for AI Evaluation

If you want to use the AI evaluation feature, you need a DeepSeek API key:

1. Sign up at [platform.deepseek.com](https://platform.deepseek.com)
2. Generate an API key
3. Enter the key in the app's sidebar when prompted

The AI evaluation is **optional** – you can still perform deterministic keyword searches without an API key.

### Pricing

DeepSeek is **pay‑as‑you‑go**:

| Model | Price per 1M Input Tokens | Price per 1M Output Tokens |
|-------|---------------------------|----------------------------|
| `deepseek-v4-flash` | $0.14 | $0.28 |
| `deepseek-v4-pro` | $0.435 | $0.87 |

New users often receive free credits to test the API.

---

## Example

```r
# Install and load
library(MicheliR)

# Launch the app
run_app()

# The app will open in your browser.
# Upload a document, run searches, and optionally run AI evaluation.
```

---

## License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---

## Authors

- **Apollon D.M.T. HEGBE** – *Creator & Maintainer* – [Laboratory of Tropical Mycology and Plant‑Fungus‑Soil Interaction / International Society for Fungal Conservation]
- **Nourou S. Yorou** – *Contributor* – [Laboratory of Tropical Mycology and Plant‑Fungus‑Soil Interaction]
- **David W. Minter** – *Contributor* – [International Society for Fungal Conservation]

---

## Citation

If you use `MicheliR` in your research, please cite:

```bibtex
@Manual{MicheliR,
  title = {MicheliR: An R Toolkit for the Micheli Guide to Fungal Conservation Policy Gap Assessment},
  author = {Apollon D.M.T. HEGBE and Nourou S. Yorou and David W. Minter},
  year = {2026},
  note = {R package version 1.0.0},
  url = {https://github.com/DATAVERSE01/MicheliR}
}
```

---

## Acknowledgements

This tool was developed to support the evaluation of National Biodiversity Strategy and Action Plans (NBSAPs) and CBD National Reports under the Micheli Guide framework. We thank the International Society for Fungal Conservation for their support.

---

## Feedback and Contributions

Issues, feature requests, and contributions are welcome!

- **Bug reports / feature requests**: Please use the [GitHub issue tracker](https://github.com/DATAVERSE01/MicheliR/issues)
- **Contributions**: Fork the repository, make your changes, and submit a pull request.
- **Questions**: Open an issue or contact the maintainer directly.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

We welcome contributions of all kinds – code, documentation, bug reports, and feature suggestions.

---

## References

1. **The Micheli Guide to Fungal Conservation**. Available at: [http://www.fungal-conservation.org/](http://www.fungal-conservation.org/)

2. Abdel-Azeem, A., & Minter, D. W. (2011). The Rio Convention and Fungi: A review of recent national biodiversity action plans and reports. *Fungal Conservation*, (1), 29–32. Available at: [fungal-conservation.org](http://www.fungal-conservation.org/)

3. Minter, D. W. (2013a). *A Future for Fungi: The Orphans of Rio*. International Society for Fungal Conservation, UK. Available at: [http://www.fungal-conservation.org/blogs/orphans-of-rio.pdf](http://www.fungal-conservation.org/blogs/orphans-of-rio.pdf)

4. Minter, D. W. (2013b). Fungal Conservation and Sustainability in Europe. In M. Letizia Gargano, G. I. Zervakis, & G. Venturella (Eds.), *Pleurotus nebrodensis: A Very Special Mushroom* (pp. 3–30). BENTHAM SCIENCE PUBLISHERS. [https://doi.org/10.2174/9781608058006113010004](https://doi.org/10.2174/9781608058006113010004)

5. Minter, D. W. (2014). Fungal conservation and the CBD: focus on Belgium. A Micheli Guide Review. *Fungal Conservation*, (4). Available at: [https://www.academia.edu/download/68114039/Fungi_and_the_Action_Plan_for_the_Conser20210715-11887-1x5p8ga.pdf#page=59](https://www.academia.edu/download/68114039/Fungi_and_the_Action_Plan_for_the_Conser20210715-11887-1x5p8ga.pdf#page=59)

---
