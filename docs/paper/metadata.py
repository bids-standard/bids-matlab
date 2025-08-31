# yml front matter for paper from citaton.cff file

import ruamel.yaml
from pathlib import Path
from rich import print

from datetime import datetime

yaml = ruamel.yaml.YAML()
yaml.indent(mapping=2, sequence=4, offset=2)

CITATION_CFF = Path(__file__).parent.parent.parent.joinpath("CITATION.cff")

first_author = "Gau"
sort_authors_alphabetically = True


def return_author_order(author_list, first_author):
    """Return the order of authors in the paper."""
    author_order = [x["family-names"].strip() for x in author_list]
    if sort_authors_alphabetically:
        author_order = sorted(author_order)
    author_order.pop(author_order.index(first_author))
    author_order.insert(0, first_author)
    print(author_order)
    return author_order


def main():
    with open(CITATION_CFF, encoding="utf8") as f:
        citation = yaml.load(f)

    author_order = return_author_order(citation["authors"], first_author)
    author_names = [x["family-names"].strip() for x in citation["authors"]]

    author_list = []
    affiliation_list = []

    for this_author_name in author_order:

        author = citation["authors"][author_names.index(this_author_name)]

        this_author = {
            "name": f"{author['given-names']} {author.get('family-names', '')}".strip()
        }

        if author.get("orcid", None) is not None:
            this_author["orcid"] = author.get("orcid").replace("https://orcid.org/", "")

        if author.get("affiliation") is not None:

            this_affiliation = author.get("affiliation")
            affiliation_list_names = [x["name"] for x in affiliation_list]

            if this_affiliation not in affiliation_list_names:
                affiliation_list.append(
                    {"name": this_affiliation, "index": len(affiliation_list) + 1}
                )

            affiliation_list_names = [x["name"] for x in affiliation_list]
            this_author["affiliation"] = (
                affiliation_list_names.index(this_affiliation) + 1
            )

        author_list.append(this_author)

    content = {
        "title": "",
        "tags": citation["keywords"],
        "authors": author_list,
        "affiliations": affiliation_list,
        "date": datetime.now().strftime("%Y-%m-%d"),
        "bibliography": "paper.bib",
    }

    with open("metadata.yml", "w", encoding="utf8") as output_file:
        return yaml.dump(content, output_file)


if __name__ == "__main__":
    main()
