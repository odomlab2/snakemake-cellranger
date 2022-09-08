#!/usr/env python

import os
import molgenis.client


molgenis_password = os.getenv("MOLGENIS_PASSWORD")


def init_session(host, user, password) -> molgenis.client.Session:
    session = molgenis.client.Session(host + "/api")
    session.login(user, password)
    return session


def get_table_name(table_name: str) -> str:
    _project = molgenis_config["project"]
    return f"{_project}_{table_name}"


def get_table_data(session, table_name: str, **kwargs) -> dict:
    if isinstance(session, molgenis.client.Session):
        resp = session.get(table_name, **kwargs)
    else:
        raise molgenis.client.MolgenisRequestError
    return resp


if __name__ == "__main__":
    molgenis_config = config["molgenis"]
    session = init_session(molgenis_config["host"],
                           molgenis_config["user"],
                           molgenis_password)

    libraries = get_table_data("library")
    readfileset = get_table_data("readfileset")
    readsfile = get_table_data("readsfile")
    file = get_table_data("file")









