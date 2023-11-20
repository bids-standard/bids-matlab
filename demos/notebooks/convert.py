"""Convert Octave notebooks to scripts."""

import json
from pathlib import Path

from rich import print

this_dir = Path(__file__).parent

notebooks = this_dir.glob("*.ipynb")

for ntbk in notebooks:

    with open(ntbk) as f:
        nb = json.load(f)

    filename = ntbk.stem.replace("-", "_")

    output_file = ntbk.with_stem(filename).with_suffix(".m")

    with open(output_file, "w") as f:

        for cell in nb["cells"]:

            if cell["cell_type"] == "markdown":
                for line in cell["source"]:
                    print(f"% {line}", file=f, end="")
                print(
                    "\n",
                    file=f,
                )

            if cell["cell_type"] == "code":
                print(
                    "%%\n",
                    file=f,
                )
                for line in cell["source"]:
                    if line.startswith("https://"):
                        print(f"% {line}", file=f, end="")
                    else:
                        print(f"{line}", file=f, end="")
                print(
                    "\n",
                    file=f,
                )
