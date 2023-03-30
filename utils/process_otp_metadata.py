import pandas as pd


def rename_date_of_birth(row: pd.Series):
    """Unify the 'BIRTH' and 'DATE_OF_BIRTH' columns into
    a single 'DATE_OF_BIRTH' column.
    """
    values = [row["BIRTH"], row["DATE_OF_BIRTH"]]
    dates = [val for val in values if not pd.isna(val)]
    if len(dates) == 1:
        return dates[0]
    elif len(dates) != 1:
        return pd.NA
