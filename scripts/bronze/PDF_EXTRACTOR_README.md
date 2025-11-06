# PDF Data Extractor - README

## Overview
This Python script (`pdf_extractor.py`) extracts data breach information from ITRC (Identity Theft Resource Center) annual report PDF files and converts them to CSV format.

## Purpose
Automates the extraction of structured data from PDF reports, specifically designed to parse data breach records including:
- Breached entity names
- Location (US state)
- Publication dates
- Breach types (Paper Data / Electronic)
- Breach categories
- Number of records exposed
- Source information
- Reference URLs

## Installation

### Prerequisites
- Python 3.7 or higher

### Dependencies
Install required packages:
```bash
pip install -r requirements.txt
```

This will install:
- `pdfplumber` - For reading and extracting text from PDF files
- `pandas` - For data manipulation and CSV export

## Usage

### Basic Usage
```bash
python pdf_extractor.py
```

### Input Files
Place the following PDF files in the `script/` directory (relative to the script location):
- `ITRCAnnualReportPdf2019.pdf`
- `ITRCAnnualReportPdf2018.pdf`

You can modify the `file_list()` function to add more files.

### Output
The script generates CSV files with the same name as the input PDFs:
- `script/ITRCAnnualReportPdf2019.csv`
- `script/ITRCAnnualReportPdf2018.csv`

CSV format uses `;` as separator with the following columns:
- BreachedEntity
- State
- PublishedDate
- BreachType
- BreachCategory
- RecorsReported
- Source
- URL

## How It Works

1. **Text Extraction**: Uses `pdfplumber` to extract raw text from each page
2. **Data Grouping**: Identifies and groups related data lines using keyword markers
3. **Field Extraction**: Uses regular expressions to extract specific fields (dates, states, etc.)
4. **Data Compilation**: Aggregates extracted data into a Pandas DataFrame
5. **CSV Export**: Saves the structured data to CSV files

## Key Functions

- `check_unwanted_keywords_in_the_line()` - Identifies separator keywords
- `get_data_lines_from_text()` - Groups lines into data blocks
- `extract_data()` - Coordinates extraction of all fields
- `get_state()`, `get_date()`, `get_type()`, etc. - Extract specific fields using regex
- `check_data()` - Decorator for error handling (returns '-' on failure)

## Error Handling
All extraction functions are protected by the `@check_data` decorator, which:
- Catches exceptions during extraction
- Returns '-' for missing or malformed data
- Allows the script to continue processing even with incomplete data

## Documentation
For detailed French documentation explaining the code structure and logic, see:
- [PDF_EXTRACTOR_EXPLANATION_FR.md](PDF_EXTRACTOR_EXPLANATION_FR.md)

## Known Limitations
1. Designed for specific ITRC report format - may not work with other PDF structures
2. Contains a typo in column name: "RecorsReported" instead of "RecordsReported"
3. Uses deprecated `df.append()` method (works but will show warnings in newer Pandas versions)

## Potential Improvements
- Replace `df.append()` with `pd.concat()` for better performance
- Add configuration file for input/output paths
- Implement proper logging instead of print statements
- Add unit tests for extraction functions
- Add data validation and quality checks

## License
This script is part of the DataWarehouseProject repository. See repository LICENSE for details.

## Author
Kaouter RHAZLANI - Data Engineer

## Related Documentation
- Main project README: [../../README.md](../../README.md)
- French code explanation: [PDF_EXTRACTOR_EXPLANATION_FR.md](PDF_EXTRACTOR_EXPLANATION_FR.md)
