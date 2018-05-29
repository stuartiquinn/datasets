# FHA Origination Data

Data sourced from Housing & Urban Development (HUD) - Federal Housing Administration (FHA): [HERE][1] <br>
The Full Data Dictionary Can be Found: [HERE][2]

Certain fields have been modified for usability: 
* Originating Mortgagee = orig_mtg_spons_orig
* Mortgage Amount = orig_mtg_amount
* Loan Purpose = loan_purpose
* Property Type = prop_type
* Endorsement Year = endorsement_yr: The year in which the loan was endorsed with FHA Insurance
* Endorsement = endoresement: The Month in which the loan was endorsed with FHA Insurance

> FHA operates on Fiscal Years, therefore the month numeric corresponds to the month of Fiscal Year (e.g. a loan endoresed in October 1, 2016, will have the corresponding endorsement_yr = 2017 and endorsement (month) = 1)
Data will be updated on a regular basis


[1]: https://www.hud.gov/program_offices/housing/rmra/oe/rpts/sfsnap/sfsnap
[2]: https://www.hud.gov/sites/documents/DOC_16618.PDF
