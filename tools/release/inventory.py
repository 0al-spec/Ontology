"""Read executable products from SwiftPM's evaluated package manifest."""
import json
import sys


def executable_inventory(package):
    names = [product["name"] for product in package["products"]
             if "executable" in product["type"]]
    if sorted(names) not in (["ontologyc"], ["ontologyc", "ontologyviz"]):
        raise ValueError("missing, ambiguous or unsupported executable products")
    return ",".join(sorted(names))


if __name__ == "__main__":
    print(executable_inventory(json.load(sys.stdin)))
